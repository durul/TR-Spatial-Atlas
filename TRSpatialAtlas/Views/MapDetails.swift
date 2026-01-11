//
//  MapDetails.swift
//  TRSpatialAtlas
//
//  Created by durul dalkanat on 1/10/26.
//

import SwiftUI

/// VisionOS HIG: Minimum tap target size is 60pt for comfortable interaction
struct MapDetails: View {
    @State private var mapFlatOn = true // Start flat (default map state)

    let turnOnMapFlat: () -> Void
    let turnOffMapFlat: () -> Void

    var body: some View {
        VStack(spacing: 100) {
            // Title - Large and readable
            Text("🗺️ Map Controls")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Map Mode Toggle Button - HIG Compliant (60pt+ tap target)
            Button {
                mapFlatOn.toggle()
                if mapFlatOn {
                    turnOnMapFlat()
                } else {
                    turnOffMapFlat()
                }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: mapFlatOn ? "square.on.square.fill" : "rectangle.portrait.fill")
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Map Mode")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(mapFlatOn ? "Flat (Tabletop)" : "Vertical (Wall)")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Visual indicator
                    Image(systemName: mapFlatOn ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(mapFlatOn ? .green : .secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(minHeight: 100) // HIG: Minimum 60pt tap target
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .hoverEffect(.highlight) // VisionOS: Visual feedback on gaze
            .contentShape(Rectangle()) // Ensure entire area is tappable
        }
        .padding(50)
        .frame(minWidth: 200)
        .glassBackgroundEffect()
    }
}

#Preview {
    MapDetails(turnOnMapFlat: {}, turnOffMapFlat: {})
}
