import Foundation

/// Parses schema.org's ISO 8601 duration strings (e.g. "PT1H30M", "PT45M")
/// into whole minutes. Recipe sites use this format for prepTime/cookTime/totalTime.
enum ISO8601DurationParser {
    static func minutes(from duration: String?) -> Int {
        guard let duration, duration.hasPrefix("P") else { return 0 }

        var hours = 0
        var minutes = 0
        var days = 0

        let timePart = duration.split(separator: "T")
        let datePart = timePart[0].dropFirst() // drop leading "P"

        if let daysMatch = datePart.range(of: #"(\d+)D"#, options: .regularExpression) {
            days = Int(datePart[daysMatch].dropLast()) ?? 0
        }

        if timePart.count > 1 {
            let time = timePart[1]
            if let hourMatch = time.range(of: #"(\d+)H"#, options: .regularExpression) {
                hours = Int(time[hourMatch].dropLast()) ?? 0
            }
            if let minuteMatch = time.range(of: #"(\d+)M"#, options: .regularExpression) {
                minutes = Int(time[minuteMatch].dropLast()) ?? 0
            }
        }

        return days * 24 * 60 + hours * 60 + minutes
    }

    static func label(fromMinutes totalMinutes: Int) -> String {
        guard totalMinutes > 0 else { return "" }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, let m): return "\(m) min"
        case (let h, 0): return "\(h) hr"
        default: return "\(hours) hr \(minutes) min"
        }
    }
}
