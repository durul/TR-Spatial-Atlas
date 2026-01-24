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

    var body: some View {
        VStack(spacing: 20) {
            header

            Text("3D visualization of Türkiye's provincial borders")
                .font(.title3) // subheadline yerine biraz daha rahat
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 12)

            Group {
                if viewModel.isLoading {
                    loadingBlock
                } else {
                    actions
                }
            }
            .frame(maxWidth: 520)
        }
        .padding(24)
    }

    // MARK: - Sections

    private var header: some View {
        GeometryReader { proxy in
            Text("🇹🇷 Türkiye Map")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .modifier(
                    RippleEffect(
                        origin: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2),
                        trigger: counter
                    )
                )
        }
        .frame(height: 120)
        .padding(.horizontal, 12)
        .accessibilityAddTraits(.isHeader)
    }

    private var loadingBlock: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)

            Text(viewModel.loadingProgress)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassBackgroundEffect()
    }

    private var actions: some View {
        VStack(spacing: 14) {
            ToggleImmersiveSpaceButton(onTriggerRipple: triggerRipple)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func triggerRipple() {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            counter += 1
        }
    }
}
