//
//  CGPointExtensions.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/9/25.
//


import SpriteKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(self.x - point.x, self.y - point.y)
    }
}
