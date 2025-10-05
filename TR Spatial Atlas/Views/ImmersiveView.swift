//
//  ImmersiveView.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct ImmersiveView: View {
    @Environment(TrSpatialAtlasViewModel.self) var viewModel

    var body: some View {
        RealityView { content in
            content.add(viewModel.setupContentEntity())
            viewModel.makePolygon()
        }
    }
}
