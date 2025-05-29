//
//  Spaceship.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class Spaceship: SKSpriteNode {
    private var sailAngle: CGFloat = 0.0
    
    init() {
        let texture = SKTexture(imageNamed: "spaceship_placeholder")
        if texture.size() != .zero {
            print("Spaceship texture loaded: \(texture.description)")
        } else {
            print("Error: Spaceship texture is nil")
        }
        super.init(texture: texture, color: .clear, size: CGSize(width: 30, height: 30))
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.mass = 1.0
        physicsBody?.friction = 0.0
        physicsBody?.linearDamping = 0.1
        physicsBody?.categoryBitMask = 1
        physicsBody?.collisionBitMask = 2
        physicsBody?.contactTestBitMask = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustSailRudder(touchLocation: CGPoint, sceneSize: CGSize) {
        sailAngle = touchLocation.y / sceneSize.height
        // Horizontal movement via tap
        let targetX = touchLocation.x
        let deltaX = (targetX - position.x) * 0.1
        physicsBody?.applyImpulse(CGVector(dx: deltaX, dy: 0))
    }
    
    func adjustVerticalPosition(delta: Double, sceneSize: CGSize) {
        print("Crown delta: \(delta)")
        let newY = position.y + CGFloat(delta) * 50 // Sensitivity
        position.y = min(max(newY, sceneSize.height * 0.1), sceneSize.height * 0.5) // Bounds
    }
    
    func applyJetForce(from blackHole: BlackHole, direction: CGVector) {
        let distance = position.distance(to: blackHole.position)
        if distance < blackHole.jetRange * blackHole.xScale {
            let forceMagnitude = blackHole.jetStrength / max(distance, 1.0) * sailAngle
            let force = CGVector(dx: direction.dx * forceMagnitude,
                                 dy: direction.dy * forceMagnitude)
            physicsBody?.applyForce(force)
            print("Applied jet force: \(force) from black hole at: \(blackHole.position)")
        }
    }
}
