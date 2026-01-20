//
//  ContentView.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import RealityKit
import SwiftUI

struct ContentView: View {
    @Environment(TrSpatialAtlasViewModel.self) private var viewModel

    @State private var counter = 0
    @State private var touch: CGPoint = .zero

    var body: some View {
        VStack {
            GeometryReader { proxy in
                Text("🇹🇷 Türkiye Map")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(RippleEffect(origin: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2), trigger: counter))
            }
            .frame(height: 60)
            .padding()

            Text("3D visualization of Türkiye's provincial borders")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)

                    Text(viewModel.loadingProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            } else {
                ToggleImmersiveSpaceButton(onTriggerRipple: {
                    Task {
                        try? await Task.sleep(for: .milliseconds(300))

                        counter += 1
                    }
                })
            }
        }
        .padding()
    }
}
