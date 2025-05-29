//
//  BlackHole.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class BlackHole: SKSpriteNode {
    let jetStrength: CGFloat = 50.0
    let jetRange: CGFloat = 100.0
    var zDepth: CGFloat = 100.0
    
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
        physicsBody?.collisionBitMask = 1
        physicsBody?.contactTestBitMask = 1
        if let jetEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            print("JetEffect loaded successfully")
            jetEmitter.position = CGPoint(x: 0, y: size.height / 2)
            jetEmitter.zPosition = 1
            addChild(jetEmitter)
        } else {
            print("Error: Failed to load JetEffect.sks")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyJetForce(to spaceship: Spaceship) {
        let direction = CGVector(dx: position.x - spaceship.position.x, dy: position.y - spaceship.position.y)
        spaceship.applyJetForce(from: self, direction: direction)
    }
}
