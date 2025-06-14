//
//  BlackHole.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class BlackHole: CelestialBody {
    private var jetAngle: CGFloat = 0
    private var jetEmitters: [SKEmitterNode] = []

    init() {
        super.init(textureName: "blackhole_placeholder", size: CGSize(width: 20, height: 20))
        setupJetEffects()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupJetEffects() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
        if let topEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            topEmitter.particleBirthRate = 10
            topEmitter.position = CGPoint(x: 0, y: size.height / 2)
            topEmitter.zRotation = jetAngle
            topEmitter.zPosition = 1
            addChild(topEmitter)
            jetEmitters.append(topEmitter)
        } else {
            print("Error: Failed to load top JetEffect.sks")
        }

        if let bottomEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            bottomEmitter.particleBirthRate = 10
            bottomEmitter.position = CGPoint(x: 0, y: -size.height / 2)
            bottomEmitter.zRotation = jetAngle + .pi
            bottomEmitter.zPosition = 1
            addChild(bottomEmitter)
            jetEmitters.append(bottomEmitter)
        } else {
            print("Error: Failed to load bottom JetEffect.sks")
        }
    }

    func updateJetAngle() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
        if let topEmitter = jetEmitters.first(where: { $0.position.y > 0 }) {
            topEmitter.zRotation = jetAngle
        }
        if let bottomEmitter = jetEmitters.first(where: { $0.position.y < 0 }) {
            bottomEmitter.zRotation = jetAngle + .pi
        }
    }

    override func reset(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat) {
        jetEmitters.forEach { $0.removeFromParent() }
        jetEmitters.removeAll()
        super.reset(spaceshipX: spaceshipX, spaceshipY: spaceshipY, verticalOffset: verticalOffset)
        setupJetEffects()
    }
}
