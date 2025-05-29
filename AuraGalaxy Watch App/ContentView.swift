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
    @State private var crownValue: Double = 0.0 // Tracks crown rotation

    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            if gameWon {
                Text("You Win!")
                    .font(.title)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    let tapLocation = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2)
                    gameScene.handleTap(at: tapLocation)
                }
        )
        .digitalCrownRotation($crownValue)
        .onChange(of: crownValue) { newValue, oldValue in
            let delta = newValue - oldValue
            gameScene.spaceship.adjustRudder(delta: delta * 0.1)
        }
        .onChange(of: gameScene.spaceshipPosition) { newPosition, _ in
            let center = CGPoint(x: gameScene.size.width / 2, y: gameScene.size.height / 2)
            if newPosition.distance(to: center) < 20 {
                gameWon = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
