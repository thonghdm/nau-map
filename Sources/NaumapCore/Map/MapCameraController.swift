import Foundation

public enum MapCameraMode: String, Codable, Sendable {
    case courseUp3D
    case northUp2D
}

public struct MapCameraState: Hashable, Codable, Sendable {
    public let center: Coordinate
    public let zoomLevel: Double
    public let bearingDegrees: Double
    public let pitchDegrees: Double
    public let mode: MapCameraMode

    public init(
        center: Coordinate,
        zoomLevel: Double,
        bearingDegrees: Double,
        pitchDegrees: Double,
        mode: MapCameraMode
    ) {
        self.center = center
        self.zoomLevel = zoomLevel
        self.bearingDegrees = MapCameraController.normalize(bearingDegrees)
        self.pitchDegrees = min(60.0, max(0.0, pitchDegrees))
        self.mode = mode
    }
}

public struct MapCameraController: Sendable {
    public let navigationZoomLevel: Double
    public let overviewZoomLevel: Double

    public init(navigationZoomLevel: Double = 16.0, overviewZoomLevel: Double = 11.0) {
        self.navigationZoomLevel = navigationZoomLevel
        self.overviewZoomLevel = overviewZoomLevel
    }

    public func navigationCamera(for location: Coordinate) -> MapCameraState {
        MapCameraState(
            center: location,
            zoomLevel: navigationZoomLevel,
            bearingDegrees: location.bearing ?? 0.0,
            pitchDegrees: 45.0,
            mode: .courseUp3D
        )
    }

    public func overviewCamera(for location: Coordinate) -> MapCameraState {
        MapCameraState(
            center: location,
            zoomLevel: overviewZoomLevel,
            bearingDegrees: 0.0,
            pitchDegrees: 0.0,
            mode: .northUp2D
        )
    }

    public static func normalize(_ bearing: Double) -> Double {
        let normalized = bearing.truncatingRemainder(dividingBy: 360.0)
        return normalized >= 0.0 ? normalized : normalized + 360.0
    }
}
