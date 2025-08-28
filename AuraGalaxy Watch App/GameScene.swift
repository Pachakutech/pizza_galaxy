//
//  GameScene.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/9/25.
//

import SpriteKit
import Combine

let maxSpaceshipSpeedX: CGFloat = 200.0
let zSpeedDefault: CGFloat = 30.0 / 100.0
let zSpeedUpperLimit = zSpeedDefault * 5.0
let zSpeedLowerLimit = zSpeedDefault / 10.0
let bgScrollSpeed: CGFloat = 0.2 / 60.0
let celestialScrollSpeed: CGFloat = 1.0 / 60.0
let maxJetForce: CGFloat = 2000.0
let xDamping: CGFloat = 0.95
let blackHoleEjectionForceMagnitude: CGFloat = 1.0
let zConversionFactor: CGFloat = 100000.0
let gravitationalConstant: CGFloat = 10
let verticalOffsetSigma: CGFloat = 0.4
let verticalOffsetDefault: CGFloat = 25.0
let bowDepth: CGFloat = 20.0 // Depth of downward bow at screen edges
let crownDeltaMax: CGFloat = 5.0 // Max crown delta per frame

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
    private var verticalOffset: CGFloat = verticalOffsetDefault
    private var yBackgroundOffset: CGFloat = 0.0
    private var isAnimatingOrbit: Bool = false
    private var animatingBlackHole: BlackHole?
    private var frameCount: Int = 0
    private var placidFrameCount: Int = 0
    private var spawnIntervalFrames = 15
    private var zAccDelta: CGFloat = 0.0
    private var zSpeedAvg: CGFloat = zSpeedDefault
    private var apparentSpaceshipXVelocity: CGFloat = 0.0
    private var spaceshipXForce: CGFloat = 0.0
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

        print("Initial setup: spaceship position: \(spaceship.position), xVelocity: \(apparentSpaceshipXVelocity)")
    }

    func handleTap(at location: CGPoint) {
        print("Tap at \(location), no action defined")
    }

    func updateCrownDelta(_ delta: Double) {
        crownDelta = max(min(delta, Double(crownDeltaMax)), -Double(crownDeltaMax)) // Clamp delta
        print("Crown delta updated: \(crownDelta)")
    }

    override func update(_ currentTime: TimeInterval) {
        frameCount += 1
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        let zAccBase = zAccDelta
        zAccDelta = 0.0
        if zAccBase != 0.0 {
            print("Set zAccBase to \(zAccBase) from accDelta \(zAccDelta) when zSpeedAvg \(zSpeedAvg)")
        }

        // Update spaceship position and velocity
        apparentSpaceshipXVelocity = apparentSpaceshipXVelocity * xDamping + spaceshipXForce + (spaceship.position.x - centerX) / 4
        apparentSpaceshipXVelocity = min(max(-maxSpaceshipSpeedX, apparentSpaceshipXVelocity), maxSpaceshipSpeedX)
        let newX = min(max(size.width * 0.1, spaceship.position.x + CGFloat(crownDelta)), size.width * 0.9)
//        let newX = min(size.width * 0.9, max(spaceship.position.x + CGFloat(crownDelta), size.width * 0.1))
        // bow: y = a(x - h)^2 + k
        let a = bowDepth / pow(size.width * 0.4, 2) // Parabola coefficient
        let h = centerX
        let k = centerY
        let newY = -20 + a * pow(newX - h, 2) + k
        spaceship.position = CGPoint(x: newX, y: newY)
        spaceshipXForce = 0.0 // Reset forces
        spaceshipPosition = spaceship.position
        let xCelestialOffset = -apparentSpaceshipXVelocity * celestialScrollSpeed
        crownDelta = 0 // Reset crownDelta
        
        // Update camera
        if let camera = camera {
            camera.position.y = centerY
            camera.position.x = centerX
        }

        // Handle crown input (y-axis for celestial bodies)
        if crownDelta != 0 {
            lastCrownInputTime = currentTime
            spaceship.applyThrust(crownDelta: crownDelta)
//            verticalOffset += CGFloat(crownDelta) * 15.0
//            verticalOffset = min(max(verticalOffset, -size.height * verticalOffsetSigma), size.height * verticalOffsetSigma)
            print("Crown input: delta=\(crownDelta), verticalOffset=\(verticalOffset)")
        } else if currentTime - lastCrownInputTime > 0.25 {
            spaceship.hideThrusters()
        }

        // Update background
        let backgroundWidth: CGFloat = 1024
        let yMaxOffset = size.height * 0.4
        let yBaseSpeed: CGFloat = yMaxOffset / (60 * 10)
        let ySpeedFactor = yBaseSpeed * (verticalOffset / yMaxOffset)
        yBackgroundOffset += ySpeedFactor
        yBackgroundOffset = min(max(yBackgroundOffset, -yMaxOffset), yMaxOffset)
        let yBackgroundPosition = centerY - yBackgroundOffset
        let xScrollOffset = apparentSpaceshipXVelocity * bgScrollSpeed
        for background in backgroundNodes {
            var newX = background.position.x + xScrollOffset
            if newX < centerX - backgroundWidth / 2 - centerX {
                newX += backgroundWidth * 2
            } else if newX > centerX + backgroundWidth / 2 + centerX {
                newX -= backgroundWidth * 2
            }
            background.position = CGPoint(x: newX, y: yBackgroundPosition)
        }
        print("Background y=\(yBackgroundPosition), verticalOffset=\(verticalOffset), yBackgroundOffset=\(yBackgroundOffset), ySpeedFactor=\(ySpeedFactor)")

        // Update celestial bodies
        var bodiesToReset: [CelestialBody] = []
        for body in activeBlackHoles + activeStars {
            body.zDepth -= body.zSpeed
            if body.zDepth <= 0 {
                bodiesToReset.append(body)
            } else {
                body.updatePositionAndScale(centerX: centerX, spaceshipY: centerY, verticalOffset: verticalOffset, xOffset: xCelestialOffset)

                let distance = spaceship.position.distance(to: body.position)
                body.zSpeed = max(zSpeedLowerLimit, min(zSpeedUpperLimit, body.zSpeed + zAccBase))
                zSpeedAvg += (body.zSpeed - zSpeedAvg) / CGFloat(activeStars.count + 1)

                if body.zDepth <= 30 {
                    // Collision detection
                    let collisionThreshold = (spaceship.size.width / 2 + body.size.width / 2)
                    if distance < collisionThreshold {
                        if body is BlackHole {
                            startOrbitAnimation(for: body as! BlackHole)
                        } else {
                            print("Star collision detected, changing to lovey_face")
                            body.changeFace(to: "lovey_face")
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
                                applyJetForce(blackHole, body, hitBox, isTop)
                            }
                        }
                    }

                    // Apply gravitational force
                    applyGravitationalForce(from: body)
                }
            }
        }

        // Spawn celestial bodies
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
            newBody.reset(xOffset: apparentSpaceshipXVelocity, yOffset: 0.0, verticalOffset: verticalOffset, zNewSpeed: zSpeedAvg)
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
            print("Spawned \(isBlackHole ? "BlackHole" : "Star") at angle: \(newBody.direction * 180 / .pi)°, distance: \(newBody.radialMagnitude)")
        }

        if isAnimatingOrbit {
            if let collidedBlackHole = animatingBlackHole {
                collidedBlackHole.zDepth -= collidedBlackHole.zSpeed
                if collidedBlackHole.zDepth <= 0 {
                    collidedBlackHole.isHidden = true
                    collidedBlackHole.removeFromParent()
                    activeBlackHoles.removeAll { $0 === collidedBlackHole }
                    inactiveCelestialBodies.append(collidedBlackHole)
                }
            }
            return
        }

        // Reset bodies
        for body in bodiesToReset {
            body.isHidden = true
            body.removeFromParent()
            body.zSpeed = zSpeedAvg
            activeBlackHoles.removeAll { $0 === body }
            activeStars.removeAll { $0 === body }
            inactiveCelestialBodies.append(body)
        }

        spaceshipPosition = spaceship.position
    }

    private func startOrbitAnimation(for blackHole: BlackHole) {
        isAnimatingOrbit = true
        animatingBlackHole = blackHole
        zAccDelta = 0
        verticalOffset = verticalOffsetDefault

        let radius: CGFloat = 20.0
        let orbitPath = UIBezierPath(arcCenter: spaceship.position, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let orbitAction = SKAction.follow(orbitPath.cgPath, asOffset: false, orientToPath: false, duration: 3.0)
        let repeatOrbit = SKAction.repeat(orbitAction, count: 2)

        for body in activeBlackHoles {
            if body !== blackHole {
                body.run(repeatOrbit)
                print("Started orbit animation for BlackHole at position: \(body.position)")
            }
        }

        for body in activeStars {
            body.run(repeatOrbit)
            body.changeFace(to: "silly_face")
            print("Started orbit animation for Star at position: \(body.position)")
        }

        applyEndForce(to: blackHole)
        let wait = SKAction.wait(forDuration: 3.0)
        let endAnimation = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isAnimatingOrbit = false
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

    private func applyGravitationalForce(from body: CelestialBody) {
        let direction = CGFloat(atan2(body.position.y - spaceship.position.y, body.position.x - spaceship.position.x))
        let distance = body.position.distance(to: body.position)
        let denominator = max(distance * distance, 1.0)
        let gravForceMagnitude = (gravitationalConstant * body.mass) / denominator
        print("Applying gravitational force of \(gravForceMagnitude) at forceAngle \(direction * 180 / .pi)°")
        applyForceToSpaceship(forceAngle: direction, forceMagnitude: gravForceMagnitude)
    }

    func applyJetForce(_ blackHole: BlackHole, _ body: CelestialBody, _ hitBox: SKSpriteNode, _ isTop: Bool) {
        print("Applying jet force for Jet hit box")
        let distanceToBlackHole = spaceship.position.distance(to: blackHole.position)
        let baseForce = maxJetForce * (1.0 - body.zDepth / 100.0)
        let hitBoxLocalSpaceshipPos = blackHole.convert(spaceship.position, from: self)
        let hitBoxLength = hitBox.size.height
        let baseY = isTop ? blackHole.size.height / 2 : -blackHole.size.height / 2
        let tipY = isTop ? baseY + hitBoxLength : baseY - hitBoxLength
        let relativeY = isTop ? hitBoxLocalSpaceshipPos.y : -hitBoxLocalSpaceshipPos.y
        let t = max(0.0, min(1.0, (relativeY - baseY) / (tipY - baseY)))
        let forceScale = 1.0 - 0.75 * t
        let forceAngle = blackHole.zRotation - (isTop ? 0 : .pi) + .pi / 2
        let forceMagnitude = (baseForce * forceScale * 0.25) / max(1.0, body.zDepth)
        applyForceToSpaceship(forceAngle: forceAngle, forceMagnitude: forceMagnitude)
        print("Jet hit box collision: distanceToBlackHole=\(distanceToBlackHole), zDepth=\(body.zDepth), forceMagnitude=\(forceMagnitude), forceAngle=\(forceAngle * 180 / .pi)°, t=\(t), forceScale=\(forceScale)")
    }

    private func applyEndForce(to blackHole: BlackHole) {
        let jetAngle = blackHole.zRotation
        let isAbove = spaceship.position.y > blackHole.position.y
        let forceAngle = isAbove ? jetAngle + .pi : jetAngle
        print("Applying end force at forceAngle \(forceAngle * 180 / .pi)° magnitude \(blackHoleEjectionForceMagnitude)")
        applyForceToSpaceship(forceAngle: forceAngle, forceMagnitude: blackHoleEjectionForceMagnitude)
    }

    private func applyForceToSpaceship(forceAngle: CGFloat, forceMagnitude: CGFloat) {
        let forceX = cos(forceAngle) * forceMagnitude
        let forceZ = sin(forceAngle) * forceMagnitude
        zAccDelta += CGFloat(forceZ / zConversionFactor)
        spaceshipXForce += forceX * 0.7
        print("Applied force: forceAngle \(forceAngle * 180 / .pi)°, forceX: \(forceX), forceZ: \(forceZ)")
    }
}
