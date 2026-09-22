import SwiftUI

/// Today's sunrise and sunset in the popover, in spoken fuzzy time: the
/// location is a guess from the time zone, so minutes would be false precision.
struct SunView: View {
    let now: Date
    @ObservedObject var settings: SunSettings

    var body: some View {
        if settings.isShown, let location = settings.location() {
            VStack(alignment: .leading, spacing: 3) {
                switch Sun.day(containing: now, latitude: location.latitude, longitude: location.longitude) {
                case let .risesAndSets(sunrise, sunset):
                    Label("Sunrise around \(FuzzyTime.phrase(for: sunrise))", systemImage: "sunrise")
                    Label("Sunset around \(FuzzyTime.phrase(for: sunset))", systemImage: "sunset")
                case .alwaysUp:
                    Label("The sun doesn't set today", systemImage: "sun.max")
                case .alwaysDown:
                    Label("The sun doesn't rise today", systemImage: "moon.stars")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }
}
