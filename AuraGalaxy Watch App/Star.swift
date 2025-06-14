//
//  Star.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/14/25
//

import SpriteKit

@MainActor
class Star: CelestialObject {
    init() {
        let texture = SKTexture(imageNamed: "star")
        super.init(texture: texture, size: CGSize(width: 15, height: 15)) // Increased from 10x10 to 15x15
        zSpeed = 100.0 / 360.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
