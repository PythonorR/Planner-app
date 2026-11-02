import Foundation

/// English date/time strings (the UI is English even on a Korean-region phone),
/// using the device calendar and time zone.
enum Fmt {
    private static var cache: [String: DateFormatter] = [:]

    private static func formatter(_ template: String) -> DateFormatter {
        let f: DateFormatter
        if let cached = cache[template] {
            f = cached
        } else {
            f = DateFormatter()
            f.locale = Locale(identifier: "en_US")
            f.setLocalizedDateFormatFromTemplate(template)
            cache[template] = f
        }
        f.calendar = Calendar.current
        f.timeZone = TimeZone.current
        return f
    }

    /// "Nov 1"
    static func monthDay(_ d: Date) -> String { formatter("MMMd").string(from: d) }
    /// "Tue, Nov 3"
    static func weekdayMonthDay(_ d: Date) -> String { formatter("EEEMMMd").string(from: d) }
    /// "Sunday, November 1"
    static func fullDay(_ d: Date) -> String { formatter("EEEEMMMMd").string(from: d) }
    /// "SUN"
    static func weekdayShort(_ d: Date) -> String { formatter("EEE").string(from: d).uppercased() }
    /// "November"
    static func monthName(_ d: Date) -> String { formatter("MMMM").string(from: d) }
    /// "2026"
    static func year(_ d: Date) -> String { formatter("y").string(from: d) }
    /// "Nov 1 – Nov 10"
    static func range(_ a: Date, _ b: Date) -> String { "\(monthDay(a)) – \(monthDay(b))" }

    /// "5:00 PM", or "5 PM" when `compact` and on the hour.
    static func time(_ minutes: Int, compact: Bool = false) -> String {
        let h = (minutes / 60) % 24, m = minutes % 60
        let h12 = h % 12 == 0 ? 12 : h % 12
        let ap = h < 12 ? "AM" : "PM"
        if compact && m == 0 { return "\(h12) \(ap)" }
        return String(format: "%d:%02d %@", h12, m, ap)
    }

    /// "S M T W T F S", rotated to the locale's first weekday.
    static func weekdayInitials(cal: Calendar = .current) -> [String] {
        let symbols = formatter("EEE").veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }
}
