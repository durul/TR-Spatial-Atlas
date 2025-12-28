//
//  ContentView.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import RealityKit
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TrSpatialAtlasViewModel.self) private var viewModel

    var body: some View {
        VStack {
            Text("🇹🇷 Türkiye Map")
                .font(.title)
                .fontWeight(.bold)
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
                ToggleImmersiveSpaceButton()
            }
        }
        .padding()
    }
}
