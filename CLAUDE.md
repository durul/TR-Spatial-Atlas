# CLAUDE.md — Output Style & Anti‑Sycophancy Guardrails (April 2026)

> This section hard-sets response style for Claude Code in this repo. It complements the existing build/architecture guidance below.

## Non‑Negotiable Rules
- **No flattery or validation**: never use "You're absolutely right!", "You're absolutely correct!", "Excellent point!", "Great question!", or similar praise.
- **Don't evaluate non-claims**: if the user says "Yes", "OK", or "Please", treat it as **authorization**, not correctness.
- **One short ack max (optional)**: at most one of {`Got it.`, `Understood.`} — then proceed directly to action.
- **Prefer action over prose**: return diffs, code, commands, or concrete steps first.
- **If you slip** and output any banned phrase, **silently rewrite** the answer without it.

### Banned Phrases (case-insensitive, inclusive examples)
`You're absolutely right`, `You're absolutely correct`, `Excellent point`, `Great question`, `Perfect!`, `Amazing idea`, `Brilliant`, `Spot on`, `Totally correct`.

### Allowed Brief Acknowledgments
`Got it.`, `Understood.` (use at most once, ≤ 7 words total including punctuation).

## Reply Modes (choose the most constrained that fits)

1) **Action‑First (default)**
   - Sections: **Plan (≤2 cümle)** → **Diff/Code/Commands** → **Run Steps** → **Caveat/Risk** (1 line).
   - No praise. Keep prose minimal.
2) **Diff‑Only**
   - Output unified diff or patch only. No extra prose beyond a 1‑line summary.
3) **Code‑Only**
   - Output a single code block; no extra text except filename and a 1‑line summary.
4) **Checklist Mode**
   - Bullet list of concrete steps with `Command → Expected Result` pairs.

## Critical Thinking Scaffold
Before final output, internally check:
- *Is there a simpler/safer alternative?* Name 1 item or write `None`.
- *Any contradiction with repo state?* Name it or write `None`.
Output these under **Caveat/Risk** if non‑empty.

## Leanness & Determinism
- Keep answers as short as possible while complete. Avoid emphatic adverbs: *absolutely, totally, perfectly, completely*.
- Prefer precise edits (line numbers, paths, exact commands).
- If a request is ambiguous, show your **assumption** briefly, then proceed.

## Examples

### Good

```
Got it.
Plan: remove dead approve_only path; add tests.
Diff:
<unified diff here>

Run Steps:
1) pnpm test
2) pnpm build

Caveat/Risk: None found.
```

### Bad

```
You're absolutely right! Excellent point.
Let me refactor everything from scratch...
```

---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open TRSpatialAtlas.xcodeproj

# Build for Vision Pro Simulator
xcodebuild -project TRSpatialAtlas.xcodeproj -scheme TRSpatialAtlas -destination 'platform=visionOS Simulator,name=Apple Vision Pro'

# Build for device (requires visionOS device)
xcodebuild -project TRSpatialAtlas.xcodeproj -scheme TRSpatialAtlas -destination 'platform=visionOS'

# Clean build folder
xcodebuild -project TRSpatialAtlas.xcodeproj -scheme TRSpatialAtlas clean

