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

struct ImmersiveMapView: View {
    @Environment(TrSpatialAtlasViewModel.self) var viewModel
    
    // MARK: - ARKit Session

    @State private var arkitSession = ARKitSession()
    
    // The device provides 6DoF (position + orientation) tracking.
    @State private var worldTracking = WorldTrackingProvider()
    
    // MARK: - Gesture Control

    /// Gesture control view model - handles all drag, scale, and rotation gestures
    @State private var gestureVM = GestureControlViewModel()

    var body: some View {
        RealityView { content in
            
            // 3D scene setup, position, rotation
            let entity = viewModel.setupContentEntity()
            content.add(entity)
            
            // Initiating GeoJSON loading.
            viewModel.makePolygon()
            
            // Position the map in front of the user when the view appears
            Task {
                await positionMapInFrontOfUser(entity: entity)
            }
        }

        // MARK: - Gestures

        // DragGesture for translation, MagnifyGesture + RotateGesture3D for scale and rotation
        .gesture(gestureVM.createTranslationGesture())
        .gesture(gestureVM.createScaleGesture())
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
    private func positionMapInFrontOfUser(entity: Entity) async {
        // Wait a moment for tracking to stabilize
        try? await Task.sleep(for: .milliseconds(200))
        
        // Default position (used as fallback for simulator)
        // 2.5m in front of the user (negative z), 1.2m in height.
        let defaultPosition = SIMD3<Float>(0, 1.2, -2.5)
        
        // deviceAnchor provides the position and orientation (pose) of the Vision Pro in 3D space.
        // It is used to understand where the user is looking.
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
        // I get the translation (x, y, z) from the 4th column of the 4x4 matrix.
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
        
        /*
         • Forward direction (negative Z in the head's local space, horizontal only)
         • Matrix's columns.2 is generally the "forward/back" axis (z-axis).
         • You take its negative and use it as the "viewing direction".
         */
        let headForward = SIMD3<Float>(
            -headTransform.columns.2.x,
            0,
            -headTransform.columns.2.z
        )
        
        // I'm setting Y to 0 to make the direction horizontal (so the map stays parallel to the ground, even if the head is looking up or down).
        let normalizedForward = normalize(headForward)
        
        // Place the map 2.5 meters in front of the user's head
        let distance: Float = 2.5
        let mapPosition = headPosition + normalizedForward * distance
        
        await MainActor.run {
            entity.position = SIMD3<Float>(mapPosition.x, headPosition.y - 0.3, mapPosition.z)
        }
        
        print("📍 Map positioned in front of user at: \(mapPosition)")
    }
}
