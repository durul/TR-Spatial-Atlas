# 🇹🇷 Türkiye Map VisionOS Application

This project is a VisionOS application that visualizes the boundaries of Turkey’s 81 provinces in 3D.  
It serves as a strong example of **GeoJSON polygon data visualization** using **RealityKit**  
and showcases the power of **Spatial Computing** on VisionOS.

## ✨ Features

- **Visualization of 81 Provinces**: Renders the boundaries of all provinces in Turkey as colorful 3D polygons.
- **VisionOS Mixed Reality**: Optimized mixed reality experience for Apple Vision Pro.
- **GeoJSON Support**: Reads map data in standard GeoJSON format (81 provinces + islands).
- **MultiPolygon Support**: Special processing for islands and fragmented provinces.
- **Smart Filtering**: Optimizes performance by filtering out small islets.
- **10 Different Colors**: Each province is displayed in a unique color.

## 🎯 Project Story and Challenges

During the development of this project, a **serious rendering issue** was encountered and resolved. Here is the entire process:

### 🐛 Main Issue Encountered: "Confetti Effect"

**Symptoms**: The map was rendering, but it appeared as **small colorful fragments like confetti**.

### 🔍 Debug Process (Step by Step)

#### 5️⃣ **REAL ISSUE: WINDING ORDER! ✅**
- **Problem**: GeoJSON polygons were coming **clockwise**.
- RealityKit expects **counter-clockwise**.
- The polygons were facing **backwards** and were not visible!
- **Test**: A simple red square was created
  - Clockwise → NOT VISIBLE ❌
  - Counter-clockwise → VISIBLE ✅
- **Solution**: Added `vertices.reverse()` to all vertex arrays.
- **Result**: ✅ **ISSUE RESOLVED!** The entire map is displayed correctly!

### 🎓 Lesson Learned

**Polygon Rendering Rule in RealityKit:**
```swift
// GeoJSON (Clockwise) → Not suitable for RealityKit!
let vertices = [point1, point2, point3, point4]

// SOLUTION: Reverse the vertex order
vertices.reverse()  // Counter-clockwise → Suitable for RealityKit! ✅
```

**Why It Matters:**
- 3D graphic engines calculate the **normal vector** of polygons from the vertex order.
- Incorrect order = Incorrect normal = Polygon faces backward = Invisible!

## 🏗️ Technical Architecture

### **Main Components:**
- **VisionOS 2.0** - Apple Vision Pro operating system.
- **SwiftUI** - User interface.
- **RealityKit** - 3D graphics and polygon rendering.
- **GeoJSON** - Turkey map data (81 provinces + islands).
- **Mixed Reality** - Mixed reality experience.

### **Project Structure:**
```
├── Packages
│   └── RealityKitContent
│       ├── Package.realitycomposerpro
│       │   ├── ProjectData
│       │   │   └── main.json
│       │   └── WorkspaceData
│       │       ├── SceneMetadataList.json
│       │       └── Settings.rcprojectdata
│       ├── Package.swift
│       ├── README.md
│       └── Sources
│           └── RealityKitContent
│               ├── RealityKitContent.rkassets
│               │   ├── Ground
│               │   │   ├── DefaultAttenuationMap.exr
│               │   │   └── Ground.usda
│               │   ├── Immersive.usda
│               │   └── SkyDome.usdz
│               └── RealityKitContent.swift
├── README.md
├── TR Spatial Atlas
│   ├── App
│   │   └── TR_Spatial_AtlasApp.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.solidimagestack
│   │   │   ├── Back.solidimagestacklayer
│   │   │   │   ├── Content.imageset
│   │   │   │   │   └── Contents.json
│   │   │   │   └── Contents.json
│   │   │   ├── Contents.json
│   │   │   ├── Front.solidimagestacklayer
│   │   │   │   ├── Content.imageset
│   │   │   │   │   └── Contents.json
│   │   │   │   └── Contents.json
│   │   │   └── Middle.solidimagestacklayer
│   │   │       ├── Content.imageset
│   │   │       │   └── Contents.json
│   │   │       └── Contents.json
│   │   └── Contents.json
│   ├── Info.plist
│   ├── Model
│   │   ├── AppModel.swift
│   │   └── GeoJSONDataDTO.swift
│   ├── Turkey.geojson
│   ├── ViewModels
│   │   └── TrSpatialAtlasViewModel.swift
│   └── Views
│       ├── ContentView.swift
│       ├── ImmersiveView.swift
│       └── ToggleImmersiveSpaceButton.swift
├── TR Spatial Atlas.xcodeproj
│   ├── project.pbxproj
│   ├── project.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   │   └── swiftpm
│   │   │       └── configuration
│   │   └── xcuserdata
│   │       └── durulmac2013.xcuserdatad
│   │           └── UserInterfaceState.xcuserstate
│   └── xcuserdata
│       └── durulmac2013.xcuserdatad
│           └── xcschemes
│               └── xcschememanagement.plist
└── TR Spatial AtlasTests
    └── TR_Spatial_AtlasTests.swift
```

## 🎮 Usage

