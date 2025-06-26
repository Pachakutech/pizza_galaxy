//
//  Spaceship.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25
//

import SpriteKit

@MainActor
class Spaceship: SKSpriteNode {
    private var topThruster: SKEmitterNode?
    private var bottomThruster: SKEmitterNode?
    private let thrustStrength: CGFloat = 150.0

    init() {
        let texture = SKTexture(imageNamed: "spaceship_placeholder")
        guard texture.size() != .zero else {
            fatalError("Error: Spaceship texture 'spaceship_placeholder' is missing or invalid")
        }
        super.init(texture: texture, color: .clear, size: CGSize(width: 30, height: 30))
        
        zRotation = 0

        if let topEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            topEmitter.particleBirthRate = 10
            topEmitter.position = CGPoint(x: 0, y: size.height / 2)
            topEmitter.zRotation = 3 * .pi / 2 // Inverted, was .pi / 2 (fires downward)
            topEmitter.zPosition = 1
            topEmitter.isHidden = true
            addChild(topEmitter)
            topThruster = topEmitter
        } else {
            print("Error: Failed to load top thruster JetEffect.sks")
        }

        if let bottomEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            bottomEmitter.particleBirthRate = 10
            bottomEmitter.position = CGPoint(x: 0, y: -size.height / 2)
            bottomEmitter.zRotation = .pi / 2 // Inverted, was 3 * .pi / 2 (fires upward)
            bottomEmitter.zPosition = 1
            bottomEmitter.isHidden = true
            addChild(bottomEmitter)
            bottomThruster = bottomEmitter
        } else {
            print("Error: Failed to load bottom thruster JetEffect.sks")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyThrust(crownDelta: Double) {
        let maxForcePerFrame: CGFloat = 50.0
        let rawForce = CGFloat(crownDelta) * thrustStrength
        let thrustForce = min(max(rawForce, -maxForcePerFrame), maxForcePerFrame)
//        topThruster?.isHidden = thrustForce <= 0
//        bottomThruster?.isHidden = thrustForce >= 0
    }

    func hideThrusters() {
        topThruster?.isHidden = true
        bottomThruster?.isHidden = true
    }
}
