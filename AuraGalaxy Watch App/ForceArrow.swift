//
//  ForceArrow.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 1/4/26.
//

import SpriteKit

class ForceArrow: SKShapeNode{
    func updateForceArrow(forceX: CGFloat, forceY: CGFloat) {
        let magnitude = sqrt(forceX * forceX + forceY * forceY)
        let angle = atan2(forceY, forceX)
        
        let arrowPath = CGMutablePath()
        // 1. Create or update the arrow path
    
        arrowPath.move(to: .zero)
        arrowPath.addLine(to: CGPoint(x: magnitude, y: 0)) // Length scales with magnitude
        
        // 2. Add arrowhead (simple V-shape at the end)
        arrowPath.move(to: CGPoint(x: magnitude, y: 0))
        arrowPath.addLine(to: CGPoint(x: magnitude - 10, y: 5))
        arrowPath.move(to: CGPoint(x: magnitude, y: 0))
        arrowPath.addLine(to: CGPoint(x: magnitude - 10, y: -5))
        
        // 3. Update the node properties
        self.path = arrowPath
        self.zRotation = angle
        
        // 4. Increase "fatness" based on magnitude
        self.lineWidth = max(1.0, magnitude / 50.0)
    }
}
