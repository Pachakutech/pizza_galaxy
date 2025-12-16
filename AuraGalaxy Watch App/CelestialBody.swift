//
//  CelestialBody.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class CelestialBody: SKSpriteNode, ZDepthBody {
    var hit = false
    var zSpeed: CGFloat = 0
    var zDepth: CGFloat = 100.0
    var mass: CGFloat = 1.0
    var direction: CGFloat = 0
    var radialMagnitude: CGFloat = 50  // sensitivity to changes
    var xInitialOffset: CGFloat = 0
    var yInitialOffset: CGFloat = 0
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var xCumulativeOffset: CGFloat = 0
    var yCumulativeOffset: CGFloat = 0
    var isBeingTractored: Bool = false  // Flag to prevent z-updates/recycling during animation

    init(textureName: String, size: CGSize, mass: CGFloat) {
        let texture = SKTexture(imageNamed: textureName)
        guard texture.size() != .zero else {
            fatalError(
                "Error: Texture '\(textureName)' for CelestialBody is missing or invalid"
            )
        }
        super.init(texture: texture, color: .clear, size: size)
        self.mass = mass
        isUserInteractionEnabled = true  // Enable touch interaction (though handled at scene level)
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

    func changeFace(to textureName: String) {
        texture = SKTexture(imageNamed: textureName)
    }

    func updatePositionAndScale(
        centerX: CGFloat,
        centerY: CGFloat,
        xOffset: CGFloat,
        yOffset: CGFloat
    ) {
        let firstTime = xCumulativeOffset == 0 && yCumulativeOffset == 0
        xCumulativeOffset += xOffset
        yCumulativeOffset += yOffset

        let scale = 0.1 + (1 - zDepth * zDepth / 10000) * 0.9
        setScale(scale)
        let radialFactor = (100 - zDepth) / 100 * radialMagnitude
        currentX =
            centerX - cos(direction) * radialFactor - xInitialOffset
            - xCumulativeOffset
        currentY =
            centerY - sin(direction) * radialFactor - yInitialOffset
            - yCumulativeOffset
        if firstTime {
            print("initialized star at x:\(currentX) y:\(currentY)")
        }
        position = CGPoint(x: currentX, y: currentY)
        zPosition = 20 - zDepth / 5  // zDepth 0 -> zPosition 20, zDepth 100 -> zPosition 0
        //        print("Updated \(texture?.description ?? "unknown"): zDepth=\(zDepth), zPosition=\(zPosition), radialFactor=\(radialFactor), pos=\(position), xOffset=\(xOffset), xCumulativeOffset=\(xCumulativeOffset)")
    }

    func reset(xOffset: CGFloat, yOffset: CGFloat, zNewSpeed: CGFloat) {
        let radian = generateBiasedRadian(sigma: 6)
        let radialOffset = CGFloat.random(in: 5...25)
        direction = (radian + .pi / 2) * (Bool.random() ? 1 : -1)
        xInitialOffset = cos(direction) * radialOffset + xOffset
        yInitialOffset = sin(direction) * radialOffset + yOffset
        xCumulativeOffset = 0  // Reset cumulative offset
        yCumulativeOffset = 0
        zPosition = 0  // Matches zDepth = 100
        zDepth = 100
        zSpeed = zNewSpeed
        setScale(0.1)
        hit = false
        isHidden = false
        alpha = 1.0
        isBeingTractored = false
    }

    func generateBiasedRadian(sigma: CGFloat, mean: CGFloat = 0) -> CGFloat {
        // Use a Gaussian-like distribution to bias towards π/2 (vertical), then shift to horizontal
        // Approximate Gaussian using Bell-Knop transform
        let u = CGFloat.random(in: 0...1)
        let v = CGFloat.random(in: 0...1)
        let magnifier = .pi / sigma * sqrt(-2.0 * log(u))
        let z = magnifier * cos(2.0 * .pi * v) + mean
        return z
    }
}
