import Foundation

/// Sunrise and sunset from NOAA's simplified solar-position equations, ported
/// from LittleFuzzyClock's sun.py. Good to about a minute outside the polar
/// regions, which is far finer than the location FuzzyBar has to go on.
enum Sun {
    enum Day: Equatable {
        case risesAndSets(sunrise: Date, sunset: Date)
        /// Midnight sun: the sun never goes below the horizon that day.
        case alwaysUp
        /// Polar night: the sun never comes above it.
        case alwaysDown
    }

    /// Sunrise and sunset on the calendar day containing `date`.
    static func day(containing date: Date, latitude: Double, longitude: Double,
                    calendar: Calendar = .current) -> Day {
        // The equations work in minutes after UTC midnight of the calendar
        // date; the local date picks which day, the UTC one anchors the sums.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let base = utc.date(from: calendar.dateComponents([.year, .month, .day], from: date))!
        let n = Double(utc.ordinality(of: .day, in: .year, for: base)!)

        let gamma = 2 * Double.pi / 365 * (n - 1)
        let eqtime = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma) - 0.040849 * sin(2 * gamma))
        let decl = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma) + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma) + 0.00148 * sin(3 * gamma)

        let lat = latitude * .pi / 180
        // 90.833 degrees allows for refraction and the sun's apparent radius.
        let cosH = cos(90.833 * .pi / 180) / (cos(lat) * cos(decl)) - tan(lat) * tan(decl)
        if cosH < -1 { return .alwaysUp }
        if cosH > 1 { return .alwaysDown }
        let h = acos(cosH) * 180 / .pi

        let sunrise = 720 - 4 * (longitude + h) - eqtime
        let sunset = 720 - 4 * (longitude - h) - eqtime
        return .risesAndSets(sunrise: base.addingTimeInterval(sunrise * 60),
                             sunset: base.addingTimeInterval(sunset * 60))
    }
}