1. **Launching the Application**: You will be welcomed with the title "🇹🇷 Türkiye Haritası".
2. **3D Mode**: Click the "Hide Turkey Map" button.
3. **Viewing**: Experience Turkey's 81 provinces as a colorful 3D map in a mixed reality environment.
4. **Closing**: Press the button again to return to normal mode.

## 🎨 Visual Features

### **Color Palette (10 Colors):**
- 🔵 **Turquoise** (systemTeal)
- 🟠 **Orange** (systemOrange)
- 🟣 **Purple** (systemPurple)
- 🟡 **Yellow** (systemYellow)
- 🩷 **Pink** (systemPink)
- 🟣 **Indigo** (systemIndigo)
- 🟤 **Brown** (systemBrown)
- 🩵 **Cyan** (systemCyan)
- 🟢 **Mint Green** (systemMint)
- 🔴 **Red** (systemRed)

Each province is displayed in one of these colors!

### **3D Features:**
- **Opacity**: 0.95 (high visibility)
- **MultiPolygon**: Islands and fragmented provinces are supported.
- **Smart Filtering**: Small islets are automatically filtered out.
- **Vertex Simplification**: Polygons with 255+ vertices are simplified.

## 💡 Use Cases

### **Education:**
- Geography lessons.
- Learning about provincial boundaries.
- 3D spatial computing education.

### **Tourism and Exploration:**
- General introduction to Turkey.
- Regional exploration.
- Virtual trip planning.

### **Technical Development:**
- Learning GeoJSON polygon rendering.
- RealityKit mesh creation.
- Solving winding order problems.
- Techniques for processing MultiPolygons.

## 🔧 Development Details

### **Coordinate Transformation:**
```swift
// Center of Turkey: Near Ankara
let center: SIMD2<Float> = [35.0, 39.0]
let scaleFactor: Float = 0.05

// Convert GeoJSON coordinates to 3D space
let x = (longitude - center.x) * scaleFactor
let z = (latitude - center.y) * scaleFactor
let y: Float = 0.001 // Ground level
```

### **CRITICAL: Winding Order Correction** ⚠️

**WINDING ORDER** issue! GeoJSON polygons are **clockwise**, but RealityKit wants **counter-clockwise**!

```swift
// Get vertices from GeoJSON
var vertices: [SIMD3<Float>] = []
for point in ring {
    vertices.append(SIMD3<Float>(x, y, z))
}

// IMPORTANT: Reverse the vertex order for RealityKit!
vertices.reverse()  // Clockwise → Counter-clockwise
```


### **3D Mesh Creation:**
```swift
// Create a polygon mesh descriptor
var meshDescriptor = MeshDescriptor()
meshDescriptor.positions = .init(vertices)
meshDescriptor.primitives = .polygons(counts, indices)

// Create the mesh and add materials
let mesh = try MeshResource.generate(from: [meshDescriptor])
var material = UnlitMaterial(color: provinceColor)
material.blending = .transparent(opacity: 0.95)

let entity = ModelEntity(mesh: mesh, materials: [material])
```

### **MultiPolygon Processing:**
```swift
// Each province can have multiple polygons (islands)
for polygonCoordinates in multiPolygonCoordinates {
// Get only the outer boundary
guard let outerRing = polygonCoordinates.first else { continue }

// Filter out small islands (largest 50%)

let keepCount = max(5, Int(Float(polygonData.count) * 0.5))

let significantPolygons = Array(polygonData.prefix(keepCount))
}
```

## 📊 Performance Optimizations

- ✅ **Single GeoJSON File**: 81 provinces in a single file (241KB)
- ✅ **Vertex Simplification**: 255+ vertices → simplification
- ✅ **Island Filtering**: Small islands are automatically discarded
- ✅ **Efficient Batching**: A group of entities per province
- ✅ **Optimized Scale**: `scaleFactor = 0.05` (optimal size)

## 🚀 Upcoming Enhancements

1. **🎯 Interactivity**: Click on provinces to display information
2. **📊 Data Layers**: Population, income, tourism data overlay
3. **🎨 Animation**: Dynamic elevation of provinces
4. **📱 Gesture Support**: Pinch-to-zoom, rotate
5. **🔊 Audio**: Voice information for each province
6. **🌐 API Integration**: Real-time data update

## 🛠️ Build and Run

```bash
# In the project directory
cd "/path/to/Day11_Turkiye"

# Build for VisionOS Simulator
xcodebuild -scheme Day11 -destination "platform=visionOS Simulator,name=Apple Vision Pro" build

# Run in Xcode
# Press Run in Xcode or open in Simulator
```

## ✅ Tested

- ✅ VisionOS 2.0 Simulator
- ✅ Apple Vision Pro Simulator
- ✅ 81 provinces successfully rendered
- ✅ Winding order issue resolved
- ✅ MultiPolygon support enabled
- ✅ Island filtering working

## 🎖️ Achievements

- 🏆 **Fixed a difficult rendering bug** (Winding Order)
- 🏆 **Rendered all 81 provinces** (325+ polygons)
- 🏆 **Optimized performance** (0.30 second load)
- 🏆 **Gained experience with spatial computing**

---


**Special Note:** The **Winding Order** issue encountered in this project is a common problem in 3D graphics programming. This solution can also be used in similar projects! 🎯
