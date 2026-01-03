//
//  GestureControlViewModel.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 1/12/25.
//

import Foundation
import RealityKit
import SwiftUI

/// GestureControlViewModel that manages all gesture-based manual control functionality
///
/// This ViewModel handles:
/// - Translation (drag) gestures for positioning entities
/// - Scale (magnify) gestures for resizing entities
/// - 3D rotation gestures for entity
/// - State management for gesture tracking
///
@MainActor
@Observable
class GestureControlViewModel {
    // MARK: - Properties
    
    // MARK: - Gesture State
    
    /// Stores the initial position of an entity when a drag gesture begins
    var initialPosition: SIMD3<Float>?
    
    /// Stores the initial scale of an entity when a magnify gesture begins
    var initialScale: SIMD3<Float>?
    
    /// Stores the accumulated 3D rotation for MAP from RotateGesture3D
    /// Initialized with -90° X rotation to keep map flat
    var mapRotation3D: Rotation3D = Rotation3D(angle: .degrees(-90), axis: .x)
    
    /// Stores the current gesture rotation during RotateGesture3D
    var mapGestureRotation: Rotation3D = .identity
    
    // MARK: - Gesture Handlers
    
    /// Resets the Map rotation state to identity
    /// This should be called when exiting manual control mode
    func resetMapRotation() {
        mapRotation3D = .identity
        mapGestureRotation = .identity
        print("🔄 MAP rotation state reset")
    }
    
    // MARK: - Gesture Definitions
    
    // TODO: The immersion sensation can be enhanced by adding a small vibration via RealityKit or CoreHaptics.
    /// Creates a translation (drag) gesture for moving entities in 3D space
    /// - Returns: A DragGesture that only processes when Manual Control Mode is enabled
    ///
    /// This gesture allows users to move Earth and MAP entities freely in 3D space.
    /// The gesture is always applied but only processes input when Manual Control Mode is enabled.
    func createTranslationGesture() -> some Gesture {
        DragGesture()
            .targetedToAnyEntity() // Ensures the gesture only targets entities with an InputTargetComponent
            .onChanged { value in // value parameter contains information about the drag, such as location, direction, and target Entity.

                /// The entity that the drag gesture targets (for example an “EarthEntity”) comes with this entity parameter.
                let rootEntity = value.entity
                
                // MARK: 🏁 Starting position recording

                // Set `initialPosition` to the position of the entity if it is `nil`
                // In this way, motion vectors are calculated according to this starting point.
                if self.initialPosition == nil {
                    self.initialPosition = rootEntity.position
                    print("🎮 MANUAL MODE: Drag started on \(rootEntity.name)")
                }

                // Convert gesture translation from global to scene coordinate space
                // No inversion needed - works correctly in both volumetric and immersive modes
                let movement = value.convert(value.translation3D, from: .global, to: .scene)
                
                rootEntity.position = (self.initialPosition ?? .zero) + SIMD3<Float>(movement)
            }
            .onEnded { value in

                let rootEntity = value.entity
                print("🎮 MANUAL MODE: Drag ended on \(rootEntity.name) - Final position: \(rootEntity.position)")
                
                // Reset the `initialPosition` back to `nil` when the gesture ends
                self.initialPosition = nil
            }
    }
    
    /// Creates a scale (magnify) gesture combined with 3D rotation for entities
    /// - Returns: A MagnifyGesture combined with RotateGesture3D for simultaneous scaling and rotation
    ///
    /// This gesture allows users to:
    /// - Scale any entity with two-handed pinch gestures
    /// - Rotate the Map entity in 3D space simultaneously
    ///
    /// The gesture is always applied but only processes input when Manual Control Mode is enabled.
    func createScaleGesture() -> some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity() // Ensures the gesture only targets entities with an InputTargetComponent
            .onChanged { value in

                /// The entity that the magnify gesture targets
                let rootEntity = value.entity
                
                // Set the `initialScale` to the scale of the entity if it is `nil`
                if self.initialScale == nil {
                    self.initialScale = rootEntity.scale
                    print("🎮 MANUAL MODE: Scale started on \(rootEntity.name)")
                }
                
                /// The rate that the model will scale by
                let scaleRate: Float = 1.0
                
                // Scale the entity up smoothly by the relative magnification on the gesture
                rootEntity.scale = (self.initialScale ?? .init(repeating: scaleRate)) * Float(value.gestureValue.magnification)
            }
            .onEnded { value in
                   
                let rootEntity = value.entity
                print("🎮 MANUAL MODE: Scale ended on \(rootEntity.name) - Final scale: \(rootEntity.scale)")
                
                // Reset the `initialScale` back to `nil` when the gesture ends
                self.initialScale = nil
            }
            .simultaneously(with: createRotateGesture())
    }
    
    // MARK: - Private Helper Gestures
    
    /// Creates a 3D rotation gesture specifically for the MAP entity
    /// - Returns: A RotateGesture3D that only applies to MAP entities
    ///
    /// This gesture works simultaneously with the scale gesture to allow
    /// smooth MAP rotation while scaling.
    private func createRotateGesture() -> some Gesture {
        // Higher minimumAngleDelta = less sensitive, won't interfere with scale gesture
        RotateGesture3D(minimumAngleDelta: .degrees(15))
            .targetedToAnyEntity()
            .onChanged { value in
                 
                let rootEntity = value.entity
                
                // Update the current gesture rotation
                self.mapGestureRotation = value.rotation
                
                // Apply the combined rotation (accumulated + current gesture)
                let combinedRotation = self.mapRotation3D.rotated(by: self.mapGestureRotation)
                
                // Convert Rotation3D to simd_quatf and apply to entity
                rootEntity.transform.rotation = simd_quatf(combinedRotation)
                
                print("🎮 MANUAL MODE: Rotating MAP in 3D (on scale) - rotation: \(value.rotation)")
            }
            .onEnded { value in
                    
                let rootEntity = value.entity
                
                // Finalize the accumulated rotation
                self.mapRotation3D = self.mapRotation3D.rotated(by: value.rotation)
                self.mapGestureRotation = .identity
                
                // Apply the final rotation to entity
                rootEntity.transform.rotation = simd_quatf(self.mapRotation3D)
                
                print("✅ MANUAL MODE: Rotate (on scale) ended on \(rootEntity.name)")
            }
    }
}
