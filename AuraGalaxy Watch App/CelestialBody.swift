//
//  CelestialBody.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class CelestialBody: SKSpriteNode, ZDepthBody {
    var zDepth: CGFloat = 100.0
    var zSpeed: CGFloat = 100.0 / 360.0
    var direction: CGFloat = 0
    var initialX: CGFloat = 0

    init(textureName: String, size: CGSize) {
        let texture = SKTexture(imageNamed: textureName)
        guard texture.size() != .zero else {
            fatalError("Error: Texture '\(textureName)' for CelestialBody is missing or invalid")
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

    func updatePositionAndScale(spaceshipY: CGFloat, verticalOffset: CGFloat) {
        let scale = 0.1 + (1 - zDepth / 100) * 0.9
        setScale(scale)
        position = CGPoint(x: initialX, y: spaceshipY + verticalOffset)
    }

    func reset(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat) {
        initialX = spaceshipX + CGFloat.random(in: -12.0...12.0)
        position = CGPoint(x: initialX, y: spaceshipY + verticalOffset)
        zDepth = 100
        setScale(0.1)
        direction = 0
        isHidden = false
        print("Reset CelestialBody (\(texture?.description ?? "unknown")) at x: \(initialX), y: \(position.y), scale: \(xScale)")
    }

    func applyGravitationalForce(to spaceship: Spaceship) {
        let direction = CGVector(dx: position.x - spaceship.position.x, dy: position.y - spaceship.position.y)
        let distance = position.distance(to: spaceship.position)
        let gravitationalConstant: CGFloat = 25000
        let denominator = max(distance * distance, 1.0)
        let gravForceMagnitude = gravitationalConstant / denominator
        let gravForce = CGVector(dx: direction.dx * gravForceMagnitude / distance, dy: 0)
        spaceship.physicsBody?.applyForce(gravForce)
    }
}
