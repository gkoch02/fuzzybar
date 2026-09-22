import Combine
import Foundation

/// Where sunrise and sunset are worked out for. FuzzyBar has no location
/// access, so by default it uses the reference city of the Mac's time zone
/// (New York for America/New_York), which is close enough for a fuzzy clock.
/// Anyone who wants better can type in coordinates.
@MainActor
final class SunSettings: ObservableObject {
    static let shownKey = "sunShown"
    static let customKey = "sunUseCustomLocation"
    static let latitudeKey = "sunLatitude"
    static let longitudeKey = "sunLongitude"

    @Published var isShown: Bool { didSet { defaults.set(isShown, forKey: Self.shownKey) } }
    @Published var usesCustomLocation: Bool { didSet { defaults.set(usesCustomLocation, forKey: Self.customKey) } }
    @Published var latitude: Double? { didSet { store(latitude, forKey: Self.latitudeKey) } }
    @Published var longitude: Double? { didSet { store(longitude, forKey: Self.longitudeKey) } }
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isShown = defaults.object(forKey: Self.shownKey) as? Bool ?? true
        usesCustomLocation = defaults.bool(forKey: Self.customKey)
        latitude = defaults.object(forKey: Self.latitudeKey) as? Double
        longitude = defaults.object(forKey: Self.longitudeKey) as? Double
    }

    private func store(_ value: Double?, forKey key: String) {
        if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
    }

    /// Typed-in coordinates, if both are present and on the globe.
    var customLocation: (latitude: Double, longitude: Double)? {
        guard let latitude, let longitude, (-90...90).contains(latitude),
              (-180...180).contains(longitude) else { return nil }
        return (latitude, longitude)
    }

    /// The location to use, or `nil` when there is none: custom coordinates
    /// that are missing or off the globe, or a time zone with no city.
    func location(in timeZone: TimeZone = .current) -> (latitude: Double, longitude: Double)? {
        usesCustomLocation ? customLocation : Self.zoneLocation(timeZone)
    }

    /// Older spellings some systems still report; zone.tab has only the new.
    private nonisolated static let renamedZones = [
        "Asia/Calcutta": "Asia/Kolkata", "Asia/Saigon": "Asia/Ho_Chi_Minh",
        "Asia/Katmandu": "Asia/Kathmandu", "Asia/Rangoon": "Asia/Yangon",
        "Europe/Kiev": "Europe/Kyiv", "America/Buenos_Aires": "America/Argentina/Buenos_Aires",
        "Atlantic/Faeroe": "Atlantic/Faroe", "Pacific/Truk": "Pacific/Chuuk",
        "Pacific/Ponape": "Pacific/Pohnpei", "America/Godthab": "America/Nuuk",
    ]

    nonisolated static func zoneLocation(_ timeZone: TimeZone) -> (latitude: Double, longitude: Double)? {
        let id = renamedZones[timeZone.identifier] ?? timeZone.identifier
        return ZoneLocations.table[id]
    }

    /// "New York" for America/New_York, "Buenos Aires" for America/Argentina/Buenos_Aires.
    nonisolated static func cityName(_ timeZone: TimeZone) -> String {
        let id = renamedZones[timeZone.identifier] ?? timeZone.identifier
        return (id.split(separator: "/").last.map(String.init) ?? id).replacingOccurrences(of: "_", with: " ")
    }
}
