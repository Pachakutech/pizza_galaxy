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
        print("Spaceship texture: \(texture.description)")
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
    
    func adjustSail(touchLocation: CGPoint, sceneSize: CGSize) {
        sailAngle = touchLocation.y / sceneSize.height
        rudderAngle = (touchLocation.x / sceneSize.width) * 2 - 1
    }
    
    func adjustRudder(delta: Double) {
        rudderAngle = min(max(rudderAngle + CGFloat(delta), -1.0), 1.0)
    }
    
    func applyJetForce(from blackHole: BlackHole) {
        let distance = position.distance(to: blackHole.position)
        if distance < blackHole.jetRange {
            let direction = CGVector(dx: position.x - blackHole.position.x, dy: position.y - blackHole.position.y)
            let forceMagnitude = blackHole.jetStrength / max(distance, 1.0) * sailAngle
            let force = CGVector(dx: direction.dx * forceMagnitude * (1 - abs(rudderAngle)),
                                dy: direction.dy * forceMagnitude * (1 - abs(rudderAngle)))
            physicsBody?.applyForce(force)
        }
    }
}
