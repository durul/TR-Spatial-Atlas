//
//  TR_Spatial_AtlasApp.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import SwiftUI

@main
struct TR_Spatial_AtlasApp: App {
    @State private var appModel = AppModel()
    @State private var viewModel = TrSpatialAtlasViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(viewModel)
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)

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
