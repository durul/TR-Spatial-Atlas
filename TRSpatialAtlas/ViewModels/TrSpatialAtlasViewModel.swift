import Observation
import RealityKit
import SwiftUI

@Observable
class TrSpatialAtlasViewModel {
    // MARK: - Properties

    let contentEntity = Entity() // Made public for gesture access
    private let constants = Constants()
    private let decoder = JSONDecoder()
    
    // MARK: Loading state

    var isLoading = false
    var loadingProgress = ""
    
    // MARK: Color palette for 81 provinces

    private let provinceColors: [UIColor] = {
        var colors: [UIColor] = []
        
        // Use HSB (Hue, Saturation, Brightness) to generate 81 different colors
        for i in 0..<81 {
            let hue = CGFloat(i) / 81.0 // Color spectrum between 0.0 - 1.0
            let saturation: CGFloat = 0.7 + (CGFloat(i % 3) * 0.1) // Variation between 0.7, 0.8, 0.9
            let brightness: CGFloat = 0.6 + (CGFloat(i % 4) * 0.1) // Variation between 0.6 - 0.9
            
            let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
            colors.append(color)
        }
        
        return colors
    }()

    // MARK: - Setup Entity

    func setupContentEntity() -> Entity {
        // Lay the map flat (rotate 90° around X axis - parallel to ground)
        let xRotation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        contentEntity.transform.rotation = xRotation
        
        // SCALE UP the map - for better visibility
        contentEntity.scale = [1.5, 0.5, 1.5]

        // Add InputTarget + Collision for gesture interaction
        // These are REQUIRED for DragGesture and MagnifyGesture to work
        contentEntity.components.set(InputTargetComponent())
        contentEntity.components.set(CollisionComponent(shapes: [
            .generateBox(width: 3.0, height: 0.1, depth: 3.0)
        ]))
        
        return contentEntity
    }

    // MARK: - Data Handling

    func makePolygon() {
        isLoading = true
        loadingProgress = "Loading GeoJSON data..."
        
        // Parsing Turkey.geojson
        constants.mapDataFiles.forEach { fileName in
            loadGeoJSONData(fileName: fileName)
        }
        
        isLoading = false
        loadingProgress = "Complete ✅"
    }

    private func loadGeoJSONData(fileName: String) {
        loadingProgress = "Processing \(fileName) file..."
        
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "geojson") else {
            print("GeoJSON file not found: \(fileName)")
            return
        }

        do {
            let jsonData = try Data(contentsOf: fileUrl)
            print("📂 JSON data loaded: \(jsonData.count) bytes")
            
            let geoJSON = try decoder.decode(GeoJSONData.self, from: jsonData)
            print("✅ GeoJSON decoded successfully!")
            print("📊 Total features: \(geoJSON.features.count)")
            
            loadingProgress = "Creating 3D models..."
            processFeatures(geoJSON.features)
        } catch {
            print("❌ Error loading GeoJSON: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
            loadingProgress = "Error: \(error.localizedDescription)"
        }
    }
    
    // MARK: (Distribution Center / Dispatcher)
    
    // It analyzes the raw data stream coming from GeoJSON.
    private func processFeatures(_ features: [GeoJSONFeature]) {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("Processing \(features.count) features...")
        
        var processedCount = 0
        var skippedCount = 0
        //
        // // DEBUG: Show only KONYA
        // let testFeatures = features.filter { $0.properties?.name == "Konya" }
        // print("🔍 DEBUG: Testing with \(testFeatures.count) feature(s)")

        for (index, feature) in features.enumerated() {
            switch feature.geometry.type {
            case "Point":
                createPointMarker(feature: feature, index: index)
                processedCount += 1
            case "LineString":
                createLineString(feature: feature, index: index)
                processedCount += 1
            case "Polygon":
                createPolygon(feature: feature, index: index)
                processedCount += 1
            case "MultiPolygon":
                createMultiPolygon(feature: feature, index: index)
                processedCount += 1
            default:
                print("Skipping unsupported geometry type: \(feature.geometry.type)")
                skippedCount += 1
            }
        }
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("✅ Processing complete!")
        print("   Processed: \(processedCount) features")
        print("   Skipped: \(skippedCount) features")
        print("   Total entities: \(contentEntity.children.count)")
        print("   Processing time: \(String(format: "%.2f", processingTime)) seconds")
    }
    
