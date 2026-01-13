//
//  GameScene.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 6/9/25.
//

import AVFoundation
import Combine
import SpriteKit
import WatchKit

let maxSpeedX: CGFloat = 28.8
let maxSpeedY: CGFloat = 28.8
let zSpeedDefault: CGFloat = 20.0 / 100.0
let zSpeedUpperLimit = zSpeedDefault * 15.0
let zSpeedLowerLimit = zSpeedDefault / 10.0
let bgScrollSpeed: CGFloat = 30.0
let celestialScrollSpeedFactor: CGFloat = 1.0 / 60.0
let maxJetForce: CGFloat = 2000.0
let spaceshipMass: CGFloat = 100.5
let gravityFalloffPower: CGFloat = 1.0
let jetForceScale: CGFloat = 5.25
let xyDamping: CGFloat = 0.95
let blackHoleEjectionForceMagnitude: CGFloat = 800.0
let zConversionFactor: CGFloat = 1000.0
let gravitationalConstant: CGFloat = 0.1
let verticalOffsetSigma: CGFloat = 0.4
let verticalOffsetDefault: CGFloat = 25.0
let horizontalOffsetDefault: CGFloat = 0.0
let bowDepth: CGFloat = 20.0
let fps: CGFloat = 60.0
let crownDeltaMax: CGFloat = 5.0
let backgroundWidth: CGFloat = 1024
let backgroundHeight: CGFloat = 768

@MainActor
class GameScene: SKScene, ObservableObject {
    @Published var spaceship: Spaceship!
    @Published var spaceshipPosition: CGPoint = .zero
    var activeBlackHoles: [ZDepthBody] = []
    var activeStars: [ZDepthBody] = []
    var activeToppings: [ZDepthBody] = []
    var inactiveZBodies: [ZDepthBody] = []
    private var scores: [ToppingType: Int] = [:]
    private var scoreboard = SKNode()
    private var scoreboardIcon = SKSpriteNode(imageNamed: "yellow_star")
    private var scoreboardScore = SKLabelNode(text: "")
    private var scoreBoardTimer: Timer?
    private var lastScoreTimestamp: TimeInterval = 0.0
    private var lastScoreDuration: TimeInterval = 3.0
    private var backgroundNodes: [SKSpriteNode] = []
    private var crownDelta: Double = 0.0
    private var lastCrownInputTime: TimeInterval = 0.0
    private var lastUpdateTime: TimeInterval = 0.0
    private var dragCoef: CGFloat = 0.0
    private var ySpeed: CGFloat = 0.0
    private var yAcc: CGFloat = 0.0
    private var yBackgroundOffset: CGFloat = 0.0
    private var xSpeed: CGFloat = 0.0
    private var xAcc: CGFloat = 0.0
    private var isAnimatingOrbit: Bool = false
    private var animatingBlackHole: BlackHole?
    private var frameCount: Int = 0
    private var zSpeedDelta: CGFloat = 0.0
    private var zSpeedAvg: CGFloat = zSpeedDefault
    private var collisionSoundAction: SKAction?
    private var backgroundSprite: SKSpriteNode?
    private var rainbowEffect: SKEmitterNode?
    private var currentLevel = 1
    private var spawnIntervalFrames = 5
    private let maxCelestialBodies = 54
    private let blackHoleProbability = 0.1
    private let toppingProbability = 1.0
    private var yMaxOffset: CGFloat { backgroundHeight - 2.2 * size.height }
    private var centerX: CGFloat { size.width / 2 }
    private var centerY: CGFloat { size.height / 2 }
    private let tunnelShaderManager = TunnelShaderManager()
    private let galaxyShaderManager = GalaxyShaderManager()
    private var tunnelMode = true
    private var timeOnGalaxy = 0
    private var tractorBeamAnimator: TractorBeamAnimator!
    private var forceArrow = ForceArrow()

