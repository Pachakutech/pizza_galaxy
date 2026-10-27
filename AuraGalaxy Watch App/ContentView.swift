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
        GeometryReader {
            geo in ZStack {
                SpriteView(scene: gameScene)
                    .frame(width: geo.size.width, height: geo.size.height)
                if gameWon {
                    Text("You Win!")
                        .font(.title)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture( DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded {
                    v in let sx = gameScene.size.width / geo.size.width
                    let sy = gameScene.size.height / geo.size.height
                    gameScene.handleTap(at: CGPoint( x: v.location.x * sx, y: (geo.size.height - v.location.y) * sy))
                }
            )
        }
        .ignoresSafeArea() // outermost, on the GeometryReader
        .focusable(true)
        .digitalCrownRotation($crownValue, from: -100.0, through: 100.0, sensitivity: .medium, isContinuous: true)
        .onChange(of: crownValue) {
            oldValue, newValue in gameScene.updateCrownDelta(newValue - oldValue)
        }
    }
}
