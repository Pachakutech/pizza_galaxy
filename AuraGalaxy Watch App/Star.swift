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
        super.init(textureName: "star", size: CGSize(width: 15, height: 15))
        // Temporary debug border
        color = .red
        colorBlendFactor = 0.1 // Remove after testing
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reset(spaceshipX: CGFloat, spaceshipY: CGFloat, verticalOffset: CGFloat) {
        super.reset(spaceshipX: spaceshipX, spaceshipY: spaceshipY, verticalOffset: verticalOffset)
        // Reapply debug border
        color = .red
        colorBlendFactor = 0.1 // Remove after testing
    }
}