    override init(size: CGSize) {
        super.init(size: size)
        setupAudioSession()
        setupScene()
        tractorBeamAnimator = TractorBeamAnimator(scene: self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAudioSession()
        setupScene()
        tractorBeamAnimator = TractorBeamAnimator(scene: self)
    }

    private func setupScene() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        camera = cameraNode
        if let camera = camera {
            camera.position.y = centerY
            camera.position.x = centerX
        }
        addChild(cameraNode)

        backgroundSprite = SKSpriteNode(color: .white, size: size)
        backgroundSprite?.shader = tunnelShaderManager.getTunnelShader()
        backgroundSprite?.position = CGPoint(x: centerX, y: centerY)
        backgroundSprite?.zPosition = -3
        addChild(backgroundSprite!)

        if let emitter = SKEmitterNode(fileNamed: "rainbow.sks") {
            rainbowEffect = emitter
            rainbowEffect?.zPosition = -2
            rainbowEffect?.isHidden = true
            addChild(rainbowEffect!)
        } else {
            print("Error: Failed to load rainbow.sks")
        }

        spaceship = Spaceship()
        spaceship.position = CGPoint(x: size.width / 2, y: size.height / 2)
        spaceshipPosition = spaceship.position
        spaceship.zPosition = 10
        addChild(spaceship)

        for _ in 0..<maxCelestialBodies / 4 {
            let body: ZDepthBody = Topping()
            body.zPosition = -1
            body.isHidden = true
            inactiveZBodies.append(body)
        }
        for _ in 0..<maxCelestialBodies {
            let isBlackHole = CGFloat.random(in: 0...1) < blackHoleProbability
            let body: ZDepthBody = isBlackHole ? BlackHole() : Star()
            body.zPosition = -1
            body.isHidden = true
            inactiveZBodies.append(body)
        }

        scoreboardIcon.size.width = 20
        scoreboardIcon.size.height = 20
        scoreboardIcon.position = CGPoint(x: 24.0, y: 0.0)
        scoreboard.addChild(scoreboardIcon)

        scoreboardScore.horizontalAlignmentMode = .right
        scoreboardScore.fontSize = 22
        scoreboardScore.fontColor = .white
        scoreboardScore.position = CGPoint(
            x: scoreboardIcon.position.x - 14.0,
            y: scoreboardIcon.position.y - 9.0
        )
        scoreboard.addChild(scoreboardScore)

        scoreboard.position = CGPoint(
            x: size.width * 4 / 5,
            y: size.height * 4 / 5
        )
        scoreboard.isHidden = true
        addChild(scoreboard)

        forceArrow.position = CGPoint(
            x: size.width * 4 / 5,
            y: size.height * 2 / 3
        )
        addChild(forceArrow)
    }

