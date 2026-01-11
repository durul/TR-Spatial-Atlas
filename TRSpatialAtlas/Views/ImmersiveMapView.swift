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
    @Environment(TrSpatialAtlasViewModel.self) var viewModel

    // MARK: - ARKit Session

    @ObservedObject var arKitSessionManager = ARKitSessionManager()

    // MARK: - Gesture Control

    /// Gesture control view model - handles all drag, scale, and rotation gestures
    @State private var gestureVM = GestureControlViewModel()

    let attachmentID = "attachmentID"

    var body: some View {
        RealityView { content, attachments in
            // 3D scene setup, position, rotation
            let entity = viewModel.setupContentEntity()
            content.add(entity)

            // Add the control panel attachment
            // IMPORTANT: Add to content directly, NOT as child of entity
            // Child entities inherit parent's gestures which blocks button taps
            if let sceneAttachment = attachments.entity(for: attachmentID) {
                // Position in world space - in front and below the map
                // User requested it to be below the map ("altinda acilsin")
                sceneAttachment.position = SIMD3<Float>(0, 0.3, -2.0)
                
                // Billboard: Always face the user
                sceneAttachment.components.set(BillboardComponent())
                
                // Make it interactive in immersive space
                sceneAttachment.components.set(InputTargetComponent())
                sceneAttachment.components.set(CollisionComponent(shapes: [.generateBox(size: [0.5, 0.3, 0.1])]))
                
                // Add directly to content (not entity child)
                content.add(sceneAttachment)
            }

            // Initiating GeoJSON loading.
            viewModel.makePolygon()

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
                    viewModel.rotateMap(flat: true)
                }, turnOffMapFlat: {
                    viewModel.rotateMap(flat: false)
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
