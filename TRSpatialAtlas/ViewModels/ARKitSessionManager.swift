//
//  ARKitSessionManager.swift
//  TRSpatialAtlas
//
//  Created by durul dalkanat on 1/3/26.
//

import ARKit
import Combine
import OSLog
import RealityKit
import SwiftUI

@MainActor
class ARKitSessionManager: ObservableObject {
    let session = ARKitSession()
    let worldTrackingProvider = WorldTrackingProvider()

    func startSession() async {
        Logger.session.info("WorldTrackingProvider.isSupported: \(WorldTrackingProvider.isSupported)")
        Logger.session.info("PlaneDetectionProvider.isSupported: \(PlaneDetectionProvider.isSupported)")
        Logger.session.info("SceneReconstructionProvider.isSupported: \(SceneReconstructionProvider.isSupported)")
        Logger.session.info("HandTrackingProvider.isSupported: \(HandTrackingProvider.isSupported)")

        // Request authorization first
        let authorizationResult = await session.requestAuthorization(for: [.worldSensing])

        for (authorizationType, authorizationStatus) in authorizationResult {
            Logger.session.info("Authorization status for \(authorizationType): \(authorizationStatus)")
        }
        
        // Start monitoring in background tasks
        Task { await monitorSessionEvent() }
        Task { await handleWorldTrackingUpdates() }

        if WorldTrackingProvider.isSupported {
            do {
                try await session.run([worldTrackingProvider])
            } catch {
                Logger.session.error("Failed to run session: \(error)")
            }
        }
    }

    func stopSession() {
        session.stop()
    }

    func handleWorldTrackingUpdates() async {
        Logger.session.debug("\(#function): called")
        for await update in worldTrackingProvider.anchorUpdates {
            Logger.session.debug("\(#function): anchorUpdates: \(update)")
        }
    }

    func monitorSessionEvent() async {
        Logger.session.debug("\(#function): called")
        for await event in session.events {
            Logger.session.debug("\(#function): \(event)")
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
            Logger.session.warning("Could not get device anchor, using default position")
            entity.position = defaultPosition
            return
        }
        
        // MARK: Get the device (head) transform

        let headTransform = deviceAnchor.originFromAnchorTransform
        
        // MARK: Extract head position using SIMD extension

        let headPosition = headTransform.position
        
        // Validate head position (simulator often returns weird values)
        let isValidHeadPosition = headPosition.y > 0.5 && headPosition.y < 3.0
        
        if !isValidHeadPosition {
            Logger.session.warning("Invalid head position detected (\(headPosition)), using default position")
            entity.position = defaultPosition
            return
        }
        
        // MARK: Forward direction using SIMD extension
        
        // horizontalForward gives us the forward direction with Y zeroed,
        // so the map stays parallel to the ground even if the head is looking up or down.
        let normalizedForward = headTransform.horizontalForward
        
        // Place the map 2.5 meters in front of the user's head
        let distance: Float = 2.5
        let mapPosition = headPosition + normalizedForward * distance
        
        entity.position = SIMD3<Float>(mapPosition.x, headPosition.y - 0.3, mapPosition.z)
        
        Logger.contentGeneration.info("📍 Map positioned in front of user at: \(mapPosition)")
    }
}
