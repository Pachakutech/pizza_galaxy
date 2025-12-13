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
        super.init(textureName: "frowny_face", size: CGSize(width: 30, height: 30), mass: 0.001)
        // Temporary debug border
        color = .red
        colorBlendFactor = 0.1 // Remove after testing
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reset(xOffset: CGFloat, yOffset: CGFloat, zNewSpeed: CGFloat) {
        changeFace(to: "frowny_face")
        // Reapply debug border
        // In reset
        let frameDebug = SKAction.run {
            let path = CGPath(rect: self.frame, transform: nil)
            let shape = SKShapeNode(path: path)
            shape.strokeColor = .blue
            shape.lineWidth = 2 / self.xScale  // Adjust for scale
            shape.fillColor = .clear
            shape.zPosition = 1
            shape.position.x = super.currentX
            shape.position.y = super.currentY
            self.parent?.addChild(shape)
            shape.run(SKAction.sequence([SKAction.wait(forDuration: 5.0), SKAction.removeFromParent()]))
        }
        print("Star Reset at x \(currentX) y \(currentY)")
        run(frameDebug)
        color = .red
        colorBlendFactor = 0.1 // Remove after testing
        super.reset(xOffset: xOffset, yOffset: yOffset, zNewSpeed: zNewSpeed)
    }
}
