//
//  CelestialObject.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/14/25.
//

import SpriteKit

class CelestialObject: SKSpriteNode, ZDepthObject {
    var zDepth: CGFloat = 100.0
    var zSpeed: CGFloat = 100.0 / 360.0 // ~6 seconds to reach zDepth = 0
    var direction: CGFloat = 0
    var initialX: CGFloat = 0

    init(texture: SKTexture, size: CGSize) {
        guard texture.size() != .zero else {
            fatalError("Error: Texture for CelestialObject is missing or invalid")
        }
        super.init(texture: texture, color: .clear, size: size)
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

    // Update position and scale based on zDepth
    func updatePositionAndScale(spaceshipY: CGFloat, verticalOffset: CGFloat) {
        let scale = 0.1 + (1 - zDepth / 100) * 0.9 // Changed from 0.05 + ... * 0.95 to 0.1 + ... * 0.9
        setScale(scale)
        position = CGPoint(x: initialX, y: spaceshipY + verticalOffset)
    }

    // Reset for reuse when zDepth reaches 0
    func reset(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat, minSeparation: CGFloat, otherObjects: [CelestialObject]) {
        var newPosition: CGPoint
        var attempts = 0
        repeat {
            let initialX = spaceshipX + CGFloat.random(in: -12.0...12.0)
            newPosition = CGPoint(x: initialX, y: spaceshipY + verticalOffset)
            self.initialX = initialX
            attempts += 1
        } while otherObjects.contains(where: { other in
            other !== self && other.position.distance(to: newPosition) < minSeparation
        }) && attempts < 100

        zDepth = 100
        position = newPosition
        setScale(0.05)
        direction = 0
        print("Reset celestial object (\(type(of: self))) to x: \(newPosition.x), y: \(newPosition.y)")
    }
}
