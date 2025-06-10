//
//  GameScene.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25
//

import SpriteKit
import Combine

@MainActor
class GameScene: SKScene, ObservableObject {
    @Published var spaceship: Spaceship!
    @Published var spaceshipPosition: CGPoint = .zero
    private(set) var blackHoles: [BlackHole] = []
    private var starfieldEmitter: SKEmitterNode!
    private var crownDelta: Double = 0.0
    private var lastCrownInputTime: TimeInterval = 0.0
    private var verticalOffset: CGFloat = 0.0
    private var isAnimatingOrbit: Bool = false
    private var animatingBlackHole: BlackHole?
    
    override init(size: CGSize) {
        super.init(size: size)
        setupScene()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupScene()
    }
    
    private func setupScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        camera = cameraNode
        addChild(cameraNode)
        
        starfieldEmitter = SKEmitterNode()
        starfieldEmitter.particleTexture = SKTexture(imageNamed: "star")
        if starfieldEmitter.particleTexture == nil {
            print("Error: Starfield spark texture is nil")
        }
        starfieldEmitter.particleBirthRate = 30 // Increased for density
        starfieldEmitter.particleLifetime = 3 // Reduced for denser clustering
        starfieldEmitter.particleSpeed = 50 // Slower for density
        starfieldEmitter.particleScale = 0.1 // Bigger stars
        starfieldEmitter.particleAlpha = 1.0 // Max brightness
        starfieldEmitter.emissionAngle = 0
        starfieldEmitter.emissionAngleRange = 2 * .pi // Radial motion
        starfieldEmitter.particlePositionRange = CGVector(dx: 0, dy: 0) // Single point origin
        starfieldEmitter.position = CGPoint(x: 0, y: 0)
        starfieldEmitter.zPosition = -2
        cameraNode.addChild(starfieldEmitter)
        
        spaceship = Spaceship()
        spaceship.position = CGPoint(x: size.width / 2, y: size.height / 2)
        spaceshipPosition = spaceship.position
        spaceship.zPosition = 10
        addChild(spaceship)
        
