//
//  ContentView.swift
//  Myeline
//
//  Created by Etienne Vautherin on 19/02/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("Start") {
                Task {
                    _ = try? await StartLocationUpdateIntent().perform()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Stop") {
                Task {
                    _ = try? await StopLocationUpdateIntent().perform()
                }
            }
            .buttonStyle(.bordered)

//            #if targetEnvironment(simulator)
//            Button("Background session") {
//                Task {
//                    await LiveActivityManager.shared.createAlwaysSession()
//                }
//            }
//            #endif
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
