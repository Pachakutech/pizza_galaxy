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
    private var jetHitBoxes: [SKSpriteNode] = []

    init() {
        super.init(textureName: "blackhole_placeholder", size: CGSize(width: 20, height: 20), mass: 1.0)
        setupJetEffects()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupJetEffects() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
        self.zRotation = jetAngle

        // Set hit box dimensions
        let hitBoxWidth: CGFloat = 20.0 // Half of previous 40.0, matches black hole width
        let hitBoxLength: CGFloat = hitBoxWidth * 5.0 // 5x width (100.0)

        // Top jet emitter and hit box
        guard let topEmitter = SKEmitterNode(fileNamed: "JetEffect") else {
            return // Skip if asset is missing, no print to reduce overhead
        }
        topEmitter.particleBirthRate = 10
        topEmitter.position = CGPoint(x: 0, y: size.height / 2)
        topEmitter.zRotation = 0 // Emits outward from north pole
        topEmitter.zPosition = 1
        addChild(topEmitter)
        jetEmitters.append(topEmitter)

        let topHitBox = SKSpriteNode(color: .clear, size: CGSize(width: hitBoxWidth, height: hitBoxLength))
        topHitBox.position = CGPoint(x: 0, y: size.height / 2 + hitBoxLength / 2) // Center extends outward
        topHitBox.zPosition = 1
        // Debug outline
        topHitBox.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.5),
            SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.5)
        ])))
        addChild(topHitBox)
        jetHitBoxes.append(topHitBox)

        // Bottom jet emitter and hit box
        guard let bottomEmitter = SKEmitterNode(fileNamed: "JetEffect") else {
            return // Skip if asset is missing, no print to reduce overhead
        }
        bottomEmitter.particleBirthRate = 10
        bottomEmitter.position = CGPoint(x: 0, y: -size.height / 2)
        bottomEmitter.zRotation = .pi // Rotate 180° to emit outward from south pole
        bottomEmitter.zPosition = 1
        addChild(bottomEmitter)
        jetEmitters.append(bottomEmitter)

        let bottomHitBox = SKSpriteNode(color: .clear, size: CGSize(width: hitBoxWidth, height: hitBoxLength))
        bottomHitBox.position = CGPoint(x: 0, y: -size.height / 2 - hitBoxLength / 2) // Center extends outward
        bottomHitBox.zPosition = 1
        // Debug outline
        bottomHitBox.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.5),
            SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.5)
        ])))
        addChild(bottomHitBox)
        jetHitBoxes.append(bottomHitBox)
    }

    func updateJetAngle() {
        jetAngle = CGFloat.random(in: -.pi / 4...(.pi / 4))
        self.zRotation = jetAngle
        print("Updated black hole rotation: jetAngle=\(jetAngle * 180 / .pi)°")
    }

    func getJetHitBoxes() -> [(SKSpriteNode, Bool)] {
        return jetHitBoxes.map { hitBox in
            let isTop = hitBox.position.y > 0
            return (hitBox, isTop)
        }
    }

    override func reset(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat) {
        jetEmitters.forEach { $0.removeFromParent() }
        jetEmitters.removeAll()
        jetHitBoxes.forEach { $0.removeFromParent() }
        jetHitBoxes.removeAll()
        super.reset(spaceshipX: spaceshipX, spaceshipY: spaceshipY, verticalOffset: verticalOffset)
        setupJetEffects()
    }
}
