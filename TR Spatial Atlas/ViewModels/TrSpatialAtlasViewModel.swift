import Observation
import RealityKit
import SwiftUI

@Observable
class TrSpatialAtlasViewModel {
    private let contentEntity = Entity()
    private let constants = Constants()
    private let decoder = JSONDecoder()
    
    // Loading state
    var isLoading = false
    var loadingProgress = ""

    func setupContentEntity() -> Entity {
        // Haritayı göz hizasında ve optimal mesafede konumlandır
        contentEntity.position = [0, 1.5, -2.5]
        
        // Haritayı düz yatır (X ekseni etrafında 90° - yere paralel yap)
        let xRotation = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        contentEntity.transform.rotation = xRotation
        
        // Haritayı BÜYÜT - daha iyi görmek için
        contentEntity.scale = [1.5, 1.5, 1.5]
        
        return contentEntity
    }

    func makePolygon() {
        isLoading = true
        loadingProgress = "GeoJSON verisi yükleniyor..."
        
        constants.mapDataFiles.forEach { fileName in
            loadGeoJSONData(fileName: fileName)
        }
        
        isLoading = false
        loadingProgress = "Tamamlandı ✅"
    }

    private func loadGeoJSONData(fileName: String) {
        loadingProgress = "\(fileName) dosyası işleniyor..."
        
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
            
            // İlk birkaç il ismini yazdır
            for (index, feature) in geoJSON.features.prefix(5).enumerated() {
                if let name = feature.properties?.name {
                    print("   [\(index)] \(name)")
                }
            }
            
            loadingProgress = "3D modeller oluşturuluyor..."
            processFeatures(geoJSON.features)
        } catch {
            print("❌ Error loading GeoJSON: \(error)")
            if let decodingError = error as? DecodingError {
                print("   Decoding error details: \(decodingError)")
            }
            loadingProgress = "Hata: \(error.localizedDescription)"
        }
    }
    
    private func processFeatures(_ features: [GeoJSONFeature]) {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("Processing \(features.count) features...")
        
        var processedCount = 0
        var skippedCount = 0
//
//        // DEBUG: Sadece KONYA'yı göster
//        let testFeatures = features.filter { $0.properties?.name == "Konya" }
//        print("🔍 DEBUG: Testing with \(testFeatures.count) feature(s)")
//
//        for (index, feature) in testFeatures.enumerated() {
//
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
    
    private func createPointMarker(feature: GeoJSONFeature, index: Int) {
        guard case .point(let coordinates) = feature.geometry.coordinates,
              coordinates.count >= 2 else { return }
        
        let longitude = Float(coordinates[0])
        let latitude = Float(coordinates[1])
        
        // Koordinatları 3D uzayına dönüştür
        let x = (longitude - constants.center.x) * constants.scaleFactor
        let z = (latitude - constants.center.y) * constants.scaleFactor
        let y: Float = 0.01 // Nokta için yükseklik
        
        // Küre oluştur (daha büyük boyut)
        let sphere = MeshResource.generateSphere(radius: 0.08)
        var material = UnlitMaterial(color: .red)
        material.blending = .transparent(opacity: 0.9)
        
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        sphereEntity.position = SIMD3<Float>(x, y, z)
        
        contentEntity.addChild(sphereEntity)
    }
    
    private func createLineString(feature: GeoJSONFeature, index: Int) {
        guard case .lineString(let coordinates) = feature.geometry.coordinates else { return }
        
        var vertices: [SIMD3<Float>] = []
        
        for (_, point) in coordinates.enumerated() {
            guard point.count >= 2 else { continue }
            
            let longitude = Float(point[0])
            let latitude = Float(point[1])
            
            // Koordinatları 3D uzayına dönüştür
            let x = (longitude - constants.center.x) * constants.scaleFactor
            let z = (latitude - constants.center.y) * constants.scaleFactor
            let y: Float = 0.002 // İl sınırları için biraz daha yüksek
            
            vertices.append(SIMD3<Float>(x, y, z))
        }
        
        guard vertices.count >= 2 else { return }
        
        // LineString için cylinder-based approach - İL SINIRLARI İÇİN DAHA KALIN
        for i in 0..<(vertices.count - 1) {
            let start = vertices[i]
            let end = vertices[i + 1]
            
            let direction = end - start
            let distance = length(direction)
            let center = (start + end) / 2
            
            // Cylinder oluştur (İL SINIRLARI İÇİN DAHA KALIN VE GÖRÜNÜR)
            let cylinder = MeshResource.generateCylinder(height: distance, radius: 0.005)
            var material = UnlitMaterial(color: .systemBlue) // Mavi renk - daha belirgin
            material.blending = .transparent(opacity: 1.0) // Tam opak
            
            let cylinderEntity = ModelEntity(mesh: cylinder, materials: [material])
            cylinderEntity.position = center
            
            // Rotasyon hesapla
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
    
    private func createMultiPolygon(feature: GeoJSONFeature, index: Int) {
        guard case .multiPolygon(let multiPolygonCoordinates) = feature.geometry.coordinates else { return }
        
        let provinceName = feature.properties?.name ?? "Unknown"
        print("Creating MultiPolygon for \(provinceName) with \(multiPolygonCoordinates.count) polygons")
        
        // RENK PALETİ
        let colors: [UIColor] = [
            .systemTeal, .systemOrange, .systemPurple, .systemYellow, .systemPink,
            .systemIndigo, .systemBrown, .systemCyan, .systemMint, .systemRed
        ]
        
        // Her İL için TEK BİR RENK
        let color = colors[index % colors.count]
        
        // Her polygon'u AYRI bir entity olarak ekle - küçük adaları filtrele
        let provinceGroup = Entity()
        provinceGroup.name = provinceName
        
        // Polygon'ları boyutlarına göre sırala - en büyükleri al
        var polygonData: [(vertices: [SIMD3<Float>], area: Float)] = []
        
        for polygonCoordinates in multiPolygonCoordinates {
            guard let outerRing = polygonCoordinates.first else { continue }
            
            var vertices: [SIMD3<Float>] = []
            for point in outerRing {
                guard point.count >= 2 else { continue }
                let longitude = Float(point[0])
                let latitude = Float(point[1])
                let x = (longitude - constants.center.x) * constants.scaleFactor
                let z = (latitude - constants.center.y) * constants.scaleFactor
                let y: Float = 0.001
                vertices.append(SIMD3<Float>(x, y, z))
            }
            
            // REVERSE: GeoJSON clockwise -> RealityKit counter-clockwise
            vertices.reverse()
            
            guard vertices.count >= 3 else { continue }
            
            // Yaklaşık alan hesapla (vertex sayısı ile)
            let area = Float(vertices.count)
            polygonData.append((vertices: vertices, area: area))
        }
        
        // Büyükten küçüğe sırala
        polygonData.sort { $0.area > $1.area }
        
        // Sadece önemli polygon'ları al (küçük adacıkları filtrele)
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
                material.blending = .transparent(opacity: 0.95) // Daha opak
                
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
    
    private func createPolygon(feature: GeoJSONFeature, index: Int) {
        guard case .polygon(let coordinates) = feature.geometry.coordinates else { return }
        
        let provinceName = feature.properties?.name ?? "Unknown"
        print("Creating Polygon for \(provinceName)")
        
        let polygonColors: [UIColor] = [
            .systemTeal, .systemOrange, .systemPurple, .systemYellow, .systemPink,
            .systemIndigo, .systemBrown, .systemCyan, .systemMint, .systemRed
        ]
        
        let color = polygonColors[index % polygonColors.count]
        
        // Tüm ring'leri birleştir - tek mesh yap
        var allVertices: [SIMD3<Float>] = []
        var allCounts: [UInt8] = []
        var allIndices: [UInt32] = []
        var currentIndexOffset: UInt32 = 0
        
        // Sadece DIŞ SINIRI al (ilk ring), iç delikleri atla
        guard let outerRing = coordinates.first else { return }
        
        var vertices: [SIMD3<Float>] = []
        for point in outerRing {
            guard point.count >= 2 else { continue }
            let longitude = Float(point[0])
            let latitude = Float(point[1])
            let x = (longitude - constants.center.x) * constants.scaleFactor
            let z = (latitude - constants.center.y) * constants.scaleFactor
            let y: Float = 0.001
            vertices.append(SIMD3<Float>(x, y, z))
        }
        
        // REVERSE: GeoJSON clockwise -> RealityKit counter-clockwise
        vertices.reverse()
        
        guard vertices.count >= 3 else {
            print("Skipping \(provinceName): too few vertices")
            return
        }
        
        // Büyük poligonları parçalara böl
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
        
        // Tek mesh oluştur
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(allVertices)
        meshDescriptor.primitives = .polygons(allCounts, allIndices)
        
        do {
            let provinceMesh = try MeshResource.generate(from: [meshDescriptor])
            var material = UnlitMaterial(color: color)
            material.blending = .transparent(opacity: 0.95) // Daha opak
            
            let provinceEntity = ModelEntity(mesh: provinceMesh, materials: [material])
            provinceEntity.name = provinceName
            contentEntity.addChild(provinceEntity)
            
            print("✓ Created unified mesh for \(provinceName)")
        } catch {
            print("Error creating polygon for \(provinceName): \(error)")
        }
    }
    
    // Büyük poligonları sadeleştirerek vertex sayısını azalt
    private func createSubdividedPolygon(vertices: [SIMD3<Float>], color: UIColor) {
        guard vertices.count >= 3 else { return }
        
        // Vertex sayısını 255'in altına düşürmek için sadeleştirme faktörü hesapla
        let targetVertexCount = 200 // Güvenli bir hedef (255'in altında)
        let step = Int(ceil(Double(vertices.count) / Double(targetVertexCount)))
        
        var simplifiedVertices: [SIMD3<Float>] = []
        
        // Her 'step' noktada bir al
        for i in stride(from: 0, to: vertices.count, by: step) {
            simplifiedVertices.append(vertices[i])
        }
        
        // Poligonu kapatmak için son vertex'i ekle
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
