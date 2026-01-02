//
//  ImmersiveView.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct ImmersiveView: View {
    @Environment(TrSpatialAtlasViewModel.self) var viewModel
    
    @State private var arkitSession = ARKitSession()
    @State private var worldTracking = WorldTrackingProvider()

    var body: some View {
        RealityView { content in
            let entity = viewModel.setupContentEntity()
            content.add(entity)
            viewModel.makePolygon()
            
            // Position the map in front of the user when the view appears
            Task {
                await positionMapInFrontOfUser(entity: entity)
            }
        }
        .task {
            // Start ARKit session for head tracking
            do {
                try await arkitSession.run([worldTracking])
            } catch {
                print("Failed to start ARKit session: \(error)")
            }
        }
    }
    
    /// Positions the content entity directly in front of the user's current head position
    /// NOTE: Rotation is handled by ViewModel - this only sets position
    private func positionMapInFrontOfUser(entity: Entity) async {
        // Wait a moment for tracking to stabilize
        try? await Task.sleep(for: .milliseconds(200))
        
        // Default position (used as fallback for simulator)
        let defaultPosition = SIMD3<Float>(0, 1.2, -2.5)
        
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            print("Could not get device anchor, using default position")
            await MainActor.run {
                entity.position = defaultPosition
            }
            return
        }
        
        // Get the device (head) transform
        let headTransform = deviceAnchor.originFromAnchorTransform
        
        // Extract head position
        let headPosition = SIMD3<Float>(
            headTransform.columns.3.x,
            headTransform.columns.3.y,
            headTransform.columns.3.z
        )
        
        // Validate head position (simulator often returns weird values)
        let isValidHeadPosition = headPosition.y > 0.5 && headPosition.y < 3.0
        
        if !isValidHeadPosition {
            print("Invalid head position detected (\(headPosition)), using default position")
            await MainActor.run {
                entity.position = defaultPosition
            }
            return
        }
        
        // Forward direction (negative Z in the head's local space, horizontal only)
        let headForward = SIMD3<Float>(
            -headTransform.columns.2.x,
            0,
            -headTransform.columns.2.z
        )
        let normalizedForward = normalize(headForward)
        
        // Place the map 2.5 meters in front of the user
        let distance: Float = 2.5
        let mapPosition = headPosition + normalizedForward * distance
        
        await MainActor.run {
            // Set position only - rotation is already set by ViewModel
            entity.position = SIMD3<Float>(mapPosition.x, headPosition.y - 0.3, mapPosition.z)
        }
        
        print("📍 Map positioned in front of user at: \(mapPosition)")
    }
}
