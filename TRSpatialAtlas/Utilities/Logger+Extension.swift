import OSLog

extension Logger {
    /// Using the bundle identifier for the subsystem ensures logs are easily filterable in Console.app
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.trspatialatlas"

    /// Logs related to Map Data processing (GeoJSON, Parsing, etc.)
    static let mapData = Logger(subsystem: subsystem, category: "MapData")

    /// Logs related to 3D Content generation (RealityKit entities, Mesh generation)
    static let contentGeneration = Logger(subsystem: subsystem, category: "ContentGeneration")

    /// Logs related to Performance measurements
    static let performance = Logger(subsystem: subsystem, category: "Performance")

    /// General UI logs
    static let ui = Logger(subsystem: subsystem, category: "UI")

    /// Logs related to AR Session and Tracking
    static let session = Logger(subsystem: subsystem, category: "Session")
}