    // MARK: - Geometry Builders

    // That function ensures only works with valid "Point" data.
    // NOTE: This function is kept for future scalability.
    // It will be used to visualize point-based data such as:
    // - Earthquake epicenters
    // - City capitals
    // - Specific POIs like bus stops or stores
    private func createPointMarker(feature: GeoJSONFeature, index: Int) {
        // Checks the valid "Point" data.
        // If coordinate data is missing or does not contain latitude/longitude (at least 2 values), the function stops executing (returns).
        guard case .point(let coordinates) = feature.geometry.coordinates,
              coordinates.count >= 2 else { return }
        
        // In the GeoJSON format, the first value is usually Longitude, and the second value is Latitude.
        let longitude = Float(coordinates[0])
        let latitude = Float(coordinates[1])
        
        // Convert coordinates to 3D space
        let x = (longitude - constants.center.x) * constants.scaleFactor
        let z = (latitude - constants.center.y) * constants.scaleFactor
        let y: Float = 0.01 // Height for point
        
        // Create sphere (larger size)
        let sphere = MeshResource.generateSphere(radius: 0.08)
        var material = UnlitMaterial(color: .red)
        material.blending = .transparent(opacity: 0.9)
        
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        sphereEntity.position = SIMD3<Float>(x, y, z)
        
        contentEntity.addChild(sphereEntity)
    }
    
    // NOTE: This function is currently unused with the Turkey.geojson file but is kept for future features.
    // It will be used to visualize line-based geometries such as:
    // - Province borders (Distinct boundary lines)
    // - Roads / Highways (Yollar / Otoyollar)
    // - Rivers (Nehirler / Akarsu yatakları)
    // - Routes (e.g., Flight paths or navigation)
    private func createLineString(feature: GeoJSONFeature, index: Int) {
        guard case .lineString(let coordinates) = feature.geometry.coordinates else { return }
        
        var vertices: [SIMD3<Float>] = []
        
        for (_, point) in coordinates.enumerated() {
            guard point.count >= 2 else { continue }
            
            let longitude = Float(point[0])
            let latitude = Float(point[1])
            
            // Convert coordinates to 3D space
            let x = (longitude - constants.center.x) * constants.scaleFactor
            let z = (latitude - constants.center.y) * constants.scaleFactor
            let y: Float = 0.002 // Slightly higher for province borders
            
            vertices.append(SIMD3<Float>(x, y, z))
        }
        
        guard vertices.count >= 2 else { return }
        
        // Cylinder-based approach for LineString - THICKER FOR PROVINCE BORDERS
        for i in 0..<(vertices.count - 1) {
            let start = vertices[i]
            let end = vertices[i + 1]
            
            let direction = end - start
            let distance = length(direction)
            let center = (start + end) / 2
            
            // Create cylinder (THICKER AND MORE VISIBLE FOR PROVINCE BORDERS)
            let cylinder = MeshResource.generateCylinder(height: distance, radius: 0.005)
            var material = UnlitMaterial(color: .systemBlue) // Blue color - more prominent
            material.blending = .transparent(opacity: 1.0) // Fully opaque
            
            let cylinderEntity = ModelEntity(mesh: cylinder, materials: [material])
            cylinderEntity.position = center
            
            // Calculate rotation
            let normalizedDirection = normalize(direction)
            let upVector = SIMD3<Float>(0, 1, 0)
            let angle = acos(dot(upVector, normalizedDirection))
            let axis = cross(upVector, normalizedDirection)
            
            if length(axis) > 0.001 {
                cylinderEntity.transform.rotation = simd_quatf(angle: angle, axis: normalize(axis))
            }
            
            contentEntity.addChild(cylinderEntity)
        }
    }
    
    // MARK: Multiple polygons for island/fragmented provinces

