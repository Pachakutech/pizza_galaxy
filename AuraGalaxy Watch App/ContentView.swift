//
//  ContentView.swift
//  AuraGalaxy Watch App
//
//  Created by Pachakutech on 5/27/25.
//

import SwiftUI
import SpriteKit
import WatchKit

struct ContentView: View {
    @StateObject private var gameScene = GameScene(size: WKInterfaceDevice.current().screenBounds.size)
    @State private var gameWon = false
    @State private var crownValue: Double = 0.0

    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
                .onAppear {
                    print("SpriteView appeared, scene size: \(gameScene.size)")
                }
            if gameWon {
                Text("You Win!")
                    .font(.title)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    let location = value.location
                    print("Tap at: \(location)")
                    gameScene.handleTap(at: location)
                }
        )
        .digitalCrownRotation($crownValue)
        .onChange(of: crownValue) { newValue, oldValue in
            let delta = newValue - oldValue
            gameScene.spaceship.adjustVerticalPosition(delta: delta, sceneSize: gameScene.size)
        }
        .onChange(of: gameScene.spaceshipPosition) { newPosition, _ in
            for blackHole in gameScene.blackHoles {
                if blackHole.zDepth < 10 && newPosition.distance(to: blackHole.position) < 30 {
                    gameWon = true
                    print("Win condition met")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
