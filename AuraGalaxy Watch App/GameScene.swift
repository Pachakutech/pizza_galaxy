//
//  GameScene.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit
import Combine

@MainActor
class GameScene: SKScene, ObservableObject {
    @Published var spaceship: Spaceship!
    @Published var spaceshipPosition: CGPoint = .zero
    private(set) var blackHoles: [BlackHole] = []
    private var starfieldEmitter: SKEmitterNode!
    private var crownDelta: Double = 0.0 // Track crown delta for starfield and spaceship
    
    override init(size: CGSize) {
        super.init(size: size)
        print("GameScene initialized with size: \(size)")
        setupScene()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("GameScene initialized from coder")
        setupScene()
    }
    
    private func setupScene() {
        print("Setting up GameScene")
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Setup camera node first to attach emitter
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height * 0.2) // Initial position
        camera = cameraNode
        addChild(cameraNode)
        print("Camera added at: \(cameraNode.position)")
        
        // Setup starfield emitter
        starfieldEmitter = SKEmitterNode()
        starfieldEmitter.particleTexture = SKTexture(imageNamed: "star")
        if starfieldEmitter.particleTexture != nil {
            print("Starfield texture loaded")
        } else {
            print("Error: Starfield spark texture is nil")
        }
        starfieldEmitter.particleBirthRate = 40 // Adjusted for 360° emission, sparser look
        starfieldEmitter.particleLifetime = 10 // For full X/Y coverage
        starfieldEmitter.particleSpeed = 150
        starfieldEmitter.particleScale = 0.05
        starfieldEmitter.emissionAngle = 0 // Center of emission range
        starfieldEmitter.emissionAngleRange = 2 * .pi // 360° radiation
        starfieldEmitter.particlePositionRange = CGVector(dx: 0, dy: 0) // Single-point origin
        starfieldEmitter.position = CGPoint(x: 0, y: 0) // Camera-space, screen center
        starfieldEmitter.zPosition = -2
        cameraNode.addChild(starfieldEmitter) // Attach to camera
        print("Starfield emitter added at camera-space position: \(starfieldEmitter.position)")
        
        spaceship = Spaceship()
        spaceship.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        spaceshipPosition = spaceship.position
        spaceship.zPosition = 10
        addChild(spaceship)
        print("Spaceship added at: \(spaceship.position)")
        
        spawnBlackHoles()
    }
    
    private func spawnBlackHoles() {
        print("Spawning black holes")
        blackHoles.removeAll()
        for _ in 0..<3 {
            let blackHole = BlackHole()
            let initialX = spaceship.position.x + CGFloat.random(in: -size.width / 2...size.width / 2)
            let initialY = spaceship.position.y + size.height * 0.3
            blackHole.position = CGPoint(x: initialX, y: initialY)
            blackHole.initialX = initialX
            blackHole.zPosition = -1
            blackHole.setScale(0.05)
            blackHole.zDepth = 100
            blackHole.direction = Bool.random() ? 1 : -1
            blackHoles.append(blackHole)
            addChild(blackHole)
            print("Black hole added at: \(blackHole.position), zDepth: \(blackHole.zDepth), scale: \(blackHole.xScale), direction: \(blackHole.direction)")
        }
    }
    
    func handleTap(at location: CGPoint) {
        print("Handling tap at: \(location)")
        spaceship.adjustSailRudder(touchLocation: location, sceneSize: size)
    }
    
    func updateCrownDelta(_ delta: Double) {
        crownDelta += delta
        print("updateCrownDelta called with delta: \(delta)")
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let camera = camera {
            camera.position = CGPoint(x: spaceship.position.x, y: spaceship.position.y + size.height * 0.3)
            print("Camera position: \(camera.position)")
        }
        
        // Handle crown delta for spaceship and starfield
        if crownDelta != 0 {
            // Adjust spaceship Y-position
            let newY = spaceship.position.y + CGFloat(crownDelta) * 50
            spaceship.position.y = min(max(newY, size.height * 0.1), size.height * 0.5)
            print("Spaceship Y-position updated to: \(spaceship.position.y)")
            
            // Adjust starfield Y-position in opposite direction
            let yOffset = -CGFloat(crownDelta) * 10 // Opposite direction, scaled for subtlety
            starfieldEmitter.position.y += yOffset
            // Constrain Y-position to keep effect subtle
            starfieldEmitter.position.y = min(max(starfieldEmitter.position.y, -50), 50)
            print("Starfield Y-position updated to: \(starfieldEmitter.position.y)")
            
            crownDelta = 0 // Reset delta
        }
        
        // Adjust starfield rotation to align with spaceship's heading
        let headingAdjustment = spaceship.zRotation - .pi / 2
        starfieldEmitter.zRotation = headingAdjustment
        print("Starfield zRotation: \(headingAdjustment * 180 / .pi)°")
        
        for blackHole in blackHoles {
            blackHole.zDepth -= 100 / 180
            if blackHole.zDepth <= 0 {
                blackHole.zDepth = 100
                blackHole.initialX = spaceship.position.x + CGFloat.random(in: -size.width / 2...size.width / 2)
                blackHole.position = CGPoint(x: blackHole.initialX, y: spaceship.position.y + size.height * 0.3)
                blackHole.setScale(0.05)
                blackHole.direction = Bool.random() ? 1 : -1
            } else {
                let scale = 0.05 + (1 - blackHole.zDepth / 100) * 0.95
                blackHole.setScale(scale)
                let targetY = blackHole.direction == 1 ? size.height : 0
                blackHole.position.y = (spaceship.position.y + size.height * 0.3) + (targetY - size.height / 2) * (1 - blackHole.zDepth / 100)
            }
            blackHole.applyGravitationalForce(to: spaceship)
        }
        spaceshipPosition = spaceship.position
    }
}

extension GameScene: SKPhysicsContactDelegate {
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        Task { @MainActor in
            print("Collision detected: \(contact.bodyA.node?.name ?? "unknown") and \(contact.bodyB.node?.name ?? "unknown")")
        }
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(self.x - point.x, self.y - point.y)
    }
}