    private func setupAudioSession() {
        print("setting up audio session")
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true)
            print("Audio session configured for playback")
        } catch {
            print(
                "Failed to set up audio session: \(error.localizedDescription)"
            )
        }
        let soundAction = SKAction.playSoundFileNamed(
            "collisionSound.caf",
            waitForCompletion: false
        )
        collisionSoundAction = soundAction
        print("Collision sound preloaded")
    }

    func handleTap(at location: CGPoint) {
        print("Tap location: \(location)")
        let touchedNodes = nodes(at: location)
        var closestBody: ZDepthBody? = nil
        var minDist: CGFloat = .greatestFiniteMagnitude

        // Check touched + find nearest active body for comparison
        for node in touchedNodes {
            print(
                "Touched: type=\(String(describing: type(of: node))), frame=\(node.calculateAccumulatedFrame())"
            )
            var current: SKNode? = node
            while current != nil {
                if let body = current as? CelestialBody,
                    !body.bodyState.isBeingTractored && !body.bodyState.hit
                {
                    print(
                        "Handling body: \(type(of: body)), frame=\(body.calculateAccumulatedFrame())"
                    )
                    handleCelestialBodyTap(body)
                    return
                }
                current = current?.parent
            }
        }

        // Find nearest active body for miss debug
        for body in activeStars + activeBlackHoles {
            let bodyFrame = body.calculateAccumulatedFrame()
            let dist = distanceFromRect(bodyFrame, toPoint: location)
            if dist < minDist {
                minDist = dist
                closestBody = body
            }
        }
        if let closest = closestBody {
            print(
                "Missed closest \(type(of: closest)): dist to frame=\(minDist), its frame=\(closest.calculateAccumulatedFrame())"
            )
        }
        print("No body touched")
    }

    func distanceFromRect(_ rect: CGRect, toPoint point: CGPoint) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return sqrt(dx * dx + dy * dy)
    }

    private func handleCelestialBodyTap(_ body: CelestialBody) {
        guard !tunnelMode else {
            print("Tap ignored: Not in FreeNav mode")
            return
        }
        print("got tap on a star? \(body is Star)")
        tractorBeamAnimator.startDragWithBeam(on: body, from: spaceship)
    }

    private func classifyCompassPoint(offsetH: Float, offsetV: Float)
        -> CompassPoint
    {
        let absH = abs(offsetH)
        let absV = abs(offsetV)
        let isDiagonal = abs(absH - absV) < 0.5

        if isDiagonal {
            if offsetH > 0 && offsetV > 0 { return .topRight }
            if offsetH > 0 && offsetV < 0 { return .bottomRight }
            if offsetH < 0 && offsetV < 0 { return .bottomLeft }
            if offsetH < 0 && offsetV > 0 { return .topLeft }
        }
        if absH > absV {
            return offsetH > 0 ? .right : .left
        } else {
            return offsetV > 0 ? .top : .bottom
        }
    }

    override func update(_ currentTime: TimeInterval) {
        print(
            "update with \(activeBlackHoles.count + activeStars.count) active stars and \(activeToppings.count) Toppings"
        )
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        let dt = CGFloat(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

        frameCount += Int(fps * dt)

        let zAccBase = zSpeedDelta
        zSpeedDelta = 0.0
        zSpeedAvg = (7 * zSpeedAvg + zSpeedDefault) / 8

        forceArrow.updateForceArrow(forceX: -xAcc, forceY: -yAcc)

        xSpeed += xAcc * dt * fps
        ySpeed += yAcc * dt * fps
//        xSpeed *= pow(xyDamping, dt * fps)
//        ySpeed *= pow(xyDamping, dt * fps)
        //        xSpeed -= dragCoef * xSpeed * dt * fps
        //        ySpeed -= dragCoef * ySpeed * dt * fps
        xSpeed = min(max(-maxSpeedX, xSpeed), maxSpeedX)
        ySpeed = min(max(-maxSpeedY, ySpeed), maxSpeedY)
        let xScrollOffset = xSpeed * dt * fps
        let yScrollOffset = ySpeed * dt * fps
        //                xOffset = min(max(-centerX, xOffset), centerX)
        //                yOffset = min(max(-centerY, yOffset), centerY)
        print("updating X axis with force \(xAcc) speed\(xSpeed) and offset \(xScrollOffset)")
        xAcc *= 0.0
        yAcc *= 0.0

        if let camera = camera {
            camera.position.y = centerY
            camera.position.x = centerX
        }

        if crownDelta != 0 {
            lastCrownInputTime = currentTime
            spaceship.applyThrust(crownDelta: crownDelta)
        } else if currentTime - lastCrownInputTime > 0.25 {
            spaceship.hideThrusters()
        }

        galaxyShaderManager.addScrollH(scroll: Float(-xScrollOffset / 5000))
        galaxyShaderManager.addScrollV(scroll: Float(-yScrollOffset / 5000))
        tunnelShaderManager.addScrollX(scroll: Float(-xScrollOffset / 5000))
        tunnelShaderManager.addScrollZ(scroll: Float(zSpeedAvg / 60))
        tunnelShaderManager.addScrollRotate(scroll: Float(xSpeed / 3000))
        if tunnelShaderManager.isOutOfBounds() && tunnelMode {
            tunnelMode = false
            beginFreeNav()
        }

        // apply force of spaceship position to world
        let newX = min(
            max(size.width * 0.1, spaceship.position.x + CGFloat(crownDelta)),
            size.width * 0.9
        )
        let a = bowDepth / pow(size.width * 0.4, 2)
        let h = centerX
        let baseline = centerY - 70
        let xDelta = newX - h
        let parabola: CGFloat = a * pow(xDelta, 2)
        let newY = parabola + baseline
        spaceship.position = CGPoint(x: newX, y: newY)
        spaceship.zRotation = CGFloat(xDelta / 128)
        spaceshipPosition = spaceship.position
        crownDelta = 0

        // Apply force based on spaceship position
        xAcc += (xDelta / 5) / 10
        yAcc += (parabola - 6) / 10

        // Galaxy detection
        let offsets = galaxyShaderManager.currentGalaxyOffsets()
        var isGalaxyVisible = false
        var closestOffset: (Float, Float)? = nil
        var minDistance: Float = .greatestFiniteMagnitude

        for (offsetH, offsetV) in offsets {
            let distance = sqrt(offsetH * offsetH + offsetV * offsetV)
            if distance < minDistance {
                minDistance = distance
                closestOffset = (offsetH, offsetV)
            }
            if abs(offsetH) <= 0.5 && abs(offsetV) <= 0.5 {
                isGalaxyVisible = true
                break
            }
        }

        if let rainbow = rainbowEffect {
            if isGalaxyVisible || tunnelMode {
                rainbow.isHidden = true
            } else if let (offsetH, offsetV) = closestOffset {
                let compassPoint = classifyCompassPoint(
                    offsetH: -offsetH,
                    offsetV: -offsetV
                )
                rainbow.position = compassPoint.position(
                    size: size,
                    centerX: centerX,
                    centerY: centerY
                )
                rainbow.zRotation = compassPoint.rotation
                rainbow.isHidden = false
            } else {
                rainbow.isHidden = true
            }
        }

        if isGalaxyVisible {
            timeOnGalaxy += Int(60 * dt)
        } else {
            timeOnGalaxy = 0
        }
        //        print(
        //            "updating at offset x \(xCelestialOffset) y \(yCelestialOffset) timeOnGalaxy: \(timeOnGalaxy) with first galaxy offset: \(offsets.map{offsetH, offsetV in "h:\(offsetH) v:\(offsetV)"}.first ?? "none" ) and shaderCumulH:\(galaxyShaderManager.getCumulativeScrollH()) V:\(galaxyShaderManager.getCumulativeScrollV())"
        //        )
        if timeOnGalaxy > 10 && !tunnelMode {
            tunnelMode = !tunnelMode
            print("beginning tunnel")
            beginTunnel()
        }
        //        for (offsetH, offsetV) in offsets {
        //            if abs(offsetH) < 0.01 && abs(offsetV) < 0.01 {
        //                currentLevel += 1
        //                galaxyShaderManager.setGalaxyTexture(forLevel: currentLevel)
        //                let newRandomPeriodsH = Float.random(in: 3...10)
        //                let newRandomPeriodsV = Float.random(in: 3...10)
        //                let newThresholdH =
        //                    galaxyShaderManager.getCumulativeScrollH()
        //                    - newRandomPeriodsH * 1.0
        //                let newThresholdV =
        //                    galaxyShaderManager.getCumulativeScrollV()
        //                    - newRandomPeriodsV * 1.0
        //                galaxyShaderManager.updateAppearanceThreshold(
        //                    newValueH: newThresholdH,
        //                    newValueV: newThresholdV
        //                )
        //                break
        //            }
        //        }

        // Perform apparent physics
        var bodiesToReserve: [ZDepthBody] = []
        for body in activeBlackHoles + activeStars + activeToppings {
            body.bodyState.zDepth -= body.bodyState.zSpeed * dt * fps
            if body.bodyState.zDepth <= 0 {
                bodiesToReserve.append(body)
            } else {
                if !body.bodyState.isBeingTractored {  // tractored are not updated in x and y position
                    body.updatePositionAndScale(
                        centerX: centerX,
                        centerY: centerY,
                        xOffset: -xScrollOffset / 8 * dt * fps,
                        yOffset: -yScrollOffset / 8 * dt * fps,
                    )
                    body.bodyState.zSpeed = max(
                        zSpeedLowerLimit,
                        min(
                            zSpeedUpperLimit,
                            body.bodyState.zSpeed + zAccBase * dt * fps
                        )
                    )
                    zSpeedAvg +=
                        (body.bodyState.zSpeed - zSpeedAvg)
                        / CGFloat(activeStars.count + 1)
                }

                //                if body is Star {
                //                    print(
                //                        "Active star: pos=\(body.position), hidden=\(body.isHidden), scale=\(body.xScale), zDepth=\(body.zDepth) is \(body.position.y >= 0 && body.position.y < size.height && body.position.x >= 0 && body.position.x < size.width ? "" : "not") within bounds"
                //                    )
                //                }

                let distance = spaceship.position.distance(to: body.position)
                if (body.bodyState.zDepth <= 30 || !body.bodyState.hit)
                    && !body.bodyState.isBeingTractored
                {  // does this always protect against
                    let collisionThreshold =
                        (spaceship.size.width)
                    if distance < collisionThreshold && (!body.bodyState.hit) {
                        if body is BlackHole {
                            ySpeed = 0.0
                            xSpeed = 0.0
                        } else {
                            zSpeedDelta += zSpeedDefault * 3 / 4
                            if let soundAction = collisionSoundAction {
                                run(soundAction)
                            }
                            if let topping = body as? Topping {
                                let score =
                                    (scores[topping.toppingType] ?? 0) + 1
                                scores[topping.toppingType] = score
                                // Show score for topping type
                                scoreboardIcon.texture =
                                    topping.toppingType.texture
                                scoreboardScore.text = "\(score)"
                                scoreboard.isHidden = false
                                lastScoreTimestamp = currentTime

                            }
                            tractorBeamAnimator.startPostAnimation(
                                on: body,
                                from: spaceship
                            )
                        }
                        body.bodyState.hit = true
                    }
                    applyGravitationalForce(from: body)
                }

                if let blackHole = body as? BlackHole {
                    blackHole.updateDistortion()
                }

                if body.bodyState.zDepth <= 90,
                    let blackHole = body as? BlackHole
                {
                    let jetHitBoxes = blackHole.getJetHitBoxes()
                    for (hitBox, isTop) in jetHitBoxes {
                        let hitBoxWorldPosition = blackHole.convert(
                            hitBox.position,
                            to: self
                        )
                        let distanceToHitBox = spaceship.position.distance(
                            to: hitBoxWorldPosition
                        )
                        let collisionThreshold =
                            (spaceship.size.width / 2 + hitBox.size.width / 2)
                        if distanceToHitBox < collisionThreshold {
                            applyJetForce(blackHole, hitBox, isTop)
                        }
                    }
                }
            }
        }

        if isAnimatingOrbit {
            if let collidedBlackHole = animatingBlackHole {
                collidedBlackHole.bodyState.zDepth -=
                    collidedBlackHole.bodyState.zSpeed
                if collidedBlackHole.bodyState.zDepth <= 0 {
                    collidedBlackHole.isHidden = true
                    collidedBlackHole.removeFromParent()
                    activeBlackHoles.removeAll { $0 === collidedBlackHole }
                    inactiveZBodies.append(collidedBlackHole)
                }
            }
            return
        }

        for body in bodiesToReserve {
            if body.bodyState.isBeingTractored { continue }
            body.isHidden = true
            body.removeFromParent()
            body.bodyState.zSpeed = zSpeedAvg
            activeBlackHoles.removeAll { $0 === body }
            activeStars.removeAll { $0 === body }
            activeToppings.removeAll { $0 === body }
            inactiveZBodies.append(body)
        }
        //
        //        let count = bodiesToReset.count
        //
        //        if count > 0 {
        //            let maxXBody = activeStars.min { bodyA, bodyB in
        //                bodyA.bodyState.currentX.magnitude
        //                    > bodyB.bodyState.currentX.magnitude
        //            }
        //            let maxYBody = activeStars.min { bodyA, bodyB in
        //                bodyA.bodyState.currentY.magnitude
        //                    > bodyB.bodyState.currentY.magnitude
        //            }
        //            print(
        //                "reserving \(count) bodies with \(activeStars.count) active stars \(activeStars.count{s in s.isHidden}) hidden; minX at \(maxXBody?.bodyState.currentX ?? 99_999_999); minY at \(maxYBody?.bodyState.currentY ?? 99_999_999) (Spaceship X:\(spaceship.position.x) Y:\(spaceship.position.y)"
        //            )
        //        }
        //

        // Spawn new items
        if frameCount % spawnIntervalFrames == 0 && !isAnimatingOrbit {
            // Spawn celestials (black holes and stars)
            if activeBlackHoles.count + activeStars.count < maxCelestialBodies {
                let isBlackHole =
                    CGFloat.random(in: 0...1) < blackHoleProbability
                _ = spawnAndActivateZBody(
                    isBlackHole: isBlackHole,
                    isTopping: false,
                    xOffset: xScrollOffset,
                    yOffset: -yScrollOffset,
                    zNewSpeed: zSpeedAvg
                )
            }

            // Spawn toppings separately (using fraction of maxCelestialBodies for maxToppings; adjust fraction as needed)
            let maxToppings = Int(Double(maxCelestialBodies) / 4)
            if activeToppings.count < maxToppings {
                let toppingProb = tunnelMode ? 0.0 : toppingProbability
                let isSpawningTopping = CGFloat.random(in: 0...1) < toppingProb
                if isSpawningTopping {
                    _ = spawnAndActivateZBody(
                        isBlackHole: false,
                        isTopping: true,
                        xOffset: xScrollOffset,
                        yOffset: -yScrollOffset,
                        zNewSpeed: zSpeedAvg
                    )
                }
            }
        }

        spaceshipPosition = spaceship.position
        if !scoreboard.isHidden
            && currentTime - lastScoreTimestamp >= lastScoreDuration
        {
            scoreboard.isHidden = true
        }
    }

    private func spawnAndActivateZBody(
        isBlackHole: Bool,
        isTopping: Bool,
        xOffset: CGFloat,
        yOffset: CGFloat,
        zNewSpeed: CGFloat
    ) -> ZDepthBody {
        let newBody: ZDepthBody = {
            if isBlackHole {
                if let inactiveBody = inactiveZBodies.first(where: {
                    $0 is BlackHole
                }) as? BlackHole {
                    inactiveZBodies.removeAll { $0 === inactiveBody }
                    return inactiveBody
                } else {
                    return BlackHole()
                }
            } else if isTopping {
                if let inactiveBody = inactiveZBodies.first(where: {
                    $0 is Topping
                }) as? Topping {
                    inactiveZBodies.removeAll { $0 === inactiveBody }
                    return inactiveBody
                } else {
                    return Topping()
                }
            } else {
                if let inactiveBody = inactiveZBodies.first(where: {
                    $0 is Star
                }) as? Star {
                    inactiveZBodies.removeAll { $0 === inactiveBody }
                    return inactiveBody
                } else {
                    return Star()
                }
            }
        }()

        newBody.zPosition = -1
        if newBody.parent == nil {
            addChild(newBody)
        }

        switch newBody {
        case let bh as BlackHole:
            bh.updateJetAngle()
            bh.updateInTunnel(inTunnel: tunnelMode)
            activeBlackHoles.append(bh)
        case let t as Topping:
            activeToppings.append(t)
        case let s as Star:
            activeStars.append(s)
        default:
            // Optional: Handle unexpected subtype
            fatalError("Unexpected body type: \(type(of: newBody))")
        }

        newBody.reset(
            xOffset: tunnelMode ? 0.0 : xOffset * 2,
            yOffset: tunnelMode ? 0.0 : -yOffset * 4,
            zNewSpeed: zNewSpeed
        )
        return newBody
    }

    let firstTunnelProgram = [2.0, 2.0, 2.0, -2.0, -1.0]
    private func beginTunnel() {
        // First get inputs to the tunnel shader manager to be near 0.0
        // Then begin moving the ball around
        tunnelShaderManager.reset()
        backgroundSprite?.shader = tunnelShaderManager.getTunnelShader()
        let wait = SKAction.wait(forDuration: 2.0)
        backgroundSprite?.run(
            SKAction.sequence(
                firstTunnelProgram.flatMap { force in
                    [
                        wait,
                        SKAction.customAction(withDuration: 1.0) {
                            [self] node, time in
                            tunnelShaderManager.setScrollBackgroundX(
                                scroll: Float(force / 10) * Float(time)
                            )
                        },
                        SKAction.customAction(withDuration: 1.0) {
                            [self] node, time in xAcc += CGFloat(force * 5)
                        },
                        SKAction.customAction(withDuration: 1.0) {
                            [self] node, time in
                            tunnelShaderManager.setScrollBackgroundX(
                                scroll: Float(force / 10) * Float(1 - time)
                            )
                        },
                    ]
                }
            )
        )

    }

    private func beginFreeNav() {
        backgroundSprite?.shader = galaxyShaderManager.getGalaxyShader()
        backgroundSprite?.run(
            SKAction.customAction(withDuration: 2.0) { [self] node, time in
                galaxyShaderManager.addRotation(
                    angle: .pi * 2 * Float(time)
                )
            }
        )
    }

    private func startOrbitAnimation(for blackHole: BlackHole) {
        isAnimatingOrbit = true
        animatingBlackHole = blackHole
        let radius: CGFloat = size.width / 6.0
        let blackHoleOrbitPath = UIBezierPath(
            arcCenter: spaceship.position,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        let blackHoleOrbitAction = SKAction.follow(
            blackHoleOrbitPath.cgPath,
            asOffset: false,
            orientToPath: false,
            duration: 3.0
        )
        let starOrbitPath = UIBezierPath(
            arcCenter: spaceship.position,
            radius: radius * 3,
            startAngle: 0,
            endAngle: .pi,
            clockwise: true
        )
        let starOrbitAction = SKAction.follow(
            starOrbitPath.cgPath,
            asOffset: false,
            orientToPath: false,
            duration: 3.0
        )
        for body in activeBlackHoles {
            body.run(SKAction.repeat(blackHoleOrbitAction, count: 2))
        }
        for body in activeStars {
            body.run(starOrbitAction)
            //            body.changeFace(to: "silly_face")
        }
        backgroundSprite?.run(
            SKAction.customAction(withDuration: 3.0) { [self] node, time in
                galaxyShaderManager.addRotation(
                    angle: .pi * 2 * Float(time / 3)
                )
            }
        )
        applyEndForce(to: blackHole)
        let wait = SKAction.wait(forDuration: 3.0)
        let endAnimation = SKAction.run { [weak self] in
            self?.isAnimatingOrbit = false
            self?.activeBlackHoles.forEach {
                $0.isHidden = true
                $0.removeFromParent()
            }
            self?.activeStars.forEach {
                $0.isHidden = true
                $0.removeFromParent()
            }
            self?.inactiveZBodies.append(
                contentsOf: self?.activeBlackHoles ?? []
            )
            self?.inactiveZBodies.append(
                contentsOf: self?.activeStars ?? []
            )
            self?.activeBlackHoles.removeAll()
            self?.activeStars.removeAll()
            self?.zSpeedAvg = zSpeedUpperLimit
            self?.animatingBlackHole = nil
        }
        run(SKAction.sequence([wait, endAnimation]))
    }

    private func applyGravitationalForce(from body: ZDepthBody) {
        let direction = CGFloat(
            atan2(
                body.position.y - spaceship.position.y,
                body.position.x - spaceship.position.x
            )
        )
        let distance = body.position.distance(to: spaceship.position)
        let denominator = max(pow(distance, gravityFalloffPower), 1.0)
        let gravForceMagnitude =
            (gravitationalConstant * body.bodyState.mass) / denominator
        applyForceToSpaceship(
            forceAngle: direction,
            forceMagnitude: gravForceMagnitude
        )
    }

    private func applyJetForce(
        _ blackHole: BlackHole,
        _ hitBox: SKSpriteNode,
        _ isTop: Bool
    ) {
        let baseForce = maxJetForce * (1.0 - blackHole.bodyState.zDepth / 100.0)
        let hitBoxLocalSpaceshipPos = blackHole.convert(
            spaceship.position,
            from: self
        )
        let hitBoxLength = hitBox.size.height
        let baseY =
            isTop ? 30.0 / 2 : -30 / 2
        let tipY = isTop ? baseY + hitBoxLength : baseY - hitBoxLength
        let relativeY =
            isTop ? hitBoxLocalSpaceshipPos.y : -hitBoxLocalSpaceshipPos.y
        let t = max(0.0, min(1.0, (relativeY - baseY) / (tipY - baseY)))
        let forceScale = 1.0 - 0.75 * t
        let forceAngle = blackHole.zRotation + (isTop ? 0 : .pi) - .pi / 2
        print(
            "Applying Jet at Angle \(forceAngle) for rotation \(blackHole.zRotation)"
        )
        let forceMagnitude =
            (baseForce * forceScale * jetForceScale)
            / max(1.0, blackHole.bodyState.zDepth)
        applyForceToSpaceship(
            forceAngle: forceAngle,
            forceMagnitude: forceMagnitude
        )
    }

    private func applyEndForce(to blackHole: BlackHole) {
        let jetAngle = blackHole.zRotation
        let forceAngle = jetAngle + .pi / 2
        applyForceToSpaceship(
            forceAngle: forceAngle,
            forceMagnitude: blackHoleEjectionForceMagnitude
        )
    }

    private func applyForceToSpaceship(
        forceAngle: CGFloat,
        forceMagnitude: CGFloat
    ) {
        let forceI = cos(forceAngle) * forceMagnitude
        let forceJ = sin(forceAngle) * forceMagnitude
        xAcc += forceI / spaceshipMass
        yAcc += forceJ / spaceshipMass
    }

    func updateCrownDelta(_ delta: Double) {
        crownDelta = min(
            max(-Double(crownDeltaMax), delta),
            Double(crownDeltaMax)
        )
    }

    enum CompassPoint {
        case top
        case topRight
        case right
        case bottomRight
        case bottom
        case bottomLeft
        case left
        case topLeft

        func position(size: CGSize, centerX: CGFloat, centerY: CGFloat)
            -> CGPoint
        {
            switch self {
            case .top:
                return CGPoint(x: centerX, y: size.height)
            case .topRight:
                return CGPoint(x: size.width, y: size.height)
            case .right:
                return CGPoint(x: size.width, y: centerY)
            case .bottomRight:
                return CGPoint(x: size.width, y: 0)
            case .bottom:
                return CGPoint(x: centerX, y: 0)
            case .bottomLeft:
                return CGPoint(x: 0, y: 0)
            case .left:
                return CGPoint(x: 0, y: centerY)
            case .topLeft:
                return CGPoint(x: 0, y: size.height)
            }
        }

        var rotation: CGFloat {
            switch self {
            case .top, .bottom:
                return 0
            case .right:
                return .pi / 2
            case .left:
                return .pi / 2
            case .topRight:
                return .pi / 2
            case .bottomRight:
                return .pi / 2
            case .bottomLeft:
                return .pi / 2
            case .topLeft:
                return .pi / 2
            }
        }
    }
}
