//
//  Star.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/9/25.
//

import SpriteKit

@MainActor
class Star: CelestialBody {
    init() {
        super.init(textureName: "frowny_face", size: CGSize(width: 30, height: 30), mass: 0.05)
        // Temporary debug border
        color = .red
        colorBlendFactor = 0.1 // Remove after testing
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reset(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat, zNewSpeed: CGFloat) {
        super.reset(spaceshipX: spaceshipY, spaceshipY: spaceshipY, verticalOffset: verticalOffset, zNewSpeed: zNewSpeed)
        changeFace(to: "frowny_face")
        // Reapply debug border
        color = .red
        colorBlendFactor = 0.1 // Remove after testing
    }
}
