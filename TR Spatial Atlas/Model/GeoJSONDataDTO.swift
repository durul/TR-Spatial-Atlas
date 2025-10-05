//
//  GeoJSONDataDTO.swift
//  TR Spatial Atlas
//
//  Created by durul dalkanat on 10/5/25.
//

import Foundation

public struct Constants {
    // Türkiye koordinat merkezi (longitude, latitude) - Ankara yakını
    let center: SIMD2<Float> = [35.0, 39.0]

    // Türkiye için ölçekleme faktörü - görünür boyut
    let scaleFactor: Float = 0.05 // KÜÇÜK - görüş alanına sığsın

    let mapDataFiles = [
        "Turkey"
    ]
}

// Yeni GeoJSON veri yapısı
struct GeoJSONData: Codable {
    let type: String
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Codable {
    let type: String
    let properties: Properties?
    let geometry: GeoJSONGeometry
}

struct Properties: Codable {
    let name: String?
    let number: Int?
}

struct GeoJSONGeometry: Codable {
    let type: String
    let coordinates: GeoJSONCoordinates

    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        // Geometry tipine göre coordinates'i decode et
        switch type {
        case "Point":
            let coords = try container.decode([Double].self, forKey: .coordinates)
            coordinates = .point(coords)
        case "LineString":
            let coords = try container.decode([[Double]].self, forKey: .coordinates)
            coordinates = .lineString(coords)
        case "Polygon":
            let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
            coordinates = .polygon(coords)
        case "MultiPolygon":
            let coords = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            coordinates = .multiPolygon(coords)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Unknown geometry type: \(type)")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        switch coordinates {
        case .point(let coords):
            try container.encode(coords, forKey: .coordinates)
        case .lineString(let coords):
            try container.encode(coords, forKey: .coordinates)
        case .polygon(let coords):
            try container.encode(coords, forKey: .coordinates)
        case .multiPolygon(let coords):
            try container.encode(coords, forKey: .coordinates)
        }
    }
}

enum GeoJSONCoordinates: Codable {
    case point([Double])
    case lineString([[Double]])
    case polygon([[[Double]]])
    case multiPolygon([[[[Double]]]])

    var coordinates: Any {
        switch self {
        case .point(let coords):
            return coords
        case .lineString(let coords):
            return coords
        case .polygon(let coords):
            return coords
        case .multiPolygon(let coords):
            return coords
        }
    }
}