    private func createMultiPolygon(feature: GeoJSONFeature, index: Int) {
        guard case .multiPolygon(let multiPolygonCoordinates) = feature.geometry.coordinates else { return }
        
        let provinceName = feature.properties?.name ?? "Unknown"
        print("Creating MultiPolygon for \(provinceName) with \(multiPolygonCoordinates.count) polygons")
        
        // Different colors for 81 provinces
        let color = provinceColors[index % provinceColors.count]
        
        // Add each polygon as SEPARATE entity - filter out small islands
        let provinceGroup = Entity()
        provinceGroup.name = provinceName
        
        // Sort polygons by size - take the largest ones
        var polygonData: [(vertices: [SIMD3<Float>], area: Float)] = []
        
        // Small Y offset per province to prevent z-fighting at boundaries
        let yOffset: Float = 0.001 + Float(index) * 0.0001
        
        for polygonCoordinates in multiPolygonCoordinates {
            guard let outerRing = polygonCoordinates.first else { continue }
            
            var vertices: [SIMD3<Float>] = []
            for point in outerRing {
                guard point.count >= 2 else { continue }
                let longitude = Float(point[0])
                let latitude = Float(point[1])
                let x = (longitude - constants.center.x) * constants.scaleFactor
                let z = (latitude - constants.center.y) * constants.scaleFactor
                let y: Float = yOffset
                vertices.append(SIMD3<Float>(x, y, z))
            }
            
            // REVERSE: GeoJSON clockwise -> RealityKit counter-clockwise
            vertices.reverse()
            
            guard vertices.count >= 3 else { continue }
            
            // Yaklaşık alan hesapla (vertex sayısı ile)
            let area = Float(vertices.count)
            polygonData.append((vertices: vertices, area: area))
        }
        
        // Sort from largest to smallest
        polygonData.sort { $0.area > $1.area }
        
        // Take only significant polygons (filter out small islets)
        let keepCount = max(5, Int(Float(polygonData.count) * 0.5))
        let significantPolygons = Array(polygonData.prefix(keepCount))
        
        var polygonCount = 0
        for data in significantPolygons {
            let vertices = data.vertices
            
            if vertices.count > 255 {
                createSubdividedPolygon(vertices: vertices, color: color)
                polygonCount += 1
                continue
            }
            
            let counts: [UInt8] = [UInt8(vertices.count)]
            var indices: [UInt32] = []
            for i in 0..<vertices.count {
                indices.append(UInt32(i))
            }
            
            var meshDescriptor = MeshDescriptor()
            meshDescriptor.positions = .init(vertices)
            meshDescriptor.primitives = .polygons(counts, indices)
            
            do {
                let polygonMesh = try MeshResource.generate(from: [meshDescriptor])
                var material = UnlitMaterial(color: color)
                material.blending = .transparent(opacity: 0.95) // More opaque
                
                let polygonEntity = ModelEntity(mesh: polygonMesh, materials: [material])
                provinceGroup.addChild(polygonEntity)
                polygonCount += 1
            } catch {
                print("Error creating polygon part: \(error)")
            }
        }
        
        contentEntity.addChild(provinceGroup)
        print("✓ Created \(provinceName) with \(polygonCount)/\(multiPolygonCoordinates.count) significant polygons")
    }
    
    // MARK: Creates a single province Entity

