//
//  ZDepthBody.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/9/25
//

import SpriteKit

@MainActor
protocol ZDepthBody: SKNode {
    var zDepth: CGFloat { get set }
    var zSpeed: CGFloat { get set }
    var initialX: CGFloat { get set }
    var direction: CGFloat { get set }
}
