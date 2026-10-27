//
//  ZDepthBody.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/9/25
//

import SpriteKit

import SpriteKit
import WatchKit

struct BodyState {
    var hit = false
    var zSpeed: CGFloat = 0
    var zDepth: CGFloat = 100.0
    var mass: CGFloat = 1.0
    var direction: CGFloat = 0
    var radialMagnitude: CGFloat = 120.0 // Desire to expand per Z
    var xInitialOffset: CGFloat = 0
    var yInitialOffset: CGFloat = 0
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var speedScale: CGFloat = 1
    var xCumulativeOffset: CGFloat = 0
    var yCumulativeOffset: CGFloat = 0
    var isBeingTractored: Bool = false  // Flag to prevent z-updates/recycling during animation
}

protocol ZDepthBody: SKNode {
    var bodyState: BodyState { get set }
    func reset(xOffset: CGFloat, yOffset: CGFloat, zNewSpeed: CGFloat)
    func updatePositionAndScale(
        centerX: CGFloat,
        centerY: CGFloat,
        xOffset: CGFloat,
        yOffset: CGFloat
    )
    func generateBiasedRadian(sigma: CGFloat, mean: CGFloat) -> CGFloat
}

extension ZDepthBody {
    var depthProgress: CGFloat {
        let u = bodyState.zDepth / 100
        let c: CGFloat = 0.15
        let far = 1 / (1 + c)
        let near = 1 / c
        return (1 / (u + c) - far) / (near - far)
    }

    func updatePositionAndScale(
        centerX: CGFloat,
        centerY: CGFloat,
        xOffset: CGFloat,
        yOffset: CGFloat
    ) {
        let f = depthProgress
        let firstTime =
            bodyState.xCumulativeOffset == 0 && bodyState.yCumulativeOffset == 0
        bodyState.xCumulativeOffset += xOffset
        bodyState.yCumulativeOffset += yOffset * f

        let scale = 0.1 + f * 0.9
        setScale(scale)
        let radialFactor = f * bodyState.radialMagnitude
        bodyState.currentX =
            centerX - cos(bodyState.direction) * radialFactor
            - bodyState.xInitialOffset
            - bodyState.xCumulativeOffset
        bodyState.currentY =
            centerY - sin(bodyState.direction) * radialFactor
            - bodyState.yInitialOffset
            - bodyState.yCumulativeOffset
        if firstTime {
            print(
                "initialized star at x:\(bodyState.currentX) y:\(bodyState.currentY)"
            )
        }
        position = CGPoint(x: bodyState.currentX, y: bodyState.currentY)
        //        zPosition = 20 - bodyState.zDepth / 5  // zDepth 0 -> zPosition 20, zDepth 100 -> zPosition 0
        //        print("Updated \(texture?.description ?? "unknown"): zDepth=\(zDepth), zPosition=\(zPosition), radialFactor=\(radialFactor), pos=\(position), xOffset=\(xOffset), xCumulativeOffset=\(xCumulativeOffset)")
    }

    func resetToRing(xOffset: CGFloat, yOffset: CGFloat, zNewSpeed: CGFloat) {
        let radian = generateBiasedRadian(sigma: 6)
        let radialOffset = CGFloat.random(in: 1...200)
        bodyState.direction = (radian + .pi / 2) * (Bool.random() ? 1 : -1)
        bodyState.xInitialOffset =
            cos(bodyState.direction) * radialOffset + xOffset
        bodyState.yInitialOffset =
            sin(bodyState.direction) * radialOffset + yOffset
        bodyState.xCumulativeOffset = 0  // Reset cumulative offset
        bodyState.yCumulativeOffset = 0
        zPosition = 0  // Matches zDepth = 100
        bodyState.zDepth = 100
        bodyState.zSpeed = zNewSpeed
        setScale(0.1)
        bodyState.hit = false
        isHidden = false
        alpha = 1.0
        bodyState.isBeingTractored = false
    }

    func generateBiasedRadian(sigma: CGFloat, mean: CGFloat = 0) -> CGFloat {
        // Use a Gaussian-like distribution to bias towards π/2 (vertical), then shift to horizontal
        // Approximate Gaussian using Bell-Knop transform
        let u = CGFloat.random(in: 0...1)
        let v = CGFloat.random(in: 0...1)
        let magnifier = .pi / sigma * sqrt(-2.0 * log(u))
        let z = magnifier * cos(2.0 * .pi * v) + mean
        return z
    }
}
