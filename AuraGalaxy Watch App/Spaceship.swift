//
//  Spaceship.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class Spaceship: SKSpriteNode {
    private var sailAngle: CGFloat = 0.5
    
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
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustSailRudder(touchLocation: CGPoint, sceneSize: CGSize) {
        sailAngle = touchLocation.y / sceneSize.height
        zRotation = .pi / 2 + sailAngle * .pi // 90° to 270°
        print("Set sailAngle: \(sailAngle), rotation: \(zRotation) radians (\(zRotation * 180 / .pi)°)")
    }
    
    func adjustVerticalPosition(delta: Double, sceneSize: CGSize) {
//        print("Crown delta: \(delta)")
//        let newY = position.y + CGFloat(delta) * 50
//        position.y = min(max(newY, sceneSize.height * 0.1), sceneSize.height * 0.5)
    }
    
    func applyGravitationalForce(from blackHole: BlackHole, direction: CGVector) {
        let distance = position.distance(to: blackHole.position)
        let gravitationalConstant: CGFloat = 50000 // Increased for stronger pull
        let gravForceMagnitude = gravitationalConstant / max(distance * distance, 1.0)
        let gravForce = CGVector(dx: -direction.dx * gravForceMagnitude / distance,
        dy: -direction.dy * gravForceMagnitude / distance)
              
        let forwardForceMagnitude = blackHole.jetStrength * sailAngle * blackHole.xScale // jetStrength = 200
        let forwardForce = CGVector(dx: 0, dy: forwardForceMagnitude)
              
        physicsBody?.applyForce(gravForce)
        physicsBody?.applyForce(forwardForce)
        print("Applied gravitational force: \(gravForce), forward force: \(forwardForce) from black hole at: \(blackHole.position), distance: \(distance)")
    }
}
