# 🗺️ TR-Spatial-Atlas: Cross-Device Placement Recovery

## 🎯 0. Purpose

This document plans an A-to-Z feature expansion for **TR-Spatial-Atlas**: adding persistent spatial placement, recovery diagnostics, and fallback relocalization patterns for Apple Vision Pro / visionOS.

The core idea is to turn TR-Spatial-Atlas from a strong 3D GeoJSON visualization project into a serious enterprise-style spatial computing demo that addresses a real platform gap:

> visionOS can persist `WorldAnchor`s on the same device and can share coordinate spaces live with nearby devices, but it does not currently provide a supported `ARWorldMap`-style asynchronous cross-device handoff workflow.

For TR-Spatial-Atlas, this means:

- 📍 A user should be able to place the Turkey map in a physical room.
- 💾 The app should remember that placement on the same device.
- 🧭 If the placement cannot be recovered confidently, the app should guide the user through fallback recovery.
- ⚠️ The app should clearly separate what is supported by visionOS from what is a workaround.
- 🏆 The feature should become portfolio-quality proof that the project understands real spatial computing deployment friction.

---

## 📋 1. Executive Summary

### ✅ Current TR-Spatial-Atlas

TR-Spatial-Atlas currently demonstrates:

- 🇹🇷 3D visualization of Turkey's 81 provinces.
- 🗂️ GeoJSON polygon parsing.
- 🧩 MultiPolygon handling.
- 🎨 RealityKit mesh generation.
- ✋ Hand manipulation: move, rotate, scale.
- 📐 Flat tabletop and vertical wall display modes.
- 👤 Head-relative initial placement.
- 🛠️ RealityKit rendering fixes such as winding order correction, double-sided rendering, z-fighting mitigation, and vertex downsampling.

### 🚀 Proposed Expansion

Add a new layer called:

> **Spatial Persistence Layer**

This layer will handle:

1. 💾 Saving user-adjusted map placement.
2. 📌 Creating a local `WorldAnchor` for same-device recovery.
3. 🔄 Attempting automatic recovery when the app starts.
4. 📊 Showing recovery status and confidence to the user.
5. 🆘 Offering fallback relocalization when recovery fails.
6. 🎛️ Providing manual fine-tune controls.
7. 📝 Logging recovery attempts for debugging.
8. 📖 Documenting the current visionOS limitation honestly.

### 💡 Strategic Value

This feature makes TR-Spatial-Atlas more than a visual demo. It becomes a **real spatial deployment prototype**.

That matters because spatial computing apps often fail not because the 3D content is weak, but because the last-mile placement and recovery workflow is fragile.

---

## ❓ 2. Problem Definition

### 🏁 The Last-Mile Problem

In spatial computing, the content itself is only half the problem.

The harder problem is:

> **How does the app know exactly where virtual content belongs in a real physical room, repeatedly and reliably?**

For example:

- 🏛️ A museum wants a 3D historical map to appear on the same table every day.
- 🏠 A real estate app wants virtual furniture to appear in the same empty apartment for every prospect.
- 🏫 A classroom wants a 3D geography model to appear on the same wall for every lesson.
- 🛍️ A showroom wants spatial product overlays to align with physical display stands.

TR-Spatial-Atlas can become a clean educational demo for this class of problem.

### ✅ What visionOS Solves

visionOS supports local spatial persistence patterns through `WorldAnchor`s and ARKit world tracking.

This is enough for:

- 🔁 Same-device relaunch recovery.
- 👤 A user placing content and returning later on the same Vision Pro.
- 🏡 A local persistent scene experience.

### ❌ What visionOS Does Not Fully Solve

The missing workflow is **asynchronous cross-device handoff**.

That means:

- 📱 Device A sets up the spatial scene today.
- 📱 Device B loads the same spatial scene tomorrow.
- 🎯 Device B aligns automatically to the same real-world location.
- ⏱️ The setup device and target device do not need to be active at the same time.

