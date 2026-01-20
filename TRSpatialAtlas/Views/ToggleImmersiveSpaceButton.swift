//
//  ToggleImmersiveSpaceButton.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {
    @Environment(AppModel.self) private var appModel

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var onTriggerRipple: (() -> Void)?

    var body: some View {
        Button {
            onTriggerRipple?()

            // Delay the heavy operation to let ripple animation start smoothly
            Task { @MainActor in

                switch appModel.immersiveSpaceState {
                case .open:
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                    // We set this here so the button reliably returns to "Show" even
                    // if ImmersiveView.onDisappear isn't reached for any reason.
                    appModel.immersiveSpaceState = .closed

                case .closed:
                    appModel.immersiveSpaceState = .inTransition
                    let result = await openImmersiveSpace(id: appModel.immersiveSpaceID)
                    switch result {
                    case .opened:
                        // Set state here so the button reliably flips to "Hide".
                        appModel.immersiveSpaceState = .open
                    case .userCancelled, .error:
                        appModel.immersiveSpaceState = .closed
                    @unknown default:
                        appModel.immersiveSpaceState = .closed
                    }

                case .inTransition:
                    // Button is disabled in this state.
                    break
                }
            }
        } label: {
            Text(appModel.immersiveSpaceState == .open ? "Hide Turkey Map" : "Show Turkey Map")
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .fontWeight(.semibold)
    }
}
