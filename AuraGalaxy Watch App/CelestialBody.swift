//
//  CelestialBody.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class CelestialBody: SKSpriteNode, @MainActor ZDepthBody {
    var bodyState = BodyState()
    
    var mass: CGFloat = 1.0

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeFace(to textureName: String) {
        texture = SKTexture(imageNamed: textureName)
    }
    func reset(xOffset: CGFloat, yOffset: CGFloat, zNewSpeed: CGFloat) {
        resetToRing(xOffset: xOffset, yOffset: yOffset, zNewSpeed: zNewSpeed)
    }
}
