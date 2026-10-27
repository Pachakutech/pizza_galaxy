//
//  TractorBeamAnimator.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 11/7/25.
//

import SpriteKit

@MainActor
class TractorBeamAnimator {
    private weak var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func startDragWithBeam(on body: CelestialBody, from ship: Spaceship) {
        guard let scene = scene else { return }
        body.bodyState.isBeingTractored = true
        let beam = SKSpriteNode(color: .cyan, size: CGSize(width: 1, height: 2))
        beam.anchorPoint = CGPoint(x: 0, y: 0.5) // pivot at the ship end
        beam.zPosition = 5
        beam.alpha = 0.8
        scene.addChild(beam)
        let start = body.position // captured ONCE
        let dur: TimeInterval = 2.0
        let drag = SKAction.customAction(withDuration: dur) {
            node, elapsed in let t = CGFloat(elapsed / dur)
            let e = t * t
            let p = CGPoint(x: start.x + (ship.position.x - start.x) * e, y: start.y + (ship.position.y - start.y) * e)
            node.position = p // body moves ship-ward (live ship pos)
            let dx = p.x - ship.position.x, dy = p.y - ship.position.y
            beam.position = ship.position
            beam.zRotation = atan2(dy, dx)
            beam.xScale = hypot(dx, dy) // 1pt wide sprite -> length
        }
        body.run(.sequence([drag, .run {
            beam.removeFromParent()
        }, _getPostAnimation(in: scene, on: body, from: ship)]))
    }
    
    func startPostAnimation(on body: ZDepthBody, from spaceship: Spaceship) {
        guard let scene = scene else { return }
        body.run(_getPostAnimation(in: scene, on: body, from: spaceship))
    }
    
    func _getPostAnimation(in scene: GameScene, on body: ZDepthBody, from ship: Spaceship) -> SKAction {
        let dur: TimeInterval = 0.9
        let begin = SKAction.run {
            body.bodyState.isBeingTractored = true // update loop must not touch it
            scene.awardTopping(body) // no-op if already awarded
        } // Curved flight: quadratic Bezier ship -> scoreboard, bulging up then right.
        let fly = SKAction.customAction(withDuration: dur) {
            node, elapsed in let t = CGFloat(elapsed / dur)
            let e = t * t * (3 - 2 * t) // smoothstep
            let p0 = ship.position
            let p2 = scene.scoreboardTarget // live: survives layout changes
            let p1 = CGPoint(x: p0.x, y: p2.y) // control point
            let u = 1 - e
            node.position = CGPoint( x: u*u*p0.x + 2*u*e*p1.x + e*e*p2.x, y: u*u*p0.y + 2*u*e*p1.y + e*e*p2.y)
        }
        let shrink = SKAction.scale(to: 0.25, duration: dur) // shrinks into the icon
        shrink.timingMode = .easeIn
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: dur)
        let fadeTail = SKAction.sequence([.wait(forDuration: dur * 0.8), .fadeOut(withDuration: dur * 0.2)])
        let arrive = SKAction.run {
            scene.pulseScoreboard()
            scene.activeStars.removeAll { $0 === body }
            scene.activeBlackHoles.removeAll { $0 === body }
            body.zRotation = 0
            scene.inactiveZBodies.append(body)
            body.isHidden = true
            body.bodyState.isBeingTractored = false // safe now: hidden and recycled
        }
        return .sequence([begin, .group([fly, shrink, spin, fadeTail]), arrive])
    }
   }
