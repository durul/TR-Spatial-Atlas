//
//  ImmersiveView.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import ARKit
import OSLog
import RealityKit
import RealityKitContent
import SwiftUI

struct ImmersiveMapView: View {
    @Environment(TrSpatialAtlasViewModel.self) var atlasViewModel

    // MARK: - ARKit Session

    @ObservedObject var arKitSessionManager = ARKitSessionManager()

    // MARK: - Gesture Control

    /// Gesture control view model - handles all drag, scale, and rotation gestures
    @State private var gestureVM = GestureControlViewModel()

    // MARK: - Map Mode State

    /// Tracks if map is in flat mode (true) or vertical mode (false)
    @State private var mapIsFlat = true

    let attachmentID = "attachmentID"

    var body: some View {
        RealityView { content, attachments in
            // 3D scene setup, position, rotation
            let entity = atlasViewModel.setupContentEntity()
            content.add(entity)

            // MARK: Add the control panel attachment

            // IMPORTANT: Add to content directly, NOT as child of entity
            // Child entities inherit parent's gestures which blocks button taps
            if let sceneAttachment = attachments.entity(for: attachmentID) {
                // Store reference in ViewModel for dynamic position updates
                atlasViewModel.controlPanelEntity = sceneAttachment

                // Initial position: below the flat map
                sceneAttachment.position = SIMD3<Float>(0, 0.3, -1.2)

                // Billboard: Always face the user
                sceneAttachment.components.set(BillboardComponent())

                // Add InputTargetComponent for interactivity in immersive space
                sceneAttachment.components.set(InputTargetComponent(allowedInputTypes: .indirect))
                sceneAttachment.components.set(CollisionComponent(shapes: [.generateBox(size: [0.6, 0.4, 0.1])]))

                // Add directly to content (not entity child)
                content.add(sceneAttachment)
            }

            // Initiating GeoJSON loading.
            atlasViewModel.makePolygon()

            // Position the map in front of the user when the view appears
            Task {
                await arKitSessionManager.positionMapInFrontOfUser(entity: entity)
            }

        } update: { _, _ in
            Logger.mapData.debug("RealityView changes detected...")
        } placeholder: {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
        } attachments: {
            Attachment(id: attachmentID) {
                MapDetails(turnOnMapFlat: {
                    mapIsFlat = true
                    atlasViewModel.rotateMap(flat: true)
                    // Move control panel below the flat map
                    atlasViewModel.moveControlPanel(toTop: false)
                }, turnOffMapFlat: {
                    mapIsFlat = false
                    atlasViewModel.rotateMap(flat: false)
                    // Move control panel above the vertical map
                    atlasViewModel.moveControlPanel(toTop: true)
                })
            }
        }

        // MARK: - Gestures

        // DragGesture for translation, MagnifyGesture + RotateGesture3D for scale and rotation
        .gesture(gestureVM.createTranslationGesture())
        .gesture(gestureVM.createScaleGesture())
        .task {
            await arKitSessionManager.startSession()
        }
        .task {
            await arKitSessionManager.handleWorldTrackingUpdates()
        }
        .task {
            await arKitSessionManager.monitorSessionEvent()
        }
    }
}