        spawnBlackHoles()
    }
    
    private func spawnBlackHoles() {
        blackHoles.removeAll()
        var attempts = 0
        while blackHoles.count < 2 && attempts < 100 {
            let blackHole = BlackHole()
            let initialX = spaceship.position.x + CGFloat.random(in: -12.0...12.0)
            let initialY = spaceship.position.y + verticalOffset
            blackHole.position = CGPoint(x: initialX, y: initialY)
            blackHole.initialX = initialX
            blackHole.zPosition = -1
            blackHole.setScale(0.05)
            blackHole.zDepth = 100
            blackHole.direction = 0
            
            let minSeparation: CGFloat = 10.0
            let tooClose = blackHoles.contains { other in
                other.position.distance(to: blackHole.position) < minSeparation
            }
            if !tooClose {
                blackHoles.append(blackHole)
                addChild(blackHole)
                print("Spawned black hole at x: \(initialX), y: \(initialY), spaceship.x: \(spaceship.position.x), verticalOffset: \(verticalOffset)")
            }
            attempts += 1
        }
        if blackHoles.count < 2 {
            print("Warning: Only spawned \(blackHoles.count) black holes after \(attempts) attempts")
        }
    }
    
    func handleTap(at location: CGPoint) {
        print("Tap at \(location), no zRotation change")
    }
    
    func updateCrownDelta(_ delta: Double) {
        crownDelta += delta
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let camera = camera {
            camera.position = spaceship.position
        }
        
        if crownDelta != 0 {
            lastCrownInputTime = currentTime
            spaceship.applyThrust(crownDelta: crownDelta)
            verticalOffset -= CGFloat(crownDelta) * 15.0
            verticalOffset = min(max(verticalOffset, -size.height * 0.4), size.height * 0.4)
            
            starfieldEmitter.position.y = verticalOffset // Match black hole y-range
            
            crownDelta = 0
        } else if currentTime - lastCrownInputTime > 0.25 {
            spaceship.hideThrusters()
        }
        
        if isAnimatingOrbit {
            return
        }
        
        for blackHole in blackHoles {
            blackHole.zDepth -= blackHole.zSpeed
            if blackHole.zDepth <= 0 {
                print("Black hole at zDepth <= 0, position: \(blackHole.position), spaceship: \(spaceship.position)")
                resetBlackHole(blackHole)
            } else {
                let scale = 0.05 + (1 - blackHole.zDepth / 100) * 0.95
                blackHole.setScale(scale)
                blackHole.position = CGPoint(x: blackHole.initialX, y: spaceship.position.y + verticalOffset)
            }
            blackHole.applyGravitationalForce(to: spaceship)
        }
        
        spaceshipPosition = spaceship.position
        
        let headingAdjustment = spaceship.zRotation - .pi / 2
        starfieldEmitter.zRotation = headingAdjustment
    }
    
    private func resetBlackHole(_ blackHole: BlackHole) {
        var newPosition: CGPoint
        var attempts = 0
        let minSeparation: CGFloat = 10.0
        repeat {
            let initialX = spaceship.position.x + CGFloat.random(in: -12.0...12.0)
            newPosition = CGPoint(x: initialX, y: spaceship.position.y + verticalOffset)
            blackHole.initialX = initialX
            attempts += 1
        } while blackHoles.contains(where: { other in
            other !== blackHole && other.position.distance(to: newPosition) < minSeparation
        }) && attempts < 100
        
        blackHole.zDepth = 100
        blackHole.position = newPosition
        blackHole.setScale(0.05)
        blackHole.direction = 0
        blackHole.updateJetAngle()
        print("Reset black hole to x: \(newPosition.x), y: \(newPosition.y), spaceship.x: \(spaceship.position.x), verticalOffset: \(verticalOffset)")
    }
    
    private func startOrbitAnimation(for blackHole: BlackHole) {
        isAnimatingOrbit = true
        animatingBlackHole = blackHole
        
        let radius: CGFloat = 20.0
        let orbitPath = UIBezierPath(arcCenter: spaceship.position, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let orbitAction = SKAction.follow(orbitPath.cgPath, asOffset: false, orientToPath: false, duration: 3.0)
        let repeatOrbit = SKAction.repeat(orbitAction, count: 2)
        blackHole.run(repeatOrbit)
        
        let spinAction = SKAction.rotate(byAngle: .pi * 4, duration: 3.0)
        starfieldEmitter.run(spinAction)
        
        let wait = SKAction.wait(forDuration: 3.0)
        let endAnimation = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isAnimatingOrbit = false
            self.starfieldEmitter.zRotation = self.spaceship.zRotation - .pi / 2
            self.applyEndForce(to: blackHole)
            self.resetBlackHole(blackHole)
            self.animatingBlackHole = nil
        }
        run(SKAction.sequence([wait, endAnimation]))
    }
    
    private func applyEndForce(to blackHole: BlackHole) {
        let jetAngle = blackHole.children
            .first(where: { $0 is SKEmitterNode && $0.position.y > 0 })?
            .zRotation ?? 0
        let isAbove = spaceship.position.y > blackHole.position.y
        let forceAngle = isAbove ? jetAngle + .pi : jetAngle
        let forceMagnitude: CGFloat = 2000.0
        let forceX = cos(forceAngle) * forceMagnitude
        let forceY = sin(forceAngle) * forceMagnitude
        spaceship.physicsBody!.applyForce(CGVector(dx: forceX, dy: forceY))
        print("Applied end force: angle \(forceAngle * 180 / .pi)°, isAbove: \(isAbove), force: (\(forceX), \(forceY))")
    }
}

extension GameScene: SKPhysicsContactDelegate {
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        Task { @MainActor in
            guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }
            let (spaceship, blackHole) = (nodeA is Spaceship) ? (nodeA as! Spaceship, nodeB as! BlackHole) : (nodeB as! Spaceship, nodeA as! BlackHole)
            
            if blackHole.zDepth <= 30 {
                print("Collision at zDepth: \(blackHole.zDepth), position: \(blackHole.position), spaceship: \(spaceship.position)")
                self.startOrbitAnimation(for: blackHole)
            } else {
                print("Collision detected (GameOver) at zDepth: \(blackHole.zDepth), position: \(contact.contactPoint)")
                NotificationCenter.default.post(name: NSNotification.Name("GameOver"), object: nil)
            }
        }
    }
}
