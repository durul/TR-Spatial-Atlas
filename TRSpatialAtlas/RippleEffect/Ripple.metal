//
//  Ripple.metal
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 1/16/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[ stitchable ]]
half4 Ripple(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    // 1. Calculate distance from the touch point
    float distance = length(position - origin);
    // 2. Calculate delay (ripple takes time to travel)
    float delay = distance / speed;
    // 3. Adjust time based on delay
    time -= delay;
    time = max(0.0, time);
    // 4. The Physics: Sine wave * Exponential Decay
    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);
    // 5. Calculate the new pixel position to sample (Distortion)
    float2 n = normalize(position - origin);
    float2 newPosition = position + rippleAmount * n;
    // 6. Sample the color from the layer at the distorted position
    half4 color = layer.sample(newPosition);
    // 7. Add a slight lighting effect based on alpha (Red Tint)
    // We add red to the RGB channels. using max(0.0, ...) ensures we only add color on the crests (peaks),
    // or we can allow negative to subtract. Let's make it a glowing red scan line.
    half3 redTint = half3(1.5, 0.0, 0.0); // Strong red
    color.rgb += redTint * (rippleAmount / amplitude) * color.a;
    return color;
}
