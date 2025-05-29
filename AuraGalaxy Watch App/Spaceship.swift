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
    private var rudderAngle: CGFloat = 0.0
    
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
        rudderAngle = (touchLocation.x / sceneSize.width) * 2 - 1
    }
    
    func adjustRudder(delta: Double) {
        print("Crown delta: \(delta)")
        rudderAngle = min(max(rudderAngle + CGFloat(delta), -1.0), 1.0)
    }
    
    func applyJetForce(from blackHole: BlackHole, direction: CGVector) {
        let distance = position.distance(to: blackHole.position)
        if distance < blackHole.jetRange * blackHole.xScale { // Use xScale
            let forceMagnitude = blackHole.jetStrength / max(distance, 1.0) * sailAngle
            let force = CGVector(dx: direction.dx * forceMagnitude * (1 - abs(rudderAngle)),
                                 dy: direction.dy * forceMagnitude * (1 - abs(rudderAngle)))
            physicsBody?.applyForce(force)
            print("Applied jet force: \(force) from black hole at: \(blackHole.position)")
        }
    }
}
