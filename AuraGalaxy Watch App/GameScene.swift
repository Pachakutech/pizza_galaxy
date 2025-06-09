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
    private var crownDelta: Double = 0.0
    private var lastCrownInputTime: TimeInterval = 0.0
    
    override init(size: CGSize) {
        super.init(size: size)
        setupScene()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupScene()
    }
    
    private func setupScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self as SKPhysicsContactDelegate
        
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        camera = cameraNode
        addChild(cameraNode)
        
        starfieldEmitter = SKEmitterNode()
        starfieldEmitter.particleTexture = SKTexture(imageNamed: "star")
        if starfieldEmitter.particleTexture == nil {
            print("Error: Starfield spark texture is nil")
        }
        starfieldEmitter.particleBirthRate = 20
        starfieldEmitter.particleLifetime = 5
        starfieldEmitter.particleSpeed = 100
        starfieldEmitter.particleScale = 0.05
        starfieldEmitter.emissionAngle = 0
        starfieldEmitter.emissionAngleRange = 2 * .pi
        starfieldEmitter.particlePositionRange = CGVector(dx: 0, dy: 0)
        starfieldEmitter.position = CGPoint(x: 0, y: 0)
        starfieldEmitter.zPosition = -2
        cameraNode.addChild(starfieldEmitter)
        
        spaceship = Spaceship()
        spaceship.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        spaceshipPosition = spaceship.position
        spaceship.zPosition = 10
        addChild(spaceship)
        
        spawnBlackHoles()
    }
    
    private func spawnBlackHoles() {
        blackHoles.removeAll()
        for _ in 0..<2 {
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
        }
    }
    
    func handleTap(at location: CGPoint) {
        spaceship.adjustSailRudder(touchLocation: location, sceneSize: size)
    }
    
    func updateCrownDelta(_ delta: Double) {
        crownDelta += delta
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let camera = camera {
            camera.position = CGPoint(x: spaceship.position.x, y: spaceship.position.y + size.height * 0.3)
        }
        
        if crownDelta != 0 {
            lastCrownInputTime = currentTime
            spaceship.applyThrust(crownDelta: crownDelta)
            
            let maxStarfieldOffset: CGFloat = 3.0
            let rawStarfieldOffset = -CGFloat(crownDelta) * 3
            let starfieldOffset = min(max(rawStarfieldOffset, -maxStarfieldOffset), maxStarfieldOffset)
            let newStarfieldY = starfieldEmitter.position.y + starfieldOffset
            if newStarfieldY >= -50 && newStarfieldY <= 50 {
                starfieldEmitter.position.y = newStarfieldY
            } else {
                starfieldEmitter.position.y = min(max(newStarfieldY, -50), 50)
            }
            
            crownDelta = 0
        } else if currentTime - lastCrownInputTime > 0.25 {
            spaceship.hideThrusters()
        }
        
        for blackHole in blackHoles {
            blackHole.zDepth -= blackHole.zSpeed
            if blackHole.zDepth <= 0 {
                blackHole.zDepth = 100
                blackHole.position = CGPoint(x: blackHole.initialX, y: spaceship.position.y + size.height * 0.3)
                blackHole.setScale(0.05)
                blackHole.direction = Bool.random() ? 1 : -1
                blackHole.zSpeed = 100.0 / 180.0
                blackHole.updateJetAngle() // Update jet angle during recycling
            } else {
                let scale = 0.05 + (1 - blackHole.zDepth / 100) * 0.95
                blackHole.setScale(scale)
                let targetY = blackHole.direction == 1 ? size.height : 0
                blackHole.position = CGPoint(x: blackHole.initialX, y: (spaceship.position.y + size.height * 0.3) + (targetY - size.height / 2) * (1 - blackHole.zDepth / 100))
            }
            blackHole.applyGravitationalForce(to: spaceship)
        }
        
        if let physicsBody = spaceship.physicsBody {
            let minY = size.height * 0.1
            let maxY = size.height * 0.5
            if spaceship.position.y < minY {
                physicsBody.velocity.dy = max(physicsBody.velocity.dy, 0)
                physicsBody.applyForce(CGVector(dx: 0, dy: 50.0))
            } else if spaceship.position.y > maxY {
                physicsBody.velocity.dy = min(physicsBody.velocity.dy, 0)
                physicsBody.applyForce(CGVector(dx: 0, dy: -50.0))
            }
        }
        
        spaceshipPosition = spaceship.position
        
        let headingAdjustment = spaceship.zRotation - .pi / 2
        starfieldEmitter.zRotation = headingAdjustment
    }
}

extension GameScene: SKPhysicsContactDelegate {
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        Task { @MainActor in
            guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }
            if (nodeA is Spaceship && nodeB is BlackHole) || (nodeA is BlackHole && nodeB is Spaceship) {
                NotificationCenter.default.post(name: NSNotification.Name("GameOver"), object: nil)
            }
        }
    }
}
