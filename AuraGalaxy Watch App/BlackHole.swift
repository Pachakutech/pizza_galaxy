//
//  BlackHole.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25
//

import SpriteKit

@MainActor
class BlackHole: CelestialObject {
    private var jetAngle: CGFloat

    init() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
        let texture = SKTexture(imageNamed: "blackhole_placeholder")
        super.init(texture: texture, size: CGSize(width: 20, height: 20))
        setupJetEffects()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupJetEffects() {
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

    func updateJetAngle() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
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
