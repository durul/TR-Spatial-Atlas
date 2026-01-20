//
//  RippleModifier.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 1/16/26.
//

import SwiftUI

struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var duration: TimeInterval

    // Aesthetic tuning
    var amplitude: Double = 12
    var frequency: Double = 10
    var decay: Double = 4
    var speed: Double = 400

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )
        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: CGSize(width: amplitude, height: amplitude),
                isEnabled: elapsedTime > 0 && elapsedTime < duration
            )
        }
    }
}

struct RippleEffect<T: Equatable>: ViewModifier {
    var origin: CGPoint
    var trigger: T

    func body(content: Content) -> some View {
        let duration: TimeInterval = 6
        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(RippleModifier(
                origin: origin,
                elapsedTime: elapsedTime,
                duration: duration
            ))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }
}
