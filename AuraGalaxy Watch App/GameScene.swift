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

let maxSpaceshipSpeedX: CGFloat = 200.0
let zSpeedDefault: CGFloat = 60.0 / 100.0
let zSpeedUpperLimit = zSpeedDefault * 15.0
let zSpeedLowerLimit = zSpeedDefault / 10.0
let bgScrollSpeed: CGFloat = 30.0
let celestialScrollSpeedFactor: CGFloat = 1.0 / 60.0
let maxJetForce: CGFloat = 2000.0
let xDamping: CGFloat = 0.95
let blackHoleEjectionForceMagnitude: CGFloat = 800.0
let zConversionFactor: CGFloat = 1000.0
let gravitationalConstant: CGFloat = 0.1
let verticalOffsetSigma: CGFloat = 0.4
let verticalOffsetDefault: CGFloat = 25.0
let bowDepth: CGFloat = 20.0
let crownDeltaMax: CGFloat = 5.0
let backgroundWidth: CGFloat = 1024
let backgroundHeight: CGFloat = 768

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
    private var yOffset: CGFloat = verticalOffsetDefault
    private var ySpeed: CGFloat = 0.0
    private var yAcc: CGFloat = 0.0
    private var yBackgroundOffset: CGFloat = 0.0
    private var isAnimatingOrbit: Bool = false
    private var animatingBlackHole: BlackHole?
    private var frameCount: Int = 0
    private var spawnIntervalFrames = 15
    private var zSpeedDelta: CGFloat = 0.0
    private var zSpeedAvg: CGFloat = zSpeedDefault
    private var xApparentVelocity: CGFloat = 0.0
    private var xAccDelta: CGFloat = 0.0
    private var collisionSoundAction: SKAction?
    private var backgroundSprite: SKSpriteNode?
    private var rainbowEffect: SKEmitterNode?
    private var currentLevel = 1
    private let maxCelestialBodies = 34
    private let blackHoleProbability = 0.2
    private var yMaxOffset: CGFloat { backgroundHeight - 2.2 * size.height }
    private var centerX: CGFloat { size.width / 2 }
    private var centerY: CGFloat { size.height / 2 }
    private let tunnelShaderManager = TunnelShaderManager()
    private let galaxyShaderManager = GalaxyShaderManager()
    private var tunnelMode = true
    private var timeOnGalaxy = 0

    override init(size: CGSize) {
        super.init(size: size)
        setupAudioSession()
        setupScene()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAudioSession()
        setupScene()
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

        for _ in 0..<maxCelestialBodies {
            let isBlackHole = CGFloat.random(in: 0...1) < blackHoleProbability
            let body: CelestialBody = isBlackHole ? BlackHole() : Star()
            body.zPosition = -1
            body.isHidden = true
            inactiveCelestialBodies.append(body)
        }
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
        frameCount += 1

        let zAccBase = zSpeedDelta
        zSpeedDelta = 0.0
        zSpeedAvg = (7 * zSpeedAvg + zSpeedDefault) / 8

        let xDelta = spaceship.position.x - centerX
        xApparentVelocity =
            xApparentVelocity * xDamping + xAccDelta + xDelta / 4
        xApparentVelocity = min(
            max(-maxSpaceshipSpeedX, xApparentVelocity),
            maxSpaceshipSpeedX
        )
        xAccDelta *= 0.6
        let newX = min(
            max(size.width * 0.1, spaceship.position.x + CGFloat(crownDelta)),
            size.width * 0.9
        )
        let a = bowDepth / pow(size.width * 0.4, 2)
        let h = centerX
        let baseline = centerY - 70
        let parabola: CGFloat = a * pow(newX - h, 2)
        let newY = parabola + baseline
        spaceship.position = CGPoint(x: newX, y: newY)
        spaceship.zRotation = CGFloat(xDelta / 128)
        spaceshipPosition = spaceship.position
        let xCelestialOffset = -xApparentVelocity * celestialScrollSpeedFactor
        crownDelta = 0

        ySpeed += yAcc
        yAcc = 0.0
        yOffset += ySpeed
        ySpeed = ySpeed * 1 / 9
        yOffset -= parabola / 8 - 0.8
        yOffset = min(max(-centerY, yOffset), centerY)

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

        let yScrollOffset = min(max(-yMaxOffset, yOffset), yMaxOffset)
        let xScrollOffset = xApparentVelocity / bgScrollSpeed
        galaxyShaderManager.addScrollH(scroll: Float(-xScrollOffset / 1000))
        galaxyShaderManager.addScrollV(scroll: Float(yScrollOffset / 10000))
        tunnelShaderManager.addScrollX(scroll: Float(xScrollOffset / 1000))
        tunnelShaderManager.addScrollZ(scroll: Float(zSpeedAvg / 100))
        tunnelShaderManager.addScrollRotate(scroll: Float(xDelta / 1000))
        if tunnelShaderManager.isOutOfBounds() && tunnelMode {
            tunnelMode = false
            backgroundSprite?.shader = galaxyShaderManager.getGalaxyShader()
            backgroundSprite?.run(
                SKAction.customAction(withDuration: 2.0) { [self] node, time in
                    galaxyShaderManager.addRotation(
                        angle: .pi * 2 * Float(time)
                    )
                }
            )
        }

        let offsets = galaxyShaderManager.currentGalaxyOffsets()
        var isGalaxyVisible = false
        var closestOffset: (Float, Float)? = nil
        var minDistance: Float = .greatestFiniteMagnitude

        for (offsetH, offsetV) in offsets {
            if abs(offsetH) <= 0.5 && abs(offsetV) <= 0.5 {
                isGalaxyVisible = true
                break
            }
            let distance = sqrt(offsetH * offsetH + offsetV * offsetV)
            if distance < minDistance {
                minDistance = distance
                closestOffset = (offsetH, offsetV)
            }
        }

        if let rainbow = rainbowEffect {
            if isGalaxyVisible {
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
            timeOnGalaxy += 1
        } else {
            timeOnGalaxy = 0
        }
        if timeOnGalaxy > 60 && !tunnelMode{
            tunnelMode = !tunnelMode
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

        var bodiesToReset: [CelestialBody] = []
        for body in activeBlackHoles + activeStars {
            body.zDepth -= body.zSpeed
            if body.zDepth <= 0 {
                bodiesToReset.append(body)
            } else {
                body.updatePositionAndScale(
                    centerX: centerX,
                    centerY: centerY,
                    verticalOffset: 0,
                    xOffset: xCelestialOffset
                )
                let distance = spaceship.position.distance(to: body.position)
                body.zSpeed = max(
                    zSpeedLowerLimit,
                    min(zSpeedUpperLimit, body.zSpeed + zAccBase)
                )
                zSpeedAvg +=
                    (body.zSpeed - zSpeedAvg) / CGFloat(activeStars.count + 1)

                if body.zDepth <= 50 {
                    let collisionThreshold =
                        (spaceship.size.width / 2 + body.size.width / 2)
                    if distance < collisionThreshold && !body.hit {
                        if body is BlackHole {
                            ySpeed = 0.0
                            xApparentVelocity = 0.0
                            startOrbitAnimation(for: body as! BlackHole)
                        } else {
                            body.changeFace(to: "lovey_face")
                            zSpeedDelta += zSpeedDefault * 3 / 4
                            if let soundAction = collisionSoundAction {
                                run(soundAction)
                            }
                        }
                        body.hit = true
                    }
                    applyGravitationalForce(from: body)
                }

                if body.zDepth <= 90, let blackHole = body as? BlackHole {
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
                            applyJetForce(blackHole, body, hitBox, isTop)
                        }
                    }
                }
            }
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

        for body in bodiesToReset {
            body.isHidden = true
            body.removeFromParent()
            body.zSpeed = zSpeedAvg
            activeBlackHoles.removeAll { $0 === body }
            activeStars.removeAll { $0 === body }
            inactiveCelestialBodies.append(body)
        }

        if frameCount % spawnIntervalFrames == 0
            && (activeBlackHoles.count + activeStars.count) < maxCelestialBodies
            && !isAnimatingOrbit
        {
            let isBlackHole = CGFloat.random(in: 0...1) < blackHoleProbability
            let newBody: CelestialBody
            if isBlackHole,
                let inactiveBody = inactiveCelestialBodies.first(where: {
                    $0 is BlackHole
                })
            {
                newBody = inactiveBody
                inactiveCelestialBodies.removeAll { $0 === inactiveBody }
            } else if !isBlackHole,
                let inactiveBody = inactiveCelestialBodies.first(where: {
                    $0 is Star
                })
            {
                newBody = inactiveBody
                inactiveCelestialBodies.removeAll { $0 === inactiveBody }
            } else {
                newBody = isBlackHole ? BlackHole() : Star()
            }
            newBody.reset(
                xOffset: xApparentVelocity / 2,
                yOffset: -yOffset / 2,
                zNewSpeed: zSpeedAvg
            )
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
        }

        spaceshipPosition = spaceship.position
    }
    
    private func beginTunnel() {
        // First get inputs to the tunnel shader manager to be near 0.0
        // Then begin moving the ball around
        backgroundSprite?.shader = tunnelShaderManager.getTunnelShader()
        
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
            body.changeFace(to: "silly_face")
        }
        backgroundSprite?.run(
            SKAction.customAction(withDuration: 3.0) { [self] node, time in
                galaxyShaderManager.addRotation(angle: .pi * 2 * Float(time))
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
            self?.inactiveCelestialBodies.append(
                contentsOf: self?.activeBlackHoles ?? []
            )
            self?.inactiveCelestialBodies.append(
                contentsOf: self?.activeStars ?? []
            )
            self?.activeBlackHoles.removeAll()
            self?.activeStars.removeAll()
            self?.zSpeedAvg = zSpeedUpperLimit
            self?.animatingBlackHole = nil
        }
        run(SKAction.sequence([wait, endAnimation]))
    }

    private func applyGravitationalForce(from body: CelestialBody) {
        let direction = CGFloat(
            atan2(
                body.position.y - spaceship.position.y,
                body.position.x - spaceship.position.x
            )
        )
        let distance = body.position.distance(to: spaceship.position)
        let denominator = max(distance * distance, 1.0)
        let gravForceMagnitude =
            (gravitationalConstant * body.mass) / denominator
        ySpeed = ySpeed * 3 / 4
        applyForceToSpaceship(
            forceAngle: direction,
            forceMagnitude: gravForceMagnitude
        )
    }

    private func applyJetForce(
        _ blackHole: BlackHole,
        _ body: CelestialBody,
        _ hitBox: SKSpriteNode,
        _ isTop: Bool
    ) {
        let baseForce = maxJetForce * (1.0 - body.zDepth / 100.0)
        let hitBoxLocalSpaceshipPos = blackHole.convert(
            spaceship.position,
            from: self
        )
        let hitBoxLength = hitBox.size.height
        let baseY =
            isTop ? blackHole.size.height / 2 : -blackHole.size.height / 2
        let tipY = isTop ? baseY + hitBoxLength : baseY - hitBoxLength
        let relativeY =
            isTop ? hitBoxLocalSpaceshipPos.y : -hitBoxLocalSpaceshipPos.y
        let t = max(0.0, min(1.0, (relativeY - baseY) / (tipY - baseY)))
        let forceScale = 1.0 - 0.75 * t
        let forceAngle = blackHole.zRotation + (isTop ? 0 : .pi) - .pi / 2
        let forceMagnitude =
            (baseForce * forceScale * 5.25) / max(1.0, body.zDepth)
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
        xAccDelta += forceI * 0.7
        yAcc += forceJ * 0.7
    }

    func handleTap(at location: CGPoint) {
        print("Tap at \(location), no action defined")
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
