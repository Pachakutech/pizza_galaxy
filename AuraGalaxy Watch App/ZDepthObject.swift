//
//  ZDepthObject.swift
//  AuraGalaxy
//
//  Created on 6/9/25.
//

import SpriteKit

protocol ZDepthObject: SKNode {
    var zDepth: CGFloat { get set }
    var zSpeed: CGFloat { get set }
    var initialX: CGFloat { get set }
    var direction: CGFloat { get set }
}
