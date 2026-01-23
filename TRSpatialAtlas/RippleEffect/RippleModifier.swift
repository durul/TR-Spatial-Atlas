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
        content.keyframeAnimator(initialValue: 0, trigger: trigger) { view, elapsedTime in
            view.modifier(RippleModifier(origin: origin, elapsedTime: elapsedTime, duration: duration))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }
}

#Preview("Ripple - Tap to trigger") {
    struct Demo: View {
        @State private var trigger = 0
        @State private var origin: CGPoint = .init(x: 160, y: 80)

        var body: some View {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.blue.gradient)
                        .frame(width: 320, height: 160)
                        .overlay(alignment: .topLeading) {
                            Text("Tap button to ripple")
                                .font(.headline)
                                .padding()
                                .foregroundStyle(.white)
                        }
                }
                .modifier(RippleEffect(origin: origin, trigger: trigger))

                Button("Trigger Ripple") {
                    origin = CGPoint(x: CGFloat.random(in: 40...280),
                                     y: CGFloat.random(in: 30...130))
                    trigger += 1
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    return Demo()
}
