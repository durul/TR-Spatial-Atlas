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
            Text("🇹🇷 Türkiye Haritası")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Text("Türkiye'nin il sınırlarının 3D görselleştirmesi")
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
