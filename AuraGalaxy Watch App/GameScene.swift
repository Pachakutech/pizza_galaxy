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
    private var blackHoles: [BlackHole] = []
    private var galaxyBackground: SKSpriteNode!
    
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
        physicsWorld.contactDelegate = self
        galaxyBackground = SKSpriteNode(imageNamed: "galaxy_background")
        print("Galaxy background texture: \(galaxyBackground.texture?.description ?? "nil")")
        galaxyBackground.size = size
        galaxyBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        galaxyBackground.zPosition = -1
        addChild(galaxyBackground)
        let borderBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: size.height * 0.1, width: size.width, height: size.height * 0.8))
        borderBody.friction = 0.0
        borderBody.restitution = 0.5
        let borderNode = SKNode()
        borderNode.physicsBody = borderBody
        addChild(borderNode)
        spaceship = Spaceship()
        spaceship.position = CGPoint(x: size.width / 2, y: size.height * 0.1) // Use SKSpriteNode.position
        addChild(spaceship)
        spawnBlackHoles()
    }
    
    private func spawnBlackHoles() {
        for _ in 0..<3 {
            let blackHole = BlackHole()
            blackHole.position = CGPoint(x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                                        y: CGFloat.random(in: size.height * 0.2...size.height * 0.8))
            blackHoles.append(blackHole)
            addChild(blackHole)
        }
    }
    
    func handleTap(at location: CGPoint) {
        spaceship.adjustSail(touchLocation: location, sceneSize: size)
    }
    
    override func update(_ currentTime: TimeInterval) {
        for blackHole in blackHoles {
            blackHole.applyJetForce(to: spaceship)
        }
        // Update spaceshipPosition for SwiftUI observation
        spaceshipPosition = spaceship.position
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Handle collisions
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(self.x - point.x, self.y - point.y)
    }
}
