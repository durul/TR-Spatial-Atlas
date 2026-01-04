//
//  ARKitSessionManager.swift
//  TRSpatialAtlas
//
//  Created by durul dalkanat on 1/3/26.
//

import ARKit
import Combine
import RealityKit
import SwiftUI

@MainActor
class ARKitSessionManager: ObservableObject {
    let session = ARKitSession()
    let worldTrackingProvider = WorldTrackingProvider()

    func startSession() async {
        print("WorldTrackingProvider.isSupported: \(WorldTrackingProvider.isSupported)")
        print("PlaneDetectionProvider.isSupported: \(PlaneDetectionProvider.isSupported)")
        print("SceneReconstructionProvider.isSupported: \(SceneReconstructionProvider.isSupported)")
        print("HandTrackingProvider.isSupported: \(HandTrackingProvider.isSupported)")

        // Request authorization first
        let authorizationResult = await session.requestAuthorization(for: [.worldSensing])

        for (authorizationType, authorizationStatus) in authorizationResult {
            print("Authorization status for \(authorizationType): \(authorizationStatus)")
        }
        
        // Start monitoring in background tasks
        Task { await monitorSessionEvent() }
        Task { await handleWorldTrackingUpdates() }

        if WorldTrackingProvider.isSupported {
            do {
                try await session.run([worldTrackingProvider])
            } catch {
                print("Failed to run session: \(error)")
            }
        }
    }

    func stopSession() {
        session.stop()
    }

    func handleWorldTrackingUpdates() async {
        print("\(#function): called")
        for await update in worldTrackingProvider.anchorUpdates {
            print("\(#function): anchorUpdates: \(update)")
        }
    }

    func monitorSessionEvent() async {
        print("\(#function): called")
        for await event in session.events {
            print("\(#function): \(event)")
        }
    }
    
    /// Positions the content entity directly in front of the user's current head position
    func positionMapInFrontOfUser(entity: Entity) async {
        // Wait a moment for tracking to stabilize
        try? await Task.sleep(for: .milliseconds(200))
        
        // Default position (used as fallback for simulator)
        // 2.5m in front of the user (negative z), 1.2m in height.
        let defaultPosition = SIMD3<Float>(0, 1.2, -2.5)
        
        // deviceAnchor provides the position and orientation (pose) of the Vision Pro in 3D space.
        // It is used to understand where the user is looking.
        guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            print("Could not get device anchor, using default position")
            entity.position = defaultPosition
            return
        }
        
        // MARK: Get the device (head) transform

        let headTransform = deviceAnchor.originFromAnchorTransform
        
        // MARK: Extract head position

        // I get the translation (x, y, z) from the 4th column of the 4x4 matrix.
        // columns.3 → The device's position in the world (translation)
        let headPosition = SIMD3<Float>(
            headTransform.columns.3.x,
            headTransform.columns.3.y,
            headTransform.columns.3.z
        )
        
        // Validate head position (simulator often returns weird values)
        let isValidHeadPosition = headPosition.y > 0.5 && headPosition.y < 3.0
        
        if !isValidHeadPosition {
            print("Invalid head position detected (\(headPosition)), using default position")
            entity.position = defaultPosition
            return
        }
        
        // MARK: Forward direction
        
        /*
         • Forward direction (negative Z in the head's local space, horizontal only)
         • Matrix's columns.2 ( the device's rotation axes ) is generally the "forward/back" axis (z-axis).
         • I take its negative and use it as the "viewing direction".
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
        
        entity.position = SIMD3<Float>(mapPosition.x, headPosition.y - 0.3, mapPosition.z)
        
        print("📍 Map positioned in front of user at: \(mapPosition)")
    }
}
