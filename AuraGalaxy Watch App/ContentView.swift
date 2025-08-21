//
//  ContentView.swift
//  AuraGalaxy Watch App
//
//  Created by Pachakutech on 5/27/25.
//

import SwiftUI
import SpriteKit
import WatchKit
import Combine

struct ContentView: View {
    @StateObject private var gameScene = GameScene(size: WKInterfaceDevice.current().screenBounds.size)
    @State private var gameWon = false
    @State private var crownValue: Double = 0.0

    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
                .onAppear {
                    print("ContentView appeared, scene size: \(gameScene.size)")
                }
            if gameWon {
                Text("You Win!")
                    .font(.title)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
            }
        }
        .focusable(true) // Ensure view can receive crown input
        .digitalCrownRotation(
            $crownValue,
            from: -100.0,
            through: 100.0,
            sensitivity: .low,
            isContinuous: true
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    let location = value.location
                    print("Tap gesture ended at: \(location)")
                    gameScene.handleTap(at: location)
                }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    let deltaY = -value.translation.height / 1000.0
                    crownValue += deltaY
                    print("Drag gesture deltaY: \(deltaY), crownValue: \(crownValue)")
                }
        )
        .onChange(of: crownValue) { newValue, oldValue in
            let delta = newValue - oldValue
            print("Crown onChange triggered: newValue=\(newValue), oldValue=\(oldValue), delta=\(delta)")
            gameScene.updateCrownDelta(delta)
        }
        .onAppear {
            print("ContentView onAppear: Initial crownValue=\(crownValue)")
        }
        .onDisappear {
            print("ContentView disappeared")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
