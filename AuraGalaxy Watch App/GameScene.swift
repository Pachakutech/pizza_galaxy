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
    
    override init(size: CGSize) {
        super.init(size: size)
        print("GameScene init with size: \(size)")
        setupScene()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("GameScene init from coder")
        setupScene()
    }
    
    private func setupScene() {
        print("Setting up GameScene")
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        starfieldEmitter = SKEmitterNode()
        starfieldEmitter.particleTexture = SKTexture(imageNamed: "spark")
        if starfieldEmitter.particleTexture != nil {
            print("Starfield texture loaded")
        } else {
            print("Error: Starfield spark texture is nil")
        }
        starfieldEmitter.particleBirthRate = 50
        starfieldEmitter.particleLifetime = 3
        starfieldEmitter.particleSpeed = 200
        starfieldEmitter.particleScale = 0.05
        starfieldEmitter.emissionAngle = .pi
        starfieldEmitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        starfieldEmitter.position = CGPoint(x: size.width / 2, y: size.height)
        starfieldEmitter.zPosition = -2
        addChild(starfieldEmitter)
        print("Starfield emitter added")
        
        spaceship = Spaceship()
        spaceship.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        spaceshipPosition = spaceship.position
        spaceship.zPosition = 10
        addChild(spaceship)
        print("Spaceship added at: \(spaceship.position)")
        
        spawnBlackHoles()
        
        let cameraNode = SKCameraNode()
        cameraNode.position = spaceship.position
        camera = cameraNode
        addChild(cameraNode)
        print("Camera added")
    }
    
    private func spawnBlackHoles() {
        print("Spawning black holes")
        blackHoles.removeAll()
        for _ in 0..<3 {
            let blackHole = BlackHole()
            let initialX = CGFloat.random(in: size.width * 0.2...size.width * 0.8) // Random x
            blackHole.position = CGPoint(x: initialX, y: size.height / 2)
            blackHole.initialX = initialX // Store initial x
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
    
    override func update(_ currentTime: TimeInterval) {
        if let camera = camera {
            camera.position = CGPoint(x: spaceship.position.x, y: spaceship.position.y + size.height * 0.3)
            print("Camera position: \(camera.position)")
        }
        
        for blackHole in blackHoles {
            blackHole.zDepth -= 100 / 180
            if blackHole.zDepth <= 0 {
                blackHole.zDepth = 100
                blackHole.position = CGPoint(x: blackHole.initialX, y: size.height / 2) // Reuse initial x
                blackHole.setScale(0.05)
                blackHole.direction = Bool.random() ? 1 : -1
            } else {
                let scale = 0.05 + (1 - blackHole.zDepth / 100) * 0.95
                blackHole.setScale(scale)
                let targetY = blackHole.direction == 1 ? size.height : 0
                blackHole.position.y = size.height / 2 + (targetY - size.height / 2) * (1 - blackHole.zDepth / 100)
            }
            blackHole.applyJetForce(to: spaceship)
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
