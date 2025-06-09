//
//  Spaceship.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 5/27/25.
//

import SpriteKit

@MainActor
class Spaceship: SKSpriteNode {
    private var sailAngle: CGFloat = 0.5
    private var topThruster: SKEmitterNode?
    private var bottomThruster: SKEmitterNode?
    private let thrustStrength: CGFloat = 150.0
    
    init() {
        let texture = SKTexture(imageNamed: "spaceship_placeholder")
        guard texture.size() != .zero else {
            fatalError("Error: Spaceship texture 'spaceship_placeholder' is missing or invalid")
        }
        super.init(texture: texture, color: .clear, size: CGSize(width: 30, height: 30))
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.mass = 1.0
        physicsBody?.friction = 0.0
        physicsBody?.linearDamping = 0.8
        physicsBody?.categoryBitMask = 1
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 2
        
        if let topEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            topEmitter.particleBirthRate = 10
            topEmitter.position = CGPoint(x: 0, y: size.height / 2)
            topEmitter.zRotation = 0
            topEmitter.zPosition = 1
            topEmitter.isHidden = true
            addChild(topEmitter)
            topThruster = topEmitter
        } else {
            print("Error: Failed to load top thruster JetEffect.sks")
        }
        
        if let bottomEmitter = SKEmitterNode(fileNamed: "JetEffect") {
            bottomEmitter.particleBirthRate = 10
            bottomEmitter.position = CGPoint(x: 0, y: -size.height / 2)
            bottomEmitter.zRotation = .pi
            bottomEmitter.zPosition = 1
            bottomEmitter.isHidden = true
            addChild(bottomEmitter)
            bottomThruster = bottomEmitter
        } else {
            print("Error: Failed to load bottom thruster JetEffect.sks")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustSailRudder(touchLocation: CGPoint, sceneSize: CGSize) {
        sailAngle = touchLocation.y / sceneSize.height
        zRotation = .pi / 2 + sailAngle * .pi
    }
    
    func applyThrust(crownDelta: Double) {
        let maxForcePerFrame: CGFloat = 50.0
        let rawForce = -CGFloat(crownDelta) * thrustStrength
        let thrustForce = min(max(rawForce, -maxForcePerFrame), maxForcePerFrame)
        physicsBody?.applyForce(CGVector(dx: 0, dy: thrustForce))
        
        topThruster?.isHidden = thrustForce <= 0
        bottomThruster?.isHidden = thrustForce >= 0
    }
    
    func hideThrusters() {
        topThruster?.isHidden = true
        bottomThruster?.isHidden = true
    }
    
    func applyGravitationalForce(from blackHole: BlackHole, direction: CGVector, jetAngle: CGFloat) {
        let distance = position.distance(to: blackHole.position)
        let gravitationalConstant: CGFloat = 50000
        let denominator = distance * distance < 1.0 ? 1.0 : distance * distance
        let gravForceMagnitude = gravitationalConstant / denominator
        let gravForce = CGVector(dx: -direction.dx * gravForceMagnitude / distance, dy: -direction.dy * gravForceMagnitude / distance)
        
        physicsBody?.applyForce(gravForce)
        
        if distance < blackHole.jetRange {
            let verticalComponent = cos(jetAngle)
            let horizontalComponent = sin(jetAngle)
            let jetForceMagnitude = blackHole.jetStrength * sailAngle * blackHole.xScale * blackHole.direction
            let jetForceX = jetForceMagnitude * horizontalComponent
            let jetForce = CGVector(dx: jetForceX, dy: 0)
            physicsBody?.applyForce(jetForce)
            
            let zAcceleration = verticalComponent * blackHole.jetStrength / 500.0
            blackHole.zSpeed = (100.0 / 180.0) + zAcceleration * 0.1
        } else {
            blackHole.zSpeed = 100.0 / 180.0
        }
    }
}
