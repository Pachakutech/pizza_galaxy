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
    private(set) var celestialObjects: [CelestialObject] = []
    private var backgroundNodes: [SKSpriteNode] = []
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

        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        camera = cameraNode
        addChild(cameraNode)

        // Setup galaxy background
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

        spawnCelestialObjects()

        spaceship.physicsBody?.velocity = CGVector.zero
        print("Initial setup: spaceship position: \(spaceship.position), velocity: \(spaceship.physicsBody?.velocity ?? CGVector.zero), camera: \(cameraNode.position)")
    }

    private func spawnCelestialObjects() {
        celestialObjects.removeAll()
        let minSeparation: CGFloat = 10.0
        var attempts = 0

        // Spawn 2 black holes
        while celestialObjects.count < 2 && attempts < 100 {
            let blackHole = BlackHole()
            let initialX = spaceship.position.x + CGFloat.random(in: -12.0...12.0)
            let initialY = spaceship.position.y + verticalOffset
            blackHole.position = CGPoint(x: initialX, y: initialY)
            blackHole.initialX = initialX
            blackHole.zPosition = -1
            blackHole.setScale(0.05)
            blackHole.zDepth = 100
            blackHole.direction = 0

            let tooClose = celestialObjects.contains { other in
                other.position.distance(to: blackHole.position) < minSeparation
            }
            if !tooClose {
                celestialObjects.append(blackHole)
                addChild(blackHole)
                print("Spawned black hole at x: \(initialX), y: \(initialY)")
            }
            attempts += 1
        }

        // Spawn 12 stars
        attempts = 0
        while celestialObjects.count < 14 && attempts < 100 {
            let star = Star()
            let initialX = spaceship.position.x + CGFloat.random(in: -12.0...12.0)
            let initialY = spaceship.position.y + verticalOffset
            star.position = CGPoint(x: initialX, y: initialY)
            star.initialX = initialX
            star.zPosition = -1
            star.setScale(0.05)
            star.zDepth = 100
            star.direction = 0

            let tooClose = celestialObjects.contains { other in
                other.position.distance(to: star.position) < minSeparation
            }
            if !tooClose {
                celestialObjects.append(star)
                addChild(star)
                print("Spawned star at x: \(initialX), y: \(initialY), scale: \(star.xScale), zPosition: \(star.zPosition)")
            }
            attempts += 1
        }

        if celestialObjects.count < 14 {
            print("Warning: Only spawned \(celestialObjects.count) celestial objects after \(attempts) attempts")
        }
    }

    func handleTap(at location: CGPoint) {
        print("Tap at \(location), no zRotation change")
    }

    func updateCrownDelta(_ delta: Double) {
        crownDelta += delta
    }

    override func update(_ currentTime: TimeInterval) {
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
            verticalOffset -= CGFloat(crownDelta) * 15.0
            verticalOffset = min(max(verticalOffset, -size.height * 0.4), size.height * 0.4)
            crownDelta = 0
        } else if currentTime - lastCrownInputTime > 0.25 {
            spaceship.hideThrusters()
        }

        if isAnimatingOrbit {
            if let collidedBlackHole = animatingBlackHole {
                for object in celestialObjects {
                    if let blackHole = object as? BlackHole, blackHole === collidedBlackHole {
                        blackHole.zDepth -= blackHole.zSpeed
                        if blackHole.zDepth <= 0 {
                            print("Collided black hole at zDepth <= 0, position: \(blackHole.position)")
                            blackHole.reset(spaceshipX: spaceship.position.x, spaceshipY: spaceship.position.y, verticalOffset: verticalOffset, minSeparation: 10.0, otherObjects: celestialObjects)
                        }
                    }
                }
            }
            return
        }

        // Update background
        let backgroundWidth: CGFloat = 1024
        let backgroundHeight = size.height * 1.8
        let cameraX = spaceship.position.x
        let backgroundY = size.height / 2 - verticalOffset
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

        // Update celestial objects
        for object in celestialObjects {
            object.zDepth -= object.zSpeed
            if object.zDepth <= 0 {
                print("Celestial object (\(type(of: object))) at zDepth <= 0, position: \(object.position)")
                object.reset(spaceshipX: spaceship.position.x, spaceshipY: spaceship.position.y, verticalOffset: verticalOffset, minSeparation: 10.0, otherObjects: celestialObjects)
            } else {
                object.updatePositionAndScale(spaceshipY: spaceship.position.y, verticalOffset: verticalOffset)

                let distance = spaceship.position.distance(to: object.position)
                let collisionThreshold = (spaceship.size.width / 2 + object.size.width / 2)
                if distance < collisionThreshold && object.zDepth < 10 {
                    print("Collision with \(type(of: object)) at zDepth: \(object.zDepth), position: \(object.position)")
                    if object is BlackHole {
                        startOrbitAnimation(for: object as! BlackHole)
                    } else {
                        // TBI: Handle star collision (e.g., change texture or game state)
                        print("Star collision detected, TBI game state or texture change")
                        object.reset(spaceshipX: spaceship.position.x, spaceshipY: spaceship.position.y, verticalOffset: verticalOffset, minSeparation: 10.0, otherObjects: celestialObjects)
                    }
                }
            }
            // Apply gravitational forces only for black holes
            if let blackHole = object as? BlackHole, !isAnimatingOrbit {
                blackHole.applyGravitationalForce(to: spaceship)
            }
        }

        spaceshipPosition = spaceship.position
    }

    private func startOrbitAnimation(for blackHole: BlackHole) {
        isAnimatingOrbit = true
        animatingBlackHole = blackHole

        let radius: CGFloat = 20.0
        let orbitPath = UIBezierPath(arcCenter: spaceship.position, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let orbitAction = SKAction.follow(orbitPath.cgPath, asOffset: false, orientToPath: false, duration: 3.0)
        let repeatOrbit = SKAction.repeat(orbitAction, count: 2)

        for object in celestialObjects {
            if object !== blackHole {
                object.run(repeatOrbit)
                print("Started orbit animation for \(type(of: object)) at position: \(object.position), zDepth: \(object.zDepth)")
            } else {
                print("Collided black hole remains centered at position: \(object.position), zDepth: \(object.zDepth)")
            }
        }

        let wait = SKAction.wait(forDuration: 3.0)
        let endAnimation = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isAnimatingOrbit = false
            self.applyEndForce(to: blackHole)
            for object in self.celestialObjects {
                if object !== blackHole {
                    object.reset(spaceshipX: self.spaceship.position.x, spaceshipY: self.spaceship.position.y, verticalOffset: self.verticalOffset, minSeparation: 10.0, otherObjects: self.celestialObjects)
                }
            }
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
        if let physicsBody = spaceship.physicsBody {
            physicsBody.applyForce(CGVector(dx: forceX, dy: 0.0))
            print("Applied end force: angle \(forceAngle * 180 / .pi)°, isAbove: \(isAbove), force: (\(forceX), 0.0)")
        }
    }
}
