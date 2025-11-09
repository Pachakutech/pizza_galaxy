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
    
    func startDragWithBeam(on body: CelestialBody, from spaceship: Spaceship) {
        guard let scene = scene else { return }
        
        body.isBeingTractored = true
        
        // Load tractor beam emitter
        let beamEmitter = SKEmitterNode(fileNamed: "TractorBeam.sks")!
        beamEmitter.position = spaceship.position
        beamEmitter.zPosition = 5  // Above bodies, below spaceship
        // Remove targetNode if causing issues; particles will be in emitter's coord system
        // beamEmitter.targetNode = scene
        
        // Configure like jets: low birthrate, no ranges for thin line
        beamEmitter.particleBirthRate = 20  // Low like jets (10-20 for visibility without density)
        beamEmitter.emissionAngle = 10
        beamEmitter.emissionAngleRange = 0  // No spread for thin beam
        beamEmitter.particleSpeed = 300  // Higher speed for longer reach
        beamEmitter.particleSpeedRange = 0
        beamEmitter.particleScale = 0.01  // Small scale
        beamEmitter.particleScaleRange = 0
        beamEmitter.particleLifetimeRange = 0
        beamEmitter.particleAlpha = 1.0
        beamEmitter.particleAlphaRange = 0
        beamEmitter.particleAlphaSpeed = -0.3  // Gentle fade
        beamEmitter.particlePositionRange = CGVector(dx: 1, dy: 1)  // Tiny range for line thickness
        
        scene.addChild(beamEmitter)
        beamEmitter.advanceSimulationTime(1.0)  // Kickstart particles
        
        // Phase 1: Drag to spaceship (ease-in)
        let dragDuration: TimeInterval = 2.0
        let dragAction = SKAction.customAction(withDuration: dragDuration) { node, time in
            let t = CGFloat(time / dragDuration)
            let easedT = t * t  // Quadratic ease-in
            node.position = CGPoint(
                x: spaceship.position.x + (body.position.x - spaceship.position.x) * (1 - easedT),
                y: spaceship.position.y + (body.position.y - spaceship.position.y) * (1 - easedT)
            )
            // Update beam
            let dx = body.position.x - spaceship.position.x
            let dy = body.position.y - spaceship.position.y
            let dist = sqrt(dx * dx + dy * dy)
            let angleRad = atan2(dy, dx)
            beamEmitter.position = spaceship.position
            beamEmitter.zRotation = angleRad + .pi
            beamEmitter.particleLifetime = max(0.5, dist / beamEmitter.particleSpeed)  // Proportional length
            if dist < 10 {  // Stop near collision to avoid hop
                            beamEmitter.particleBirthRate = 0
                        }
        }
        
        // Stop emitting after drag
        let stopBeam = SKAction.run {
            beamEmitter.particleBirthRate = 0
        }
        
        // Cleanup
        let cleanup = SKAction.run {
            body.removeFromParent()
            body.isBeingTractored = false
            beamEmitter.removeFromParent()
            scene.activeStars.removeAll { $0 === body }
            scene.activeBlackHoles.removeAll { $0 === body }
        }
        
        body.run(SKAction.sequence([dragAction, stopBeam, cleanup]))
        
        // Optional: BlackHole special handling
        if let blackHole = body as? BlackHole {
            // blackHole.hideJets()  // Implement if needed
        }
    }
    func startPostAnimation(on body: CelestialBody, from spaceship: Spaceship) {
        guard let scene = scene else { return }
        print("Starting post anim")
        
        // Phase 2: Grow, fade, move to upper-right (ease-out) for non-blackholes
        let postDuration: TimeInterval = 3.0
        let upperRight = CGPoint(x: scene.size.width * 0.8, y: scene.size.height * 0.8)
        let grow = SKAction.scale(to: 3.0, duration: postDuration)
        let fade = SKAction.fadeOut(withDuration: postDuration)
        let move = SKAction.customAction(withDuration: postDuration) { node, time in
            let t = CGFloat(time / postDuration)
            let easedT = 1 - (1 - t) * (1 - t)  // Quadratic ease-out
            node.position = CGPoint(
                x: spaceship.position.x + (upperRight.x - spaceship.position.x) * easedT,
                y: spaceship.position.y + (upperRight.y - spaceship.position.y) * easedT
            )
        }
        let postGroup = SKAction.group([grow, fade, move])
        
        // Cleanup
        let cleanup = SKAction.run {
            body.removeFromParent()
            scene.activeStars.removeAll { $0 === body }
            scene.activeBlackHoles.removeAll { $0 === body }
            scene.inactiveCelestialBodies.append(body)  // Recycle
        }
        
        body.run(SKAction.sequence([postGroup, cleanup]))
    }
}
