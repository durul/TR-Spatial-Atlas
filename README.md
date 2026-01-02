# 🇹🇷 Türkiye Map VisionOS Application

This project is a VisionOS application that visualizes the boundaries of Turkey's 81 provinces in 3D.  
It serves as a strong example of **GeoJSON polygon data visualization** using **RealityKit**  
and showcases the power of **Spatial Computing** on VisionOS.

<img width="3840" height="2160" alt="Simulator Screenshot - Apple Vision Pro - 2025-10-05 at 11 32 26" src="https://github.com/user-attachments/assets/38a51bc5-4124-4e28-aeb3-756f9018931b" />

## ✨ Features

- **Visualization of 81 Provinces**: Renders the boundaries of all provinces in Turkey as colorful 3D polygons.
- **VisionOS Mixed Reality**: Optimized mixed reality experience for Apple Vision Pro.
- **GeoJSON Support**: Reads map data in standard GeoJSON format (81 provinces + islands).
- **MultiPolygon Support**: Special processing for islands and fragmented provinces.
- **Smart Filtering**: Optimizes performance by filtering out small islets.
- **81 Different Colors**: Each province is displayed in a unique HSB-generated color.
- **Head-Relative Positioning**: Map spawns directly in front of the user using ARKit head tracking.
- **Hand Manipulation**: Move, rotate, and scale the map with your hands.

## Project Structure

```
TR Spatial Atlas/
├── TRSpatialAtlas/
│   ├── App/
│   │   └── TR_Spatial_AtlasApp.swift    # Main application entry point
│   ├── Model/
│   │   ├── AppModel.swift               # Application state management
│   │   └── GeoJSONDataDTO.swift         # GeoJSON data models
│   ├── ViewModels/
│   │   └── TrSpatialAtlasViewModel.swift # Main business logic
│   ├── Views/
│   │   ├── ContentView.swift            # Main window UI
│   │   ├── ImmersiveView.swift          # 3D immersive space with ARKit
│   │   └── ToggleImmersiveSpaceButton.swift # Toggle button for immersive space
│   ├── Turkey.geojson                   # 81 provinces map data
│   └── Info.plist
├── Packages/
│   └── RealityKitContent/               # RealityKit content package
└── scripts/
    └── validate_repo.sh                 # Git repo validation script
```

## 🎯 Project Story and Challenges

During the development of this project, **two serious rendering issues** were encountered and resolved:

### 🐛 Issue #1: "Confetti Effect" - Winding Order

**Symptoms**: The map was rendering, but it appeared as **small colorful fragments like confetti**.

#### Root Cause & Solution

- **Problem**: GeoJSON polygons were coming **clockwise**.
- RealityKit expects **counter-clockwise**.
- The polygons were facing **backwards** and were not visible!
- **Solution**: Added `vertices.reverse()` to all vertex arrays.
- **Result**: ✅ **ISSUE RESOLVED!** The entire map is displayed correctly!

### 🐛 Issue #2: Z-Fighting at Province Boundaries

**Symptoms**: Adjacent provinces were **flickering** at their shared boundaries.

#### Root Cause & Solution

- **Problem**: All provinces were rendered at the exact same Y height (`0.001`).
- The GPU couldn't decide which polygon was "in front" at shared edges.
- This caused oscillating visibility between overlapping triangles.
- **Solution**: Added a small Y offset per province based on its index:

```swift
// Each province gets a slightly different height
let yOffset: Float = 0.001 + Float(index) * 0.0001
```

- **Result**: ✅ **Z-fighting eliminated!** Smooth boundaries without flickering.

### 🎓 Lessons Learned

**1. Polygon Rendering Rule in RealityKit:**

```swift
// GeoJSON (Clockwise) → Not suitable for RealityKit!
let vertices = [point1, point2, point3, point4]

// SOLUTION: Reverse the vertex order
vertices.reverse()  // Counter-clockwise → Suitable for RealityKit! ✅
```

**2. Z-Fighting Prevention:**

```swift
// Give each overlapping surface a unique depth
let yOffset: Float = baseHeight + Float(index) * smallIncrement
```

## 🏗️ Technical Architecture

### **Main Components:**

- **VisionOS 26** - Apple Vision Pro operating system.
- **SwiftUI** - User interface.
- **RealityKit** - 3D graphics and polygon rendering.
- **ARKit** - Head tracking for user-relative positioning.
- **GeoJSON** - Turkey map data (81 provinces + islands).
- **Mixed Reality** - Mixed reality experience.

## 🎨 Visual Features

### **Color Palette (81 Colors):**

Each province is assigned a unique color using HSB color generation:

```swift
let hue = CGFloat(i) / 81.0  // Full spectrum coverage
let saturation: CGFloat = 0.7 + (CGFloat(i % 3) * 0.1)
let brightness: CGFloat = 0.6 + (CGFloat(i % 4) * 0.1)
```

### **3D Features:**

- **Opacity**: 0.95 (high visibility)
- **MultiPolygon**: Islands and fragmented provinces are supported.
- **Smart Filtering**: Small islets are automatically filtered out.
- **Vertex Simplification**: Polygons with 255+ vertices are simplified.
- **Z-Fighting Prevention**: Each province at a unique Y height.

## 📍 Head-Relative Positioning

The map uses ARKit's `WorldTrackingProvider` to spawn in front of the user:

```swift
let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
let headPosition = SIMD3<Float>(headTransform.columns.3.x, ...)
let headForward = SIMD3<Float>(-headTransform.columns.2.x, 0, -headTransform.columns.2.z)

// Place map 2.5m in front of user
let mapPosition = headPosition + normalize(headForward) * 2.5
entity.position = SIMD3<Float>(mapPosition.x, headPosition.y - 0.3, mapPosition.z)
```

**Fallback**: In simulator or when tracking fails, defaults to `(0, 1.2, -2.5)`.

## 🔧 Development Details

### **Coordinate Transformation:**

```swift
// Center of Turkey: Near Ankara
let center: SIMD2<Float> = [35.0, 39.0]
let scaleFactor: Float = 0.05

// Convert GeoJSON coordinates to 3D space
let x = (longitude - center.x) * scaleFactor
let z = (latitude - center.y) * scaleFactor
let y: Float = yOffset  // Unique per province to prevent z-fighting
```

### **3D Mesh Creation:**

```swift
var meshDescriptor = MeshDescriptor()
meshDescriptor.positions = .init(vertices)
meshDescriptor.primitives = .polygons(counts, indices)

let mesh = try MeshResource.generate(from: [meshDescriptor])
var material = UnlitMaterial(color: provinceColor)
material.blending = .transparent(opacity: 0.95)

let entity = ModelEntity(mesh: mesh, materials: [material])
```

## 📊 Performance Optimizations

- ✅ **Single GeoJSON File**: 81 provinces in a single file (241KB)
- ✅ **Vertex Simplification**: 255+ vertices → automatic simplification
- ✅ **Island Filtering**: Small islands are automatically discarded
- ✅ **Efficient Batching**: Entity group per province
- ✅ **Z-Fighting Prevention**: Unique Y offset per province
- ✅ **Optimized Scale**: `scaleFactor = 0.05` (optimal size)

## 🚀 Upcoming Enhancements

1. **🎯 Interactivity**: Click on provinces to display information
2. **📊 Data Layers**: Population, income, tourism data overlay
3. **🎨 Animation**: Dynamic elevation of provinces

---

**Special Note:** The **Winding Order** and **Z-Fighting** issues encountered in this project are common problems in 3D graphics programming. These solutions can be applied to similar projects! 🎯
