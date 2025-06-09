//
//  BlackHole.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class BlackHole: SKSpriteNode {
    let jetStrength: CGFloat = 500.0
    let jetRange: CGFloat = 100.0
    var zDepth: CGFloat = 100.0
    var zSpeed: CGFloat = 100.0 / 180.0
    var direction: CGFloat = 0
    var initialX: CGFloat = 0
    private var jetAngle: CGFloat // Changed to var
    
    init() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
        let texture = SKTexture(imageNamed: "blackhole_placeholder")
        guard texture.size() != .zero else {
            fatalError("Error: BlackHole texture 'blackhole_placeholder' is missing or invalid")
        }
        super.init(texture: texture, color: .clear, size: CGSize(width: 20, height: 20))
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 2
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1
        
        if let topEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            topEmitter.particleBirthRate = 10
            topEmitter.position = CGPoint(x: 0, y: size.height / 2)
            topEmitter.zRotation = jetAngle
            topEmitter.zPosition = 1
            addChild(topEmitter)
        } else {
            print("Error: Failed to load top JetEffect.sks")
        }
        
        if let bottomEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            bottomEmitter.particleBirthRate = 10
            bottomEmitter.position = CGPoint(x: 0, y: -size.height / 2)
            bottomEmitter.zRotation = jetAngle + .pi
            bottomEmitter.zPosition = 1
            addChild(bottomEmitter)
        } else {
            print("Error: Failed to load bottom JetEffect.sks")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateJetAngle() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
        // Update emitter rotations
        if let topEmitter = children.first(where: { $0 is SKEmitterNode && $0.position.y > 0 }) as? SKEmitterNode {
            topEmitter.zRotation = jetAngle
        }
        if let bottomEmitter = children.first(where: { $0 is SKEmitterNode && $0.position.y < 0 }) as? SKEmitterNode {
            bottomEmitter.zRotation = jetAngle + .pi
        }
    }
    
    func applyGravitationalForce(to spaceship: Spaceship) {
        let direction = CGVector(dx: position.x - spaceship.position.x, dy: position.y - spaceship.position.y)
        spaceship.applyGravitationalForce(from: self, direction: direction, jetAngle: jetAngle)
    }
}
