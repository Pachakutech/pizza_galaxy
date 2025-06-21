//
//  GameScene.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/9/25.
//

import SpriteKit
import Combine

@MainActor
class GameScene: SKScene, ObservableObject {
    @Published var spaceship: Spaceship!
    @Published var spaceshipPosition: CGPoint = .zero
    private var activeBlackHoles: [BlackHole] = []
    private var activeStars: [Star] = []
    private var inactiveCelestialBodies: [CelestialBody] = []
    private var backgroundNodes: [SKSpriteNode] = []
    private var crownDelta: Double = 0.0
    private var lastCrownInputTime: TimeInterval = 0.0
    private var verticalOffset: CGFloat = 15.0
    private var backgroundOffset: CGFloat = 0.0
    private var isAnimatingOrbit: Bool = false
    private var animatingBlackHole: BlackHole?
    private var frameCount: Int = 0
    private var placidFrameCount: Int = 0
    private var spawnIntervalFrames = 15
    private let maxCelestialBodies = 34
    private let blackHoleProbability = 0.2
    private let placidPeriodFrames = 60

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

        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        camera = cameraNode
        addChild(cameraNode)

        let backgroundTexture = SKTexture(imageNamed: "galaxy_background")
        if backgroundTexture.size() == .zero {
            print("Error: Galaxy background texture 'galaxy_background' is missing or invalid")
        }
        let backgroundWidth: CGFloat = 1024
        let backgroundHeight = size.height * 1.8
        for i in 0..<2 {
            let background = SKSpriteNode(texture: backgroundTexture, size: CGSize(width: backgroundWidth, height: backgroundHeight))
            background.position = CGPoint(x: CGFloat(i) * backgroundWidth - backgroundWidth / 2, y: size.height / 2)
            background.zPosition = -3
            addChild(background)
            backgroundNodes.append(background)
        }

        spaceship = Spaceship()
        spaceship.position = CGPoint(x: size.width / 2, y: size.height / 2)
        spaceshipPosition = spaceship.position
        spaceship.zPosition = 10
        addChild(spaceship)

        for _ in 0..<maxCelestialBodies {
            let isBlackHole = CGFloat.random(in: 0...1) < blackHoleProbability
            let body: CelestialBody = isBlackHole ? BlackHole() : Star()
            body.zPosition = -1
            body.isHidden = true
            inactiveCelestialBodies.append(body)
        }

