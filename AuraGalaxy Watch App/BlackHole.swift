//
//  BlackHole.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class BlackHole: SKSpriteNode {
    let jetStrength: CGFloat = 500.0 // Increased for stronger push
    let jetRange: CGFloat = 100.0
    var zDepth: CGFloat = 100.0
    var direction: CGFloat = 0 // 1 = top, -1 = bottom
    var initialX: CGFloat = 0
    
    init() {
        let texture = SKTexture(imageNamed: "blackhole_placeholder")
        if texture.size() != .zero {
            print("BlackHole texture loaded: \(texture.description)")
        } else {
            print("Error: BlackHole texture is nil")
        }
        super.init(texture: texture, color: .clear, size: CGSize(width: 20, height: 20))
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 2
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1
        
        if let topEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            print("Top JetEffect loaded")
            topEmitter.position = CGPoint(x: 0, y: size.height / 2)
            topEmitter.zRotation = 0
            topEmitter.zPosition = 1
            addChild(topEmitter)
        } else {
            print("Error: Failed to load top JetEffect.sks")
        }
        
        if let bottomEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            print("Bottom JetEffect loaded")
            bottomEmitter.position = CGPoint(x: 0, y: -size.height / 2)
            bottomEmitter.zRotation = .pi
            bottomEmitter.zPosition = 1
            addChild(bottomEmitter)
        } else {
            print("Error: Failed to load bottom JetEffect.sks")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyGravitationalForce(to spaceship: Spaceship) {
        let direction = CGVector(dx: position.x - spaceship.position.x, dy: position.y - spaceship.position.y)
        spaceship.applyGravitationalForce(from: self, direction: direction)
    }
}