# Archive for distribution
xcodebuild -project TRSpatialAtlas.xcodeproj -scheme TRSpatialAtlas archive
```

### Project Configuration
- **Target Platform**: visionOS 26+ (deployment target 18.0)
- **Swift Version**: 6.3+
- **Xcode Version**: 26.0+
- **Required Capabilities**: World Sensing (for ARKit WorldTrackingProvider)

---

## Architecture Overview

### What This App Does

TR Spatial Atlas is a visionOS app that renders Türkiye's 81 provincial borders as interactive 3D geometry in mixed immersive space. It reads `Turkey.geojson`, converts GeoJSON coordinates to RealityKit 3D positions, and displays a manipulable province map the user can drag, scale, and switch between flat (tabletop) and upright (wall) orientations.

### Scene Structure

- **1 WindowGroup** (`ContentView`) — plain-styled launch window with loading state and toggle button.
- **1 ImmersiveSpace** (`ImmersiveMapView`) — `.mixed` immersion, hosts the 3D map and ARKit session.

### Core Application Flow

1. `TR_Spatial_AtlasApp.swift` — defines the two scenes, injects `AppModel` and `TrSpatialAtlasViewModel` via environment.
2. `ContentView` — shows header with Metal ripple effect, loading progress, and `ToggleImmersiveSpaceButton`.
3. `ImmersiveMapView` — `RealityView` that builds the map entity, attaches control panel (`MapDetails`), starts ARKit session, and registers drag/scale gestures.
4. `TrSpatialAtlasViewModel` — loads `Turkey.geojson`, converts features to RealityKit `ModelEntity` meshes, handles map rotation and control panel positioning.
5. `ARKitSessionManager` — starts `ARKitSession` with `WorldTrackingProvider`, queries device anchor to position the map in front of the user at launch.
6. `AppModel` — immersive space state machine: `closed / inTransition / open`.
7. `GestureControlViewModel` — `DragGesture` for translation, `MagnifyGesture` for scale, applied to `RealityView`.

---

## Key Implementation Details

### GeoJSON → 3D Mesh Pipeline

`TrSpatialAtlasViewModel` handles four geometry types from `Turkey.geojson`:

| GeoJSON Type | RealityKit Output |
| --- | --- |
| `Point` | `MeshResource.generateSphere` |
| `LineString` | Cylinder chain per segment |
| `Polygon` | `MeshDescriptor` with `.polygons` primitives |
| `MultiPolygon` | Per-ring `ModelEntity` children under a group entity |

**Coordinate transform:** `x = (longitude − centerX) × scaleFactor`, `z = −(latitude − centerY) × scaleFactor`. Y is a small per-province offset to prevent z-fighting.

**Vertex limit:** RealityKit polygon primitives max out at 255 vertices per polygon. Provinces exceeding this are downsampled to ~200 vertices via stride-based simplification (`createSubdividedPolygon`).

**Province colors:** 81 HSB-generated `UIColor` values cycled by feature index.

### Map Interaction

- Map starts **flat** (rotated 90° around X — tabletop orientation).
- `MapDetails` control panel (SwiftUI attachment) switches between flat and upright modes via `rotateMap(flat:)`, which uses `entity.move(to:relativeTo:duration:timingFunction:)` for animation.
- Control panel uses `BillboardComponent` so it always faces the user; it is added directly to `content` (not as a child of the map entity) to prevent gesture inheritance blocking button taps.

### ARKit Usage

- Uses `WorldTrackingProvider` only — no plane detection or scene reconstruction.
- At immersive space open, `positionMapInFrontOfUser` queries `deviceAnchor` and places the map 2.5 m in front of the user's head using `horizontalForward` from the `SIMD4x4` extension.
- Falls back to `(0, 1.2, -2.5)` default position on simulator or if head tracking returns invalid values.

### Metal Shader

`RippleEffect` (`Ripple.metal` + `RippleModifier.swift`) is a SwiftUI `.layerEffect` applied to the header text in `ContentView`. It triggers on `counter` state changes via `ToggleImmersiveSpaceButton` callback.

### Known Tech Debt

- `ARKitSessionManager` uses `ObservableObject` / `@ObservedObject` (legacy). Candidate for migration to `@Observable`.
- `TrSpatialAtlasViewModel` is not `@MainActor` isolated despite owning RealityKit entities — could cause concurrency warnings under strict Swift 6 checking.

---

## File Organization

```
TRSpatialAtlas/
├── App/
│   └── TR_Spatial_AtlasApp.swift       # Scene definitions, environment injection
├── Model/
│   ├── AppModel.swift                  # Immersive space state machine
│   ├── GeoJSONDataDTO.swift            # Decodable GeoJSON types
│   └── GestureControlViewModel.swift  # Drag + scale gesture factories
├── ViewModels/
│   ├── TrSpatialAtlasViewModel.swift  # GeoJSON loading, mesh generation, map control
│   └── ARKitSessionManager.swift      # ARKitSession + WorldTrackingProvider
├── Views/
│   ├── ContentView.swift              # Launch window
│   ├── ImmersiveMapView.swift         # RealityView, gestures, ARKit tasks
│   ├── MapDetails.swift               # Control panel attachment (flat/upright toggle)
│   └── ToggleImmersiveSpaceButton.swift
├── RippleEffect/
│   ├── Ripple.metal                   # Metal layer effect shader
│   └── RippleModifier.swift           # SwiftUI ViewModifier wrapper
├── Extensions/
│   └── SIMD+Extensions.swift          # SIMD4x4 helpers: .position, .horizontalForward
├── Utilities/
│   └── Logger+Extension.swift         # OSLog subsystem/category constants
├── Turkey.geojson                     # Province border data (81 features)
└── Assets.xcassets/

Packages/RealityKitContent/
└── Sources/RealityKitContent/
    └── RealityKitContent.rkassets/
        ├── Immersive.usda
        ├── SkyDome.usdz
        └── Ground/
```
