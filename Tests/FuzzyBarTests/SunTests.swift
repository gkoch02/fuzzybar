import XCTest
@testable import FuzzyBar

final class SunTests: XCTestCase {
    private func calendar(_ zone: String) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }

    /// Asserts sunrise and sunset as local clock times in `zone`, within
    /// `accuracy` seconds.
    private func assertSun(_ zone: String, _ lat: Double, _ lon: Double, _ y: Int, _ mo: Int, _ d: Int,
                           rise: (Int, Int), set: (Int, Int), accuracy: TimeInterval = 90,
                           file: StaticString = #filePath, line: UInt = #line) {
        let cal = calendar(zone)
        let noon = cal.date(from: DateComponents(year: y, month: mo, day: d, hour: 12))!
        guard case let .risesAndSets(sunrise, sunset) = Sun.day(containing: noon, latitude: lat, longitude: lon, calendar: cal) else {
            return XCTFail("expected a sunrise and a sunset", file: file, line: line)
        }
        let expectedRise = cal.date(from: DateComponents(year: y, month: mo, day: d, hour: rise.0, minute: rise.1))!
        let expectedSet = cal.date(from: DateComponents(year: y, month: mo, day: d, hour: set.0, minute: set.1))!
        XCTAssertEqual(sunrise.timeIntervalSince(expectedRise), 0, accuracy: accuracy, "sunrise", file: file, line: line)
        XCTAssertEqual(sunset.timeIntervalSince(expectedSet), 0, accuracy: accuracy, "sunset", file: file, line: line)
    }

    /// Expected times are LittleFuzzyClock's sun.py for the same inputs,
    /// so these pin the port rather than the (simplified) astronomy.
    func testMatchesLittleFuzzyClock() {
        assertSun("America/New_York", 40.7142, -74.0064, 2026, 9, 22, rise: (6, 42), set: (18, 55))
        assertSun("Europe/London", 51.5083, -0.1253, 2026, 6, 21, rise: (4, 42), set: (21, 21))
        assertSun("America/Los_Angeles", 34.0522, -118.2428, 2026, 12, 21, rise: (6, 54), set: (16, 47))
        // Tokyo's sunrise is on the previous UTC day; it must still land on the local date.
        assertSun("Asia/Tokyo", 35.6544, 139.7447, 2026, 1, 1, rise: (6, 50), set: (16, 37))
        assertSun("Australia/Sydney", -33.8667, 151.2167, 2026, 12, 21, rise: (5, 40), set: (20, 5))
    }

    /// And the astronomy is close enough: timeanddate.com has 6:43 and 6:53.
    func testAgreesWithPublishedTimes() {
        assertSun("America/New_York", 40.7142, -74.0064, 2026, 9, 22, rise: (6, 43), set: (18, 53), accuracy: 180)
    }

    /// Across spring-forward the same sun reads an hour later on the clock.
    func testDaylightSavingDays() {
        assertSun("America/New_York", 40.7142, -74.0064, 2026, 3, 7, rise: (6, 22), set: (17, 52))
        assertSun("America/New_York", 40.7142, -74.0064, 2026, 3, 8, rise: (7, 20), set: (18, 53))
    }

    /// Chatham, Kiribati, Samoa and Tonga keep a clock a day ahead of their
    /// longitude, so the local day's sun is the previous UTC day's. Chatham
    /// also springs forward on Sep 27, so the wrong day is an hour off.
    func testDateLineZonesGetTheirOwnDay() {
        for (zone, lat, lon) in [("Pacific/Chatham", -43.95, -176.55), ("Pacific/Kiritimati", 1.8667, -157.3333),
                                 ("Pacific/Apia", -13.8333, -171.7333), ("Pacific/Tongatapu", -21.1333, -175.2)] {
            let cal = calendar(zone)
            let noon = cal.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 12))!
            guard case let .risesAndSets(sunrise, sunset) = Sun.day(containing: noon, latitude: lat, longitude: lon, calendar: cal) else {
                XCTFail(zone); continue
            }
            XCTAssertTrue(cal.isDate(sunrise, inSameDayAs: noon), zone)
            XCTAssertTrue(cal.isDate(sunset, inSameDayAs: noon), zone)
            XCTAssertEqual(cal.component(.hour, from: sunrise), 6, zone)
        }
    }

    /// Every reference city, a solstice and an equinox apart: the day's sun
    /// is centred on the day asked for, whatever the zone's offset.
    func testEveryZoneGetsTheDayItAskedFor() {
        for (zone, location) in ZoneLocations.table {
            guard let tz = TimeZone(identifier: zone) else { continue }
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = tz
            for (month, day) in [(3, 20), (6, 21), (9, 22), (12, 21)] {
                let noon = cal.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
                if case let .risesAndSets(sunrise, sunset) = Sun.day(containing: noon, latitude: location.latitude,
                                                                   longitude: location.longitude, calendar: cal) {
                    XCTAssertLessThan(sunrise, sunset, zone)
                    let middle = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) / 2)
                    XCTAssertTrue(cal.isDate(middle, inSameDayAs: noon), "\(zone) \(month)/\(day)")
                }
            }
        }
    }

    func testPolarDayAndNight() {
        let cal = calendar("Europe/Oslo")
        func day(_ month: Int) -> Sun.Day {
            Sun.day(containing: cal.date(from: DateComponents(year: 2026, month: month, day: 21, hour: 12))!,
                    latitude: 69.6496, longitude: 18.9560, calendar: cal)  // Tromsø
        }
        XCTAssertEqual(day(6), .alwaysUp)
        XCTAssertEqual(day(12), .alwaysDown)
    }

    /// Every named zone Foundation knows has a city; only fixed offsets
    /// (GMT, UTC) don't, and Preferences says so for those.
    func testEveryKnownZoneHasACity() {
        let missing = TimeZone.knownTimeZoneIdentifiers.filter {
            SunSettings.zoneLocation(TimeZone(identifier: $0)!) == nil
        }
        XCTAssertEqual(missing, ["GMT"])
        for (alias, zone) in ZoneLocations.aliases {
            XCTAssertNotNil(ZoneLocations.table[zone], alias)
        }
    }

    func testZoneLocationsAreOnTheGlobe() {
        XCTAssertGreaterThan(ZoneLocations.table.count, 400)
        for (zone, location) in ZoneLocations.table {
            XCTAssertTrue((-90...90).contains(location.latitude), zone)
            XCTAssertTrue((-180...180).contains(location.longitude), zone)
        }
    }

    func testTimeZoneGivesTheReferenceCity() {
        let ny = SunSettings.zoneLocation(TimeZone(identifier: "America/New_York")!)!
        XCTAssertEqual(ny.latitude, 40.7142, accuracy: 0.001)
        XCTAssertEqual(ny.longitude, -74.0064, accuracy: 0.001)
        XCTAssertEqual(SunSettings.cityName(TimeZone(identifier: "America/New_York")!), "New York")
        XCTAssertEqual(SunSettings.cityName(TimeZone(identifier: "America/Argentina/Buenos_Aires")!), "Buenos Aires")
        // Old and merged names find their city, the one tzdb means rather
        // than whichever zone happens to share its rules.
        for (alias, city) in [("Asia/Calcutta", "Kolkata"), ("US/Eastern", "New York"), ("America/Montreal", "Toronto"),
                              ("Australia/Canberra", "Sydney"), ("Iceland", "Reykjavik"), ("Pacific/Enderbury", "Kanton")] {
            let tz = TimeZone(identifier: alias)!
            XCTAssertEqual(tz.identifier, alias, "Foundation keeps the name as given")
            XCTAssertNotNil(SunSettings.zoneLocation(tz), alias)
            XCTAssertEqual(SunSettings.cityName(tz), city)
        }
        // Fixed offsets have no city.
        XCTAssertNil(SunSettings.zoneLocation(TimeZone(identifier: "UTC")!))
        XCTAssertNil(SunSettings.zoneLocation(TimeZone(secondsFromGMT: 3600)!))
    }

    @MainActor
    func testSettingsPersistAndChooseTheLocation() {
        let suite = "FuzzyBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let ny = TimeZone(identifier: "America/New_York")!

        let settings = SunSettings(defaults: defaults)
        XCTAssertTrue(settings.isShown)
        XCTAssertFalse(settings.usesCustomLocation)
        XCTAssertEqual(settings.location(in: ny)?.latitude, 40.7142)

        settings.usesCustomLocation = true
        XCTAssertNil(settings.location(in: ny), "custom with nothing typed has no location")
        settings.latitude = 42.36
        XCTAssertNil(settings.location(in: ny), "one coordinate is not enough")
        settings.longitude = -71.06
        XCTAssertEqual(settings.location(in: ny)?.longitude, -71.06)
        settings.latitude = 91
        XCTAssertNil(settings.location(in: ny), "off the globe")
        settings.latitude = 42.36
        settings.isShown = false

        let reloaded = SunSettings(defaults: defaults)
        XCTAssertFalse(reloaded.isShown)
        XCTAssertTrue(reloaded.usesCustomLocation)
        XCTAssertEqual(reloaded.latitude, 42.36)
        XCTAssertEqual(reloaded.longitude, -71.06)

        reloaded.latitude = nil
        XCTAssertNil(defaults.object(forKey: SunSettings.latitudeKey))
    }
}