    // It creates a single province or region (e.g., Ankara) as a 3D model (Entity).
    private func createPolygon(feature: GeoJSONFeature, index: Int) {
        guard case .polygon(let coordinates) = feature.geometry.coordinates else { return }
        
        let provinceName = feature.properties?.name ?? "Unknown"
        print("Creating Polygon for \(provinceName)")
        
        // Different colors for 81 provinces
        let color = provinceColors[index % provinceColors.count]
        
        // Combine all rings - create single mesh
        var allVertices: [SIMD3<Float>] = []
        var allCounts: [UInt8] = []
        var allIndices: [UInt32] = []
        let currentIndexOffset: UInt32 = 0
        
        // Small Y offset per province to prevent z-fighting at boundaries
        let yOffset: Float = 0.001 + Float(index) * 0.0001
        
        // Take only OUTER BOUNDARY (first ring), skip inner holes
        guard let outerRing = coordinates.first else { return }
        
        // MARK: Coordinate Transformation
        
        // Converts latitude/longitude data into X/Z coordinates in a 3D world.
        var vertices: [SIMD3<Float>] = []
        for point in outerRing {
            guard point.count >= 2 else { continue }
            let longitude = Float(point[0])
            let latitude = Float(point[1])
            let x = (longitude - constants.center.x) * constants.scaleFactor
            let z = (latitude - constants.center.y) * constants.scaleFactor
            let y: Float = yOffset
            vertices.append(SIMD3<Float>(x, y, z))
        }
        
        // REVERSE: GeoJSON clockwise -> RealityKit counter-clockwise
        vertices.reverse()
        
        guard vertices.count >= 3 else {
            print("Skipping \(provinceName): too few vertices")
            return
        }
        
        // Split large polygons into parts
        if vertices.count > 255 {
            print("Subdividing polygon for \(provinceName) with \(vertices.count) vertices")
            createSubdividedPolygon(vertices: vertices, color: color)
            return
        }
        
        allCounts.append(UInt8(vertices.count))
        for i in 0..<vertices.count {
            allIndices.append(currentIndexOffset + UInt32(i))
        }
        allVertices.append(contentsOf: vertices)
        
        // Create single mesh
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(allVertices)
        meshDescriptor.primitives = .polygons(allCounts, allIndices)
        
        do {
            let provinceMesh = try MeshResource.generate(from: [meshDescriptor])
            var material = UnlitMaterial(color: color)
            material.blending = .transparent(opacity: 0.95) // More opaque
            
            let provinceEntity = ModelEntity(mesh: provinceMesh, materials: [material])
            provinceEntity.name = provinceName
            contentEntity.addChild(provinceEntity)
            
            print("✓ Created unified mesh for \(provinceName)")
        } catch {
            print("Error creating polygon for \(provinceName): \(error)")
        }
    }
    
    // MARK: - Helpers

    // Simplify large polygons to reduce vertex count
    // It is the most critical performance function. It manages the Vertex Limit, which is a constraint of RealityKit and Vision Pro.
    // If a province's borders are too detailed (e.g., Muğla coasts, thousands of points), this function kicks in.
    // Downsampling: It reduces the number of points (e.g., takes 1 out of every 3 points).
    // This prevents the application from crashing and prevents FPS (frame rate) drops.
    private func createSubdividedPolygon(vertices: [SIMD3<Float>], color: UIColor) {
        guard vertices.count >= 3 else { return }
        
        // Calculate simplification factor to bring vertex count below 255
        let targetVertexCount = 200 // Safe target (below 255)
        let step = Int(ceil(Double(vertices.count) / Double(targetVertexCount)))
        
        var simplifiedVertices: [SIMD3<Float>] = []
        
        // Take one point every 'step' points
        for i in stride(from: 0, to: vertices.count, by: step) {
            simplifiedVertices.append(vertices[i])
        }
        
        // Add last vertex to close the polygon
        if simplifiedVertices.count > 0, simplifiedVertices.first != vertices.first {
            simplifiedVertices.append(vertices.first!)
        }
        
        guard simplifiedVertices.count >= 3, simplifiedVertices.count <= 255 else {
            print("  Failed to simplify polygon: \(simplifiedVertices.count) vertices (step: \(step))")
            return
        }
        
        print("  ✓ Simplified from \(vertices.count) to \(simplifiedVertices.count) vertices (step: \(step))")
        
        let counts: [UInt8] = [UInt8(simplifiedVertices.count)]
        var indices: [UInt32] = []
        for i in 0..<simplifiedVertices.count {
            indices.append(UInt32(i))
        }
        
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(simplifiedVertices)
        meshDescriptor.primitives = .polygons(counts, indices)
        
        do {
            let polygonMesh = try MeshResource.generate(from: [meshDescriptor])
            var material = UnlitMaterial(color: color)
            material.blending = .transparent(opacity: 0.9)
            
            let polygonEntity = ModelEntity(mesh: polygonMesh, materials: [material])
            contentEntity.addChild(polygonEntity)
        } catch {
            print("  Error creating simplified polygon: \(error)")
        }
    }
}