On iOS, [`ARWorldMap`](https://developer.apple.com/documentation/arkit/saving-and-loading-world-data) supported a version of this style of workflow. The iOS pattern is:

- 📸 `ARSession.getCurrentWorldMap(completionHandler:)` extracts the current spatial mapping as a serializable `ARWorldMap`.
- 📦 The `ARWorldMap` is `NSSecureCoding`-archivable — write it to disk or transmit it over the network.
- 🚦 `ARFrame.worldMappingStatus` reports when the map is `.mapped` and worth saving.
- 🔁 At load time, assign the decoded `ARWorldMap` to `ARWorldTrackingConfiguration.initialWorldMap` and run the session; ARKit then **relocalizes** the device against the saved features.

> ⚠️ On visionOS there is no direct equivalent exposed as a supported, documented cross-device persistent handoff API. `WorldAnchor`s persist on the **same** Vision Pro between sessions, but there is no public `ARWorldMap`-style serializable spatial map you can hand to another device.

### 🎯 Why This Matters for TR-Spatial-Atlas

The current app spawns the map relative to the user's head.

That is good for a first-run experience, but it does not answer:

- 🪑 Can the map stay on the same table?
- 🧱 Can the map reappear on the same wall?
- 🟢 Can the app tell the user whether the placement was recovered confidently?
- 🆘 Can the app guide the user if recovery fails?
- 🔄 Can the placement workflow become repeatable enough for demo, classroom, museum, or enterprise use?

This feature answers those questions.

### 🌐 2.5 Cross-Device Placement Strategy

The cross-device picture is not binary "supported / unsupported" — it is four distinct scenarios with different mechanisms and persistence semantics. TR-Spatial-Atlas should be explicit about which one it claims to solve and which one it works around.

| Scenario                                     | Supported?             | Mechanism                                                    | Persistence                  |
| -------------------------------------------- | ---------------------- | ------------------------------------------------------------ | ---------------------------- |
| 🥽 Same Vision Pro, later                    | ✅ Yes                 | Local `WorldAnchor` + `PlacementProfile`                     | Persistent on same device    |
| 👥 Another Vision Pro, same time             | ⚠️ Yes-ish             | Live shared coordinate space / `SharePlay`-style session     | Session-bound                |
| 🛰️ Another Vision Pro, later                 | ❌ Not natively        | Marker / manual calibration / external spatial mapping       | App-defined workaround       |
| 🔁 Another Vision Pro after live calibration | 🟡 Possible workaround | Join shared session once, then save local anchor on Device B | Local persistence per device |

**📌 What TR-Spatial-Atlas commits to:**

- ✅ **Row 1** is the primary target: same-device persistence built on `WorldAnchor` (§ 5.1 – § 5.2, § 8.2).
- 🟡 **Row 4** is the realistic enterprise pattern: pair Device B with Device A once via shared session, let Device B persist its own `WorldAnchor`, then both devices behave like Row 1 independently.
- ⚠️ **Row 2** is intentionally **out of scope** for this feature (covered by `SharePlay` / `GroupActivities`, not by the persistence layer).
- ❌ **Row 3** is the gap that motivates the marker fallback (§ 5.4) — TR-Spatial-Atlas does not pretend to solve it natively, only to provide a practical workaround.

> 💡 The README limitation block (§ 12) should reference this table so readers immediately see _which_ cross-device case the app handles and which it explicitly does not.

---

## 🎯 3. Product Goal

### 🥇 Main Goal

Add a **persistent placement workflow** to TR-Spatial-Atlas so the Turkey map can be placed, saved, recovered, corrected, and inspected across app sessions on the same device.

### 🥈 Secondary Goal

Design the code and documentation so it clearly demonstrates the current limitation of visionOS cross-device persistence and practical fallback strategies.

### 🚫 Non-Goal

This project should **not** pretend to solve unsupported cross-device `WorldAnchor` transfer.

The project should not claim:

- ❌ It transfers `WorldAnchor`s across devices.
- ❌ It guarantees perfect cross-device recovery.
- ❌ It replaces an official Apple asynchronous spatial map API.

Instead, it should say:

> TR-Spatial-Atlas demonstrates practical fallback patterns for persistent spatial placement on visionOS, including same-device `WorldAnchor` recovery, saved placement profiles, manual correction, and optional marker-based relocalization.

---

## 👤 4. User Experience Flow

### 🚀 4.1 First Launch Flow

1. User opens TR-Spatial-Atlas.
2. Main window appears.
3. User taps **Show Turkey Map**.
4. App opens immersive space.
5. Map spawns in front of the user using current head-relative positioning.
6. User moves, rotates, and scales the map using gestures.
7. User chooses placement mode:
   - 📐 Tabletop
   - 🧱 Wall
8. User taps **Save Placement**.
9. App creates a `WorldAnchor` near the map.
10. App stores a placement profile locally.
11. UI confirms: ✅ **Placement Saved**.

### 🔄 4.2 Relaunch Recovery Flow

1. User opens the app later on the same Vision Pro.
2. App checks for saved placement profile.
3. App starts world tracking.
4. App attempts to recover the saved `WorldAnchor`.
5. ✅ If recovery succeeds:
   - Map appears at saved physical location.
   - UI shows **Recovered**.
6. ⚠️ If recovery is uncertain or fails:
   - App shows **Recovery Needed**.
   - App offers fallback options:
     - 👀 Look around the room.
     - 🏷️ Use marker recovery.
     - ✋ Manually place again.
     - 🗑️ Reset placement.

### 🆘 4.3 Fallback Recovery Flow

When automatic recovery fails:

1. App shows a clear instruction panel.
2. User is asked to look at a known reference marker or reference area.
3. App detects the fallback reference.
4. App applies a correction transform to the map.
5. User can fine-tune placement manually.
6. User taps **Update Placement**.
7. App saves the corrected placement.

### 🎛️ 4.4 Manual Fine-Tune Flow

Manual fine-tune mode should include:

- ↔️ Move X/Y/Z in small increments.
- 🔄 Rotate yaw/pitch/roll in small increments.
- 📏 Scale up/down.
- 📐 Snap to tabletop mode.
- 🧱 Snap to wall mode.
- ↩️ Reset to last saved placement.
- 💾 Save corrected placement.

This is important because fallback localization is rarely perfect.

---

## 🧰 5. Feature Set

### 💾 5.1 Placement Save

Add a button:

> **Save Placement**

When tapped:

- 📸 Capture current map transform.
- 🗂️ Capture current map mode.
- 📏 Capture scale.
- 📌 Create or update a local `WorldAnchor`.
- 💽 Persist placement metadata.
- 📝 Log the operation.

Stored metadata should include:

```swift
struct PlacementProfile: Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var mapMode: MapDisplayMode
    var contentTransform: CodableTransform
    var anchorID: UUID?
    var scale: Float
    var version: Int
}
```

### 🔄 5.2 Placement Recovery

On app launch or immersive space start:

- 📂 Load saved placement profile.
- 🛰️ Start ARKit world tracking.
- 🔍 Attempt to locate the associated `WorldAnchor`.
- 🧭 Reconstruct content transform relative to recovered anchor.
- ⚠️ If anchor is unavailable, fall back to stored transform relative to current session origin only as a weak fallback.

The UI must make the difference clear:

| State                       | Meaning                                                 |
| --------------------------- | ------------------------------------------------------- |
| 🕳️ **Not Saved**            | No placement profile exists                             |
| 🔍 **Searching**            | App is trying to recover spatial context                |
| ✅ **Recovered**            | `WorldAnchor` / local context recovered                 |
| 🟡 **Weak Recovery**        | Stored transform applied, but spatial confidence is low |
| 🆘 **Needs Relocalization** | App needs user assistance                               |
| ❌ **Failed**               | Recovery failed                                         |

### 📊 5.3 Recovery Diagnostics Panel

Add a small developer-facing panel.

It should show:

- 🚦 Placement status.
- 🕒 Last saved date.
- 🆔 Anchor ID.
- 🔢 Recovery attempt count.
- ⏱️ Time to recovery.
- 📐 Current map mode.
- 📍 Current transform summary.
- 🛟 Whether fallback was used.
- ❗ Last error.

This turns the app into a serious debugging and learning tool.

### 🏷️ 5.4 Marker-Based Fallback

Add optional fallback mode:

> **Use Reference Marker**

Possible implementations:

#### 🅰️ Option A: Image Marker

Use an image anchor as a known spatial reference.

✅ Good for:

- Fast proof of concept.
- Print-and-test workflow.
- Demo rooms.
- Classroom use.

⚠️ Weakness:

- Requires visible marker.
- Feels less magical.
- Adds visual clutter.

#### 🅱️ Option B: Physical Reference Object

Use a known object or calibration board.

✅ Good for:

- Enterprise demos.
- Showrooms.
- Repeatable calibration.

⚠️ Weakness:

- More setup effort.
- Object detection may be less precise unless carefully designed.

#### 🅲 Option C: Manual Reference Point

Let the user manually align the map to a known point.

✅ Good for:

- No marker needed.
- Easy implementation.
- Useful as universal fallback.

⚠️ Weakness:

- User-dependent.
- Less precise.

> 💡 **Recommended first version:** Start with manual fine-tune + image marker. Add object-based fallback later.

---

## 🏗️ 6. Architecture

### 🧱 6.1 New Layer Overview

Add a new feature layer:

```text
Spatial Persistence Layer
├── PlacementProfile
├── PlacementStore
├── SpatialAnchorManager
├── PlacementRecoveryManager
├── RelocalizationManager
├── ManualAlignmentViewModel
└── RecoveryDiagnostics
```

### 📁 6.2 Proposed Project Structure

```text
TRSpatialAtlas/
├── App/
│   └── TR_Spatial_AtlasApp.swift
├── Model/
│   ├── AppModel.swift
│   ├── GeoJSONDataDTO.swift
│   ├── GestureControlViewModel.swift
│   ├── PlacementProfile.swift
│   ├── CodableTransform.swift
│   └── RecoveryState.swift
├── ViewModels/
│   ├── TrSpatialAtlasViewModel.swift
│   ├── SpatialAnchorManager.swift
│   ├── PlacementRecoveryManager.swift
│   ├── PlacementStore.swift
│   ├── ManualAlignmentViewModel.swift
│   └── RelocalizationManager.swift
├── Utilities/
│   ├── Logger+Extension.swift
│   └── Transform+Codable.swift
├── Views/
│   ├── ContentView.swift
│   ├── ImmersiveMapView.swift
│   ├── MapDetails.swift
│   ├── ToggleImmersiveSpaceButton.swift
│   ├── PlacementControlsView.swift
│   ├── RecoveryDiagnosticsView.swift
│   └── ManualAlignmentControlsView.swift
├── Resources/
│   ├── Turkey.geojson
│   └── ReferenceMarker.arresourcegroup
└── Info.plist
```

---

## 🧬 7. Data Model

### 📦 7.1 `PlacementProfile`

```swift
struct PlacementProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var mapMode: MapDisplayMode
    var contentTransform: CodableTransform
    var anchorID: UUID?
    var scale: Float
    var fallbackReferenceID: String?
    var version: Int
}
```

### 📐 7.2 `MapDisplayMode`

```swift
enum MapDisplayMode: String, Codable {
    case tabletop
    case wall
}
```

### 🚦 7.3 `RecoveryState`

```swift
enum RecoveryState: Equatable {
    case notSaved
    case idle
    case searching
    case recovered
    case weakRecovery
    case needsRelocalization
    case failed(String)
}
```

### 🔄 7.4 `CodableTransform`

RealityKit `Transform` is not directly ideal for persistence. Create a codable wrapper.

```swift
struct CodableTransform: Codable {
    var translation: SIMD3<Float>
    var rotation: SIMD4<Float>
    var scale: SIMD3<Float>
}
```

Where rotation stores quaternion components:

```swift
SIMD4<Float>(x, y, z, w)
```

---

## ⚙️ 8. Core Components

### 💽 8.1 `PlacementStore`

**Responsibility:**

- Save placement profile to disk.
- Load placement profile from disk.
- Delete placement profile.
- Version placement schema.

**Suggested storage:**

- JSON file in app documents directory.
- Name: `placement_profile.json`

**Example API:**

```swift
final class PlacementStore {
    func save(_ profile: PlacementProfile) throws
    func load() throws -> PlacementProfile?
    func delete() throws
}
```

### 📌 8.2 `SpatialAnchorManager`

**Responsibility:**

- Create `WorldAnchor`.
- Update `WorldAnchor`.
- Remove `WorldAnchor`.
- Query anchor recovery state.

**Example API:**

```swift
@MainActor
final class SpatialAnchorManager: ObservableObject {
    func createAnchor(for entity: Entity) async throws -> UUID
    func updateAnchor(for entity: Entity, existingID: UUID?) async throws -> UUID
    func removeAnchor(id: UUID) async throws
    func tryRecoverAnchor(id: UUID) async throws -> Transform?
}
```

> ⚠️ **Important:** exact ARKit APIs may need adjustment based on current visionOS SDK behavior. Keep this manager isolated so API changes are contained.

### 🔁 8.3 `PlacementRecoveryManager`

**Responsibility:**

- Coordinate the recovery flow.
- Decide whether automatic recovery succeeded.
- Trigger fallback flow if needed.
- Update `RecoveryState`.

**Example API:**

```swift
@MainActor
final class PlacementRecoveryManager: ObservableObject {
    @Published var state: RecoveryState = .idle
    @Published var diagnostics = RecoveryDiagnostics()
    func recover(profile: PlacementProfile, contentEntity: Entity) async
    func markNeedsRelocalization(reason: String)
    func applyManualCorrection(_ transform: Transform)
}
```

### 🎛️ 8.4 `ManualAlignmentViewModel`

**Responsibility:**

- Tiny placement corrections.
- Works even when AR recovery fails.
- Keeps user in control.

**Controls:**

```swift
func moveX(_ delta: Float)
func moveY(_ delta: Float)
func moveZ(_ delta: Float)
func rotateYaw(_ degrees: Float)
func rotatePitch(_ degrees: Float)
func rotateRoll(_ degrees: Float)
func scale(_ delta: Float)
func resetToLastSaved()
func commitCorrection()
```

### 🏷️ 8.5 `RelocalizationManager`

**Responsibility:**

- Optional marker/object fallback.
- Detect reference marker.
- Compute correction transform.
- Apply correction to content entity.

**Version 1 can be simple:**

- 👀 User looks at marker.
- 📍 App gets marker transform.
- 🗺️ App places atlas relative to marker transform.
- 🎛️ User fine-tunes.
- 💾 App saves updated placement.

---

## 🖥️ 9. UI Plan

### 🎮 9.1 Placement Controls

Add a new panel near existing `MapDetails` controls:

**Buttons:**

- 💾 Save Placement
- 🔄 Recover Placement
- 🎛️ Fine-Tune
- 🗑️ Reset Placement
- 🏷️ Use Marker

**Status pill:**

- 🕳️ Not Saved
- 🔍 Searching
- ✅ Recovered
- 🆘 Needs Relocalization
- ❌ Failed

### 📊 9.2 `RecoveryDiagnosticsView`

Developer mode panel:

```text
Placement Status: Recovered
Last Saved: 2026-05-12 14:34
Anchor ID: 4D2B...
Recovery Time: 1.4s
Fallback Used: No
Map Mode: Tabletop
Transform: x 0.12, y 1.10, z -2.4
Scale: 0.85
```

### 🎚️ 9.3 `ManualAlignmentControlsView`

Use compact controls:

```text
Position
[X-] [X+]  [Y-] [Y+]  [Z-] [Z+]
Rotation
[Yaw-] [Yaw+]  [Pitch-] [Pitch+]  [Roll-] [Roll+]
Scale
[-] [+]
[Reset] [Save Correction]
```

### 💬 9.4 User Messaging

Avoid technical confusion.

**✅ Good copy:**

- "Placement recovered on this device."
- "We need help finding the saved room position."
- "Look around the room slowly."
- "Use marker recovery if the map appears in the wrong place."
- "This fallback improves local alignment; it does not transfer Apple WorldAnchors across devices."

**❌ Bad copy:**

- "Anchor synced across devices."
- "Guaranteed placement."
- "Permanent room map transferred."

---

## 🔧 10. Technical Flow

### 💾 10.1 Save Placement

```text
User taps Save Placement
    ↓
Get contentEntity.transform
    ↓
Create CodableTransform
    ↓
Create or update WorldAnchor
    ↓
Create PlacementProfile
    ↓
Save JSON profile
    ↓
Update UI state to Recovered/Saved
    ↓
Log result
```

### 🔄 10.2 Recover Placement

```text
App starts immersive space
    ↓
Load placement_profile.json
    ↓
If no profile: use head-relative default placement
    ↓
If profile exists: start recovery
    ↓
Try WorldAnchor recovery
    ↓
If success: apply recovered transform
    ↓
If weak/fail: show fallback UI
```

### 🏷️ 10.3 Marker Fallback

```text
Recovery failed
    ↓
User taps Use Marker
    ↓
App starts marker detection
    ↓
User looks at marker
    ↓
Marker transform found
    ↓
Apply predefined atlas offset from marker
    ↓
User fine-tunes
    ↓
Save corrected placement
```

---

## 🏁 11. Milestones

### 🥇 Milestone 1: Placement Profile Storage

**🎯 Goal:**

- Save and load map transform without ARKit anchor logic first.

**📋 Tasks:**

- Add `PlacementProfile`.
- Add `CodableTransform`.
- Add `PlacementStore`.
- Add **Save Placement** button.
- Add **Load Placement** on app launch.
- Apply saved transform to `contentEntity`.

**✅ Acceptance Criteria:**

- User can move/scale/rotate the map.
- User can save placement.
- User can relaunch app.
- Map returns to saved transform relative to current session origin.
- UI shows saved state.

**⚠️ Risk:**

- This is not true spatial recovery yet. It is transform persistence only.

### 🥈 Milestone 2: Local `WorldAnchor` Integration

**🎯 Goal:**

- Add same-device spatial persistence using `WorldAnchor`.

**📋 Tasks:**

- Add `SpatialAnchorManager`.
- Create `WorldAnchor` when saving placement.
- Store anchor ID in `PlacementProfile`.
- Recover anchor when immersive space starts.
- Apply map transform relative to recovered anchor.
- Add recovery state UI.

**✅ Acceptance Criteria:**

- App attempts local spatial recovery.
- Successful recovery is clearly shown.
- Failed recovery falls back to recovery UI.
- Logs show anchor lifecycle events.

**⚠️ Risk:**

- ARKit API details may differ by SDK version.
- Recovery may be environment-sensitive.

### 🥉 Milestone 3: Recovery Diagnostics

**🎯 Goal:**

- Make recovery visible and debuggable.

**📋 Tasks:**

- Add `RecoveryDiagnostics`.
- Add `RecoveryDiagnosticsView`.
- Log attempt count, elapsed time, state transitions, last error.
- Add developer mode toggle.

**✅ Acceptance Criteria:**

- Developer can understand why recovery worked or failed.
- Logs help compare test rooms and lighting conditions.

### 🎯 Milestone 4: Manual Fine-Tune

**🎯 Goal:**

- Let user correct placement precisely.

**📋 Tasks:**

- Add `ManualAlignmentViewModel`.
- Add position controls.
- Add rotation controls.
- Add scale controls.
- Add reset and commit buttons.

**✅ Acceptance Criteria:**

- User can correct bad placement without restarting.
- User can save the corrected transform.

### 🏷️ Milestone 5: Marker-Based Fallback

**🎯 Goal:**

- Add practical fallback relocalization.

**📋 Tasks:**

- Add reference image resource.
- Add marker detection flow.
- Add `RelocalizationManager`.
- Define atlas offset relative to marker.
- Apply marker-based transform.
- Save corrected placement.

**✅ Acceptance Criteria:**

- If anchor recovery fails, marker recovery can place the map approximately.
- User can fine-tune after marker recovery.
- UI clearly says fallback was used.

### 📖 Milestone 6: Documentation & Demo Polish

**🎯 Goal:**

- Make it portfolio-ready.

**📋 Tasks:**

- Update README.
- Add `Docs/SpatialPersistence.md`.
- Add architecture diagram.
- Add limitations section.
- Add demo script.
- Add screenshots or video capture.

**✅ Acceptance Criteria:**

- A recruiter, Apple engineer, or spatial computing developer can understand the problem and solution in under 5 minutes.
- The documentation does not overclaim unsupported Apple APIs.

---

## 📘 12. README Update Plan

Add a new README section:

> ## 🧭 Spatial Persistence & Recovery
>
> TR-Spatial-Atlas includes an experimental spatial persistence layer that saves map placement, attempts same-device `WorldAnchor` recovery, and provides fallback relocalization tools when the saved placement cannot be confidently restored.
>
> This feature is designed to explore a real last-mile spatial computing challenge: persistent placement across sessions. It does not claim to provide unsupported asynchronous cross-device `WorldAnchor` transfer.

**Add feature bullets:**

- 💾 Save map placement in tabletop or wall mode.
- 🔄 Attempt same-device `WorldAnchor` recovery.
- 📊 Show recovery state and diagnostics.
- 🎛️ Manual fine-tune controls for correction.
- 🏷️ Optional marker-based fallback relocalization.
- 📖 Clear documentation of platform limitations.

**Add limitation section:**

> ### ⚠️ Platform Limitation
>
> visionOS supports local spatial persistence and live coordinate-space sharing patterns, but it does not currently expose an `ARWorldMap`-style asynchronous cross-device spatial handoff API. This project demonstrates practical same-device persistence and fallback recovery workflows without pretending to transfer `WorldAnchor`s across devices.

---

## ✍️ 13. Blog Post Plan

**Title ideas:**

1. Solving the Last-Mile Placement Problem in TR-Spatial-Atlas
2. WorldAnchors, Fallbacks, and Spatial Persistence on visionOS
3. Building a Practical Placement Recovery Flow for Apple Vision Pro
4. Why Spatial Apps Need Recovery UX, Not Just Anchors

**Suggested structure:**

1. 🎬 The original TR-Spatial-Atlas idea.
2. 🧩 Why visualizing 3D maps is only half the problem.
3. 📌 What `WorldAnchor`s help with.
4. ❌ What remains hard on visionOS.
5. 🚦 The recovery state machine.
6. 🎛️ Manual correction UX.
7. 🏷️ Marker fallback.
8. 💡 Lessons learned.
9. 🍎 What Apple could improve.
10. 🎉 Final demo.

---

## 🎬 14. Demo Script

### 🎥 Demo 1: Same-Device Persistence

1. Launch app.
2. Show Turkey map.
3. Move map onto table.
4. Switch to tabletop mode.
5. Save placement.
6. Quit app.
7. Relaunch app.
8. Show recovered map.
9. Open diagnostics panel.

> 💬 **Message:** The map is not just spawned in front of the user. It is recovered from a saved spatial placement profile.

### 🎥 Demo 2: Recovery Failure UX

1. Simulate failed recovery.
2. Show status: **Needs Relocalization**.
3. Tap **Use Marker**.
4. Look at marker.
5. Map snaps near expected location.
6. Fine-tune manually.
7. Save corrected placement.

> 💬 **Message:** Spatial apps need graceful recovery. The user should not be abandoned when world tracking cannot confidently restore the scene.

### 🎥 Demo 3: Enterprise Framing

**Scenario:**

A museum installs a 3D map exhibit. The curator places it once. Visitors or staff need repeatable placement later. This demo shows same-device persistence and fallback recovery patterns that reduce setup friction.

---

## ⚠️ 15. Risks and Honest Constraints

### 🚧 15.1 visionOS API Limitation

There is no supported `ARWorldMap`-style asynchronous cross-device `WorldAnchor` handoff equivalent exposed for visionOS.

**🛡️ Mitigation:**

- Be explicit in docs.
- Do not overclaim.
- Present fallback strategies as practical workarounds.

### 📉 15.2 Recovery Reliability

`WorldAnchor` recovery can depend on:

- 💡 Lighting.
- 🪑 Room changes.
- 🚶 User starting position.
- 🧱 Surface changes.
- 🔍 Visual features in the environment.

**🛡️ Mitigation:**

- Add diagnostics.
- Add fallback flow.
- Add manual correction.

### 🏷️ 15.3 Marker UX Friction

Markers are practical but not elegant.

**🛡️ Mitigation:**

- Make marker optional.
- Use it only when recovery fails.
- Keep instructions short.

### 🌀 15.4 Transform Drift

Repeated corrections may introduce drift.

**🛡️ Mitigation:**

- Store versioned profiles.
- Allow reset to last known good placement.
- Log corrections.

---

## 🏆 16. Success Criteria

This feature is successful if:

- ✅ The map can be saved and recovered on the same device.
- ✅ The app clearly shows recovery status.
- ✅ The user has a path forward when automatic recovery fails.
- ✅ Manual fine-tune works cleanly.
- ✅ Marker fallback works as a practical recovery tool.
- ✅ The README honestly explains what the app does and does not solve.
- ✅ The project becomes a stronger portfolio piece for visionOS enterprise workflows.

---

## 📋 17. Implementation Priority

**Recommended order:**

1. `PlacementProfile`
2. `CodableTransform`
3. `PlacementStore`
4. Save/load transform without `WorldAnchor`
5. Recovery UI state machine
6. Manual fine-tune controls
7. `WorldAnchor` manager
8. Recovery diagnostics
9. Marker fallback
10. README and blog polish

This order keeps the project testable at every step.

> 💡 Do not start with marker detection or `WorldAnchor` complexity first. Build the persistence foundation first.

---

## 🎟️ 18. Suggested GitHub Issues

### 🎫 Issue 1: Add `PlacementProfile` and `CodableTransform`

**Description:** Create codable data models for storing TR-Spatial-Atlas placement state.

**Tasks:**

- Add `PlacementProfile`.
- Add `MapDisplayMode`.
- Add `CodableTransform`.
- Add conversion helpers between RealityKit `Transform` and `CodableTransform`.

### 🎫 Issue 2: Add `PlacementStore`

**Description:** Persist placement profiles to local JSON storage.

**Tasks:**

- Save placement profile.
- Load placement profile.
- Delete placement profile.
- Add error handling and `OSLog` entries.

### 🎫 Issue 3: Add Save Placement UI

**Description:** Add controls that allow users to save the current map position, rotation, scale, and mode.

**Tasks:**

- Add `PlacementControlsView`.
- Add **Save Placement** button.
- Add **Reset Placement** button.
- Show saved status.

### 🎫 Issue 4: Add `RecoveryState`

**Description:** Create a clear state machine for placement recovery.

**Tasks:**

- Add `RecoveryState` enum.
- Connect it to UI.
- Show user-friendly status messages.

### 🎫 Issue 5: Add Manual Fine-Tune Controls

**Description:** Add precise transform controls for correcting placement.

**Tasks:**

- Position controls.
- Rotation controls.
- Scale controls.
- Commit correction.
- Reset to saved placement.

### 🎫 Issue 6: Add `SpatialAnchorManager`

**Description:** Encapsulate `WorldAnchor` creation, update, and recovery logic.

**Tasks:**

- Create anchor.
- Store anchor ID.
- Recover anchor.
- Handle failure.
- Log lifecycle.

### 🎫 Issue 7: Add Recovery Diagnostics Panel

**Description:** Add developer-facing diagnostics for anchor recovery.

**Tasks:**

- Recovery attempt count.
- Elapsed recovery time.
- Last error.
- Anchor ID.
- Fallback used.

### 🎫 Issue 8: Add Marker Fallback Prototype

**Description:** Add optional reference marker recovery flow for cases where automatic placement recovery fails.

**Tasks:**

- Add reference marker resource.
- Detect marker.
- Apply atlas offset.
- Allow fine-tune.
- Save corrected placement.

### 🎫 Issue 9: Update README with Spatial Persistence Section

**Description:** Document the feature clearly and honestly.

**Tasks:**

- Explain problem.
- Explain supported workflow.
- Explain platform limitation.
- Add demo script.
- Add screenshots/video.

---

## 🌿 19. Suggested Branch Plan

```text
feature/spatial-persistence-models
feature/placement-store
feature/placement-controls
feature/recovery-state-machine
feature/manual-alignment
feature/world-anchor-manager
feature/recovery-diagnostics
feature/marker-fallback
feature/docs-spatial-persistence
```

> 💡 Keep branches small. Each should compile independently.

---

## 🎯 20. Final Positioning

The final project should be positioned like this:

> TR-Spatial-Atlas is a visionOS spatial data visualization app that renders Turkey's 81 provinces as interactive 3D GeoJSON geometry in RealityKit. It also explores persistent spatial placement workflows, including same-device `WorldAnchor` recovery, recovery diagnostics, manual correction, and marker-based fallback relocalization.

This is strong because it connects:

- 🗂️ GeoJSON data visualization.
- 🎨 RealityKit mesh generation.
- ✋ Spatial interaction.
- 🛰️ ARKit world tracking.
- 🏢 Enterprise deployment friction.
- 🧐 Honest platform limitation analysis.

That combination is much more valuable than a simple 3D map demo.

---

## 🚀 21. Recommended First Commit

Start small.

**First commit title:**

```text
Add placement profile models for spatial persistence
```

**Files:**

```text
TRSpatialAtlas/Model/PlacementProfile.swift
TRSpatialAtlas/Model/CodableTransform.swift
TRSpatialAtlas/Model/RecoveryState.swift
```

**Commit body:**

> Adds codable placement models used to persist map position, rotation, scale, display mode, and recovery state metadata. This prepares the project for local spatial placement recovery and future `WorldAnchor` integration.

This gives you a clean foundation without touching risky ARKit code first.

---

## 📚 Appendix A: iOS ARKit References & visionOS Equivalents

This appendix maps the two Apple ARKit reference articles that motivated this plan to their visionOS realities. The goal is to keep the documentation honest about which iOS patterns translate, and which do not.

### A.1 [Saving and Loading World Data](https://developer.apple.com/documentation/arkit/saving-and-loading-world-data)

**📱 iOS workflow (summary of the linked article):**

- `ARWorldMap` captures session-acquired space-mapping state — feature points, anchors, and detected planes.
- `ARSession.getCurrentWorldMap(completionHandler:)` returns a snapshot you can serialize with `NSKeyedArchiver`.
- `ARFrame.worldMappingStatus` (`.notAvailable`, `.limited`, `.extending`, `.mapped`) tells you when the snapshot is rich enough to save.
- A new session reloads the archive into `ARWorldTrackingConfiguration.initialWorldMap`; ARKit then performs **relocalization** by matching live camera features against the saved map.
- Because `ARWorldMap` is a serializable value object, the same file can be sent over the network for cross-device handoff.

**🥽 visionOS reality (relevant to this project):**

| iOS concept                      | visionOS equivalent                                                 | TR-Spatial-Atlas uses           |
| -------------------------------- | ------------------------------------------------------------------- | ------------------------------- |
| `ARWorldMap` (serializable)      | ❌ No public equivalent                                             | —                               |
| `getCurrentWorldMap()`           | ❌ Not exposed                                                      | —                               |
| `initialWorldMap` relocalization | ❌ Not exposed                                                      | —                               |
| `ARFrame.worldMappingStatus`     | ⚠️ No direct query; rely on `WorldTrackingProvider` state           | Recovery diagnostics surface    |
| Per-anchor persistence           | ✅ `WorldAnchor` + `WorldTrackingProvider`                          | `SpatialAnchorManager` (§ 8.2)  |
| Cross-device sync                | ⚠️ Live only via `SharePlay` / `GroupSession`; no async map handoff | Out of scope — see § 3 Non-Goal |

**🎯 Impact on the plan:**

- § 5.1 Placement Save builds the closest visionOS-supported analog: a `WorldAnchor` plus a JSON `PlacementProfile`.
- § 5.2 Placement Recovery implements the relocalization-style state machine the iOS article describes, but scoped to **same-device** recovery.
- § 12 README Update must explicitly link this Apple page when explaining the platform gap, so readers understand why a marker-fallback (§ 5.4) is needed.

### A.2 [Occluding Virtual Content with People](https://developer.apple.com/documentation/arkit/occluding-virtual-content-with-people)

**📱 iOS workflow (summary of the linked article):**

- People occlusion runs as an `ARFrame` semantic, enabled by inserting `.personSegmentationWithDepth` (or `.personSegmentation`) into `ARConfiguration.frameSemantics`.
- ARKit produces per-frame segmentation buffers (`segmentationBuffer`, `estimatedDepthData`) that the renderer composites so virtual content goes **behind** real people.
- Requires an A12 Bionic or later device; segmentation is monocular-derived, depth is estimated.

**🥽 visionOS reality (relevant to this project):**

- visionOS does **not** expose `ARConfiguration.FrameSemantics` or per-frame segmentation buffers. Passthrough is composited by the system; hands and nearby people are occluded automatically by the compositor, not via an `ARFrame` semantic the app can toggle.
- Apps cannot programmatically request "occlude virtual content behind people" — it is a system behavior, not an opt-in `frameSemantics` flag.

**🎯 Impact on the plan:**

- This is a **second example** of an iOS ARKit pattern that does not map 1:1 to visionOS. Worth citing in § 15.1 visionOS API Limitation and the README limitation block to reinforce the broader theme: _visionOS spatial APIs are higher-level and more opinionated than iOS ARKit; some `ARFrame`-level controls are simply not surfaced._
- TR-Spatial-Atlas does not need people occlusion for the map rendering itself (the map is rigid 3D geometry, not human-aware content), but the documentation should mention it as part of the "what iOS exposes that visionOS hides" comparison.

### A.3 Suggested README Cross-Links

When updating the README (§ 12), include both links in the limitation section:

```markdown
### ⚠️ Platform Limitation

visionOS supports local spatial persistence via `WorldAnchor` but does not expose
an [`ARWorldMap`-style](https://developer.apple.com/documentation/arkit/saving-and-loading-world-data)
asynchronous cross-device handoff API. More broadly, iOS ARKit semantics such as
[people occlusion](https://developer.apple.com/documentation/arkit/occluding-virtual-content-with-people)
are not exposed as `ARFrame`-level toggles on visionOS — the system compositor
handles them implicitly. TR-Spatial-Atlas demonstrates same-device persistence
and fallback recovery within these constraints.
```
