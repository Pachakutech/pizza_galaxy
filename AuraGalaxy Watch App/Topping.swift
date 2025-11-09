//
//  Topping.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 11/7/25.
//

import SpriteKit

@MainActor
class Topping: CelestialBody {
    init() {
        super.init(textureName: "frowny_face", size: CGSize(width: 30, height: 30), mass: 0.001)
        // Temporary debug border
        color = .red
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reset(xOffset: CGFloat, yOffset: CGFloat, zNewSpeed: CGFloat) {
        super.reset(xOffset: xOffset, yOffset: yOffset, zNewSpeed: zNewSpeed)
        // TODO: run probability that determines which of an enum of toppings this should be
        changeFace(to: "frowny_face")
        // Reapply debug border
        color = .red
    }
}