        spaceship.physicsBody?.velocity = CGVector.zero
        print("Initial setup: spaceship position: \(spaceship.position), velocity: \(spaceship.physicsBody?.velocity ?? CGVector.zero)")
    }

    func handleTap(at location: CGPoint) {
        print("Tap at \(location), no zRotation change")
    }

    func updateCrownDelta(_ delta: Double) {
        crownDelta += delta
    }

    private func applyForceToSpaceship(forceAngle: CGFloat, forceMagnitude: CGFloat) {
        let forceX = cos(forceAngle) * forceMagnitude
        let forceZ = sin(forceAngle) * forceMagnitude // using the Y component as the control for zSpeed
        
        spawnIntervalFrames = max(1, min(80, (spawnIntervalFrames + (forceZ > 0 ? 3 : -3))))
        
        if let physicsBody = spaceship.physicsBody {
            physicsBody.applyForce(CGVector(dx: forceX, dy: 0.0))
            print("Applied force: angle \(forceAngle * 180 / .pi)°, force: (\(forceX), 0.0)")
        }
    }

    override func update(_ currentTime: TimeInterval) {
        frameCount += 1

        // Lock spaceship y-position
        spaceship.position.y = size.height / 2
        if let physicsBody = spaceship.physicsBody {
            physicsBody.velocity.dy = 0
            let maxSpeed: CGFloat = 200.0
            physicsBody.velocity.dx = max(min(physicsBody.velocity.dx, maxSpeed), -maxSpeed)
        }

        if let camera = camera {
            camera.position = spaceship.position
        }

        if crownDelta != 0 {
            lastCrownInputTime = currentTime
            spaceship.applyThrust(crownDelta: crownDelta)
            verticalOffset += CGFloat(crownDelta) * 15.0
            verticalOffset = min(max(verticalOffset, -size.height * 0.4), size.height * 0.4)
            crownDelta = 0
        } else if currentTime - lastCrownInputTime > 0.25 {
            spaceship.hideThrusters()
        }

        // Background update
        let backgroundWidth: CGFloat = 1024
        let backgroundHeight = size.height * 1.8
        let cameraX = spaceship.position.x
        let maxOffset = size.height * 0.4
        let baseSpeed: CGFloat = maxOffset / (60 * 10)
        let speedFactor = baseSpeed * (verticalOffset / maxOffset)
        backgroundOffset += speedFactor
        backgroundOffset = min(max(backgroundOffset, -maxOffset), maxOffset)
        let backgroundY = size.height / 2 - backgroundOffset
        if let physicsBody = spaceship.physicsBody {
            let velocityX = physicsBody.velocity.dx
            let scrollSpeed: CGFloat = 0.1
            let scrollOffsetX = velocityX * scrollSpeed * (1.0 / 60.0)
            for background in backgroundNodes {
                var newX = background.position.x - scrollOffsetX
                if newX < cameraX - backgroundWidth / 2 - size.width / 2 {
                    newX += backgroundWidth * 2
                } else if newX > cameraX + backgroundWidth / 2 + size.width / 2 {
                    newX -= backgroundWidth * 2
                }
                background.position = CGPoint(x: newX, y: backgroundY)
            }
        }
        print("Background y=\(backgroundY), verticalOffset=\(verticalOffset), backgroundOffset=\(backgroundOffset), speedFactor=\(speedFactor)")

        // Spawn one celestial body every 15 frames
        if frameCount % spawnIntervalFrames == 0 && (activeBlackHoles.count + activeStars.count) < maxCelestialBodies && !isAnimatingOrbit {
            let isBlackHole = CGFloat.random(in: 0...1) < blackHoleProbability
            let newBody: CelestialBody
            if isBlackHole, let inactiveBody = inactiveCelestialBodies.first(where: { $0 is BlackHole }) {
                newBody = inactiveBody
                inactiveCelestialBodies.removeAll { $0 === inactiveBody }
            } else if !isBlackHole, let inactiveBody = inactiveCelestialBodies.first(where: { $0 is Star }) {
                newBody = inactiveBody
                inactiveCelestialBodies.removeAll { $0 === inactiveBody }
            } else {
                newBody = isBlackHole ? BlackHole() : Star()
            }
            newBody.reset(spaceshipX: spaceship.position.x, spaceshipY: spaceship.position.y, verticalOffset: verticalOffset)
            newBody.zPosition = -1
            if newBody.parent == nil {
                addChild(newBody)
            }
            if isBlackHole {
                (newBody as? BlackHole)?.updateJetAngle()
                activeBlackHoles.append(newBody as! BlackHole)
            } else {
                activeStars.append(newBody as! Star)
            }
            print("Spawned \(isBlackHole ? "BlackHole" : "Star") at angle: \(newBody.initialAngle * 180 / .pi)°, distance: \(newBody.initialDistance)")
        }

        if isAnimatingOrbit {
            if let collidedBlackHole = animatingBlackHole {
                collidedBlackHole.zDepth -= collidedBlackHole.zSpeed
                if collidedBlackHole.zDepth <= 0 {
                    collidedBlackHole.isHidden = true
                    collidedBlackHole.removeFromParent()
                    activeBlackHoles.removeAll { $0 === collidedBlackHole }
                    inactiveCelestialBodies.append(collidedBlackHole)
                    print("Collided black hole at zDepth <= 0, moved to inactive")
                }
            }
            return
        }

        // Update active celestial bodies
        var bodiesToReset: [CelestialBody] = []
        for body in activeBlackHoles + activeStars {
            body.zDepth -= body.zSpeed
            if body.zDepth <= 0 {
                bodiesToReset.append(body)
            } else {
                // Update position and scale for all bodies
                body.updatePositionAndScale(spaceshipX: spaceship.position.x, spaceshipY: spaceship.position.y, verticalOffset: verticalOffset)

                // Skip collision checks and gravitational force for zDepth > 50
                if body.zDepth <= 50 {
                    // Body collision
                    let distance = spaceship.position.distance(to: body.position)
                    let collisionThreshold = (spaceship.size.width / 2 + body.size.width / 2)
                    if distance < collisionThreshold && body.zDepth < 10 {
                        print("Collision with \(body is BlackHole ? "BlackHole" : "Star") at zDepth: \(body.zDepth), position: \(body.position)")
                        if body is BlackHole {
                            startOrbitAnimation(for: body as! BlackHole)
                        } else {
                            print("Star collision detected, TBI game state or texture change")
                            bodiesToReset.append(body)
                        }
                    }

                    // Jet hit box collisions for black holes
                    if let blackHole = body as? BlackHole {
                        let jetHitBoxes = blackHole.getJetHitBoxes()
                        for (hitBox, isTop) in jetHitBoxes {
                            let hitBoxWorldPosition = blackHole.convert(hitBox.position, to: self)
                            let distanceToHitBox = spaceship.position.distance(to: hitBoxWorldPosition)
                            let hitBoxSize = hitBox.size
                            let collisionThreshold = (spaceship.size.width / 2 + hitBoxSize.width / 2)
                            if distanceToHitBox < collisionThreshold {
                                let distanceToBlackHole = spaceship.position.distance(to: blackHole.position)
                                let maxForce: CGFloat = 60000.0
                                let baseForce = maxForce * (1.0 - body.zDepth / 100.0) // practically, always > 50%
                                // Calculate force gradient based on position along hit box length
                                let hitBoxLocalSpaceshipPos = blackHole.convert(spaceship.position, from: self)
                                let hitBoxLength = hitBox.size.height // 75.0
                                let baseY = isTop ? blackHole.size.height / 2 : -blackHole.size.height / 2 // ±10.0
                                let tipY = isTop ? baseY + hitBoxLength : baseY - hitBoxLength // ±85.0
                                let relativeY = isTop ? hitBoxLocalSpaceshipPos.y : -hitBoxLocalSpaceshipPos.y
                                let t = max(0.0, min(1.0, (relativeY - baseY) / (tipY - baseY))) // 0 at base, 1 at tip
                                let forceScale = 1.0 - 0.75 * t // 1.0 at base, 0.25 at tip
                                // Calculate repulsive force direction turned in the frame of reference of the spaceship
                                let forceAngle = blackHole.zRotation - (isTop ? 0 : .pi) + .pi / 2
                                let forceMagnitude = (baseForce * forceScale) / max(1.0, body.zDepth)
                                applyForceToSpaceship(forceAngle: forceAngle, forceMagnitude: forceMagnitude)
                                print("Jet hit box collision: distanceToBlackHole=\(distanceToBlackHole), zDepth=\(body.zDepth), forceMagnitude=\(forceMagnitude), forceAngle=\(forceAngle * 180 / .pi)°, t=\(t), forceScale=\(forceScale)")
                            }
                        }
                    }

                    // Apply gravitational force only for zDepth <= 50
                    body.applyGravitationalForce(to: spaceship)
                }
            }
        }

        // Reset bodies
        for body in bodiesToReset {
            body.isHidden = true
            body.removeFromParent()
            activeBlackHoles.removeAll { $0 === body }
            activeStars.removeAll { $0 === body }
            inactiveCelestialBodies.append(body)
        }

        spaceshipPosition = spaceship.position
    }

    private func startOrbitAnimation(for blackHole: BlackHole) {
        isAnimatingOrbit = true
        animatingBlackHole = blackHole

        spawnIntervalFrames = 14
        
        let radius: CGFloat = 20.0
        let orbitPath = UIBezierPath(arcCenter: spaceship.position, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let orbitAction = SKAction.follow(orbitPath.cgPath, asOffset: false, orientToPath: false, duration: 3.0)
        let repeatOrbit = SKAction.repeat(orbitAction, count: 2)
        

        for body in activeBlackHoles {
            if body !== blackHole {
                body.run(repeatOrbit)
                print("Started orbit animation for \(body is BlackHole ? "BlackHole" : "Star") at position: \(body.position)")
            }
        }
        
        for body in activeStars{
            body.run(repeatOrbit)
            print("Started orbit animation for \(body is BlackHole ? "BlackHole" : "Star") at position: \(body.position)")
        }

        let wait = SKAction.wait(forDuration: 3.0)
        let endAnimation = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isAnimatingOrbit = false
            if let animatingBlackHole = self.animatingBlackHole {
              self.applyEndForce(to: animatingBlackHole)
            }
            self.activeBlackHoles.forEach { $0.isHidden = true; $0.removeFromParent() }
            self.activeStars.forEach { $0.isHidden = true; $0.removeFromParent() }
            self.inactiveCelestialBodies.append(contentsOf: self.activeBlackHoles)
            self.inactiveCelestialBodies.append(contentsOf: self.activeStars)
            self.activeBlackHoles.removeAll()
            self.activeStars.removeAll()
            self.placidFrameCount = self.placidPeriodFrames
            self.animatingBlackHole = nil
        }
        run(SKAction.sequence([wait, endAnimation]))
    }

    private func applyEndForce(to blackHole: BlackHole) {
        let jetAngle = blackHole.zRotation
        let isAbove = spaceship.position.y > blackHole.position.y
        let forceAngle = isAbove ? jetAngle + .pi : jetAngle
        let forceMagnitude: CGFloat = 80000.0
        applyForceToSpaceship(forceAngle: forceAngle, forceMagnitude: forceMagnitude)
    }
}
