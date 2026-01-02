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
    
    // For gestures
    @State private var initialPosition: SIMD3<Float> = .zero
    @State private var baseScale: SIMD3<Float> = [1.5, 0.5, 1.5]
    @State private var baseRotation: simd_quatf = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))

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
        .gesture(dragGesture)
        .gesture(magnifyGesture)
        .gesture(rotateGesture)
        .task {
            // Start ARKit session for head tracking
            do {
                try await arkitSession.run([worldTracking])
            } catch {
                print("Failed to start ARKit session: \(error)")
            }
        }
    }
    
    // MARK: - DragGesture (Move the map)
    
    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                // Convert translation from SwiftUI to RealityKit coordinates
                let translation3D = value.convert(value.translation3D, from: .local, to: .scene)
                
                // Get the entity being dragged (should be our contentEntity or its parent)
                let entity = value.entity
                
                // If this is the start of the drag, save initial position
                if initialPosition == .zero {
                    initialPosition = entity.position(relativeTo: nil)
                }
                
                // Apply translation to initial position
                let newPosition = initialPosition + SIMD3<Float>(
                    Float(translation3D.x),
                    Float(translation3D.y),
                    Float(translation3D.z)
                )
                
                entity.setPosition(newPosition, relativeTo: nil)
            }
            .onEnded { _ in
                // Reset initial position for next drag
                initialPosition = .zero
            }
    }
    
    // MARK: - MagnifyGesture (Pinch-to-Zoom)
    
    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                let magnification = Float(value.magnification)
                let newScale = baseScale * magnification
                
                // Clamp scale between 0.3x and 5x
                let clampedScale = SIMD3<Float>(
                    min(max(newScale.x, 0.3), 5.0),
                    min(max(newScale.y, 0.1), 2.0),
                    min(max(newScale.z, 0.3), 5.0)
                )
                
                value.entity.scale = clampedScale
            }
            .onEnded { value in
                // Save the final scale as the new base
                baseScale = value.entity.scale
            }
    }
    
    // MARK: - RotateGesture3D (Rotate the map)
    
    private var rotateGesture: some Gesture {
        RotateGesture3D()
            .targetedToAnyEntity()
            .onChanged { value in
                // Get the rotation from the gesture
                let rotation = simd_quatf(value.rotation)
                
                // Combine with base rotation
                value.entity.transform.rotation = rotation * baseRotation
            }
            .onEnded { value in
                // Save the final rotation as the new base
                baseRotation = value.entity.transform.rotation
            }
    }
    
    /// Positions the content entity directly in front of the user's current head position
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
            entity.position = SIMD3<Float>(mapPosition.x, headPosition.y - 0.3, mapPosition.z)
        }
        
        print("📍 Map positioned in front of user at: \(mapPosition)")
    }
}
