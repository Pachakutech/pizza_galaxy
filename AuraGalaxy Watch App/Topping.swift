//
//  Topping.swift
//  AuraGalaxy
//
//  Created by Pachakutech on 11/7/25.
//

import SpriteKit

enum ToppingType: CaseIterable {
    case garlic
    case tomato
    case ham
    case onion
    case bacon
    case pepperoni
    case shroom
    case jalapeno
    case broccoli
}

extension ToppingType {
    var textureName: String {
        switch self {
        case .garlic: return "garlic"
        case .tomato: return "tomato"
        case .ham: return "mad_ham"
        case .onion: return "onion"
        case .bacon: return "bacon"
        case .pepperoni: return "pepperoni"
        case .shroom: return "shroom"
        case .jalapeno: return "jalapeno"
        case .broccoli: return "broccoli"
        }
    }

    private static let textureCache: [ToppingType: SKTexture] = {
        var cache = [ToppingType: SKTexture]()
        for topping in ToppingType.allCases {
            cache[topping] = SKTexture(imageNamed: topping.textureName)
        }
        return cache
    }()

    var texture: SKTexture {
        return Self.textureCache[self] ?? SKTexture(imageNamed: "yellow_star")
    }

    static func randomWeighted(weights: [ToppingType: Double]) -> ToppingType {
        let allCases = Self.allCases
        let totalWeight = weights.values.reduce(0, +)

        guard totalWeight > 0 else {
            // Fallback to uniform if no weights provided or all zero
            return allCases.randomElement() ?? .garlic  // Safe unwrap, assuming at least one case
        }

        let randomValue = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0

        for type in allCases {
            let weight = weights[type] ?? 0  // Default to 0 if not specified
            cumulative += weight
            if randomValue < cumulative {
                return type
            }
        }

        // Fallback in case of floating-point precision issues
        return allCases.last ?? .garlic
    }
}

@MainActor
class Topping: CelestialBody {
    var toppingType: ToppingType

    init() {
        toppingType = ToppingType.randomWeighted(weights: [
            .garlic: 0.1, .tomato: 0.4, .ham: 0.3, .broccoli: 0.2,
        ])  // Example; fetch from game state
        super.init(
            textureName: "yellow_star",
            size: CGSize(width: 30, height: 30),
            mass: 0.001
        )
        // Temporary debug border
        //        color = .red
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reset(xOffset: CGFloat, yOffset: CGFloat, zNewSpeed: CGFloat)
    {
        super.reset(xOffset: xOffset, yOffset: yOffset, zNewSpeed: zNewSpeed)
        toppingType = ToppingType.randomWeighted(weights: [
            .garlic: 0.1, .tomato: 0.1, .ham: 0.1, .broccoli: 0.2, .bacon: 0.1,
            .pepperoni: 0.1, .shroom: 0.1, .jalapeno: 0.1, .onion: 0.1,
        ])  // Example; fetch from game state
        changeFace(to: toppingType.textureName)
        // Reapply debug border
        //        color = .red
    }
}
