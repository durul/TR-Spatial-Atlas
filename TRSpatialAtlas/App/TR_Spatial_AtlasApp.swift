//
//  TR_Spatial_AtlasApp.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//
//  Main entry point for the TR Spatial Atlas application.
//  This app supports both traditional window-based interfaces and immersive
//  spatial experiences (likely visionOS) through ImmersiveSpace.

import SwiftUI

@main
struct TR_Spatial_AtlasApp: App {
    // Application-wide model for shared state management
    @State private var appModel = AppModel()

    // View model for the main spatial atlas view and its data
    @State private var viewModel = TrSpatialAtlasViewModel()

    var body: some Scene {
        // Main window group containing the primary interface
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(viewModel)
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)

        // Immersive space for spatial/AR experiences (visionOS)
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveMapView()
                .environment(appModel)
                .environment(viewModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
