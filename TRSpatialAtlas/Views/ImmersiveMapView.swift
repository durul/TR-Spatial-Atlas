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

    @ObservedObject var arKitSessionManager = ARKitSessionManager()

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
                await arKitSessionManager.positionMapInFrontOfUser(entity: entity)
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
