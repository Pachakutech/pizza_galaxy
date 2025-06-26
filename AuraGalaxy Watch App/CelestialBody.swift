//
//  CelestialBody.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class CelestialBody: SKSpriteNode, ZDepthBody {
    var zSpeed:CGFloat = 0
    var zDepth: CGFloat = 100.0
    var direction: CGFloat = 0
    var initialX: CGFloat = 0
    var mass: CGFloat = 1.0
    var initialAngle: CGFloat = 0
    var initialDistance: CGFloat = 0

    init(textureName: String, size: CGSize, mass: CGFloat) {
        let texture = SKTexture(imageNamed: textureName)
        guard texture.size() != .zero else {
            fatalError("Error: Texture '\(textureName)' for CelestialBody is missing or invalid")
        }
        super.init(texture: texture, color: .clear, size: size)
        self.mass = mass
        setupPhysicsBody()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysicsBody() {
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 2
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1
    }
    
    func updatePositionAndScale(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat, xOffset: CGFloat) {
        let scale = 0.1 + (1 - zDepth / 100) * 0.9
        setScale(scale)
        let radialFactor = (100 - zDepth) / 100
        position = CGPoint(
            x: spaceshipX + initialDistance * cos(initialAngle) * radialFactor + xOffset,
            y: spaceshipY + initialDistance * sin(initialAngle) * radialFactor + verticalOffset
        )
        zPosition = 20 - zDepth / 20 // zDepth 0 -> zPosition 20, zDepth 100 -> zPosition 0
        print("Updated \(texture?.description ?? "unknown"): zDepth=\(zDepth), zPosition=\(zPosition), radialFactor=\(radialFactor), pos=\(position), relativeXOffset=\(xOffset)")
    }
    
    func reset(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat, zNewSpeed: CGFloat) {
        initialAngle = CGFloat.random(in: 0...(2 * .pi))
        initialDistance = CGFloat.random(in: 75...150)
        let excludeRange: CGFloat = 5
        let xOffset = CGFloat.random(in: excludeRange...(12 + excludeRange)) * (Bool.random() ? 1 : -1)
        initialX = spaceshipX + xOffset
        zPosition = 0 // Matches zDepth = 100
        zDepth = 100
        zSpeed = zNewSpeed
        setScale(0.1)
        direction = 0
        isHidden = false
        print("Reset CelestialBody (\(texture?.description ?? "unknown")) at angle: \(initialAngle * 180 / .pi)°, distance: \(initialDistance), x: \(initialX)")
    }
}
