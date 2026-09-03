import Foundation

enum ISODate {
    static func parse(_ string: String?) -> Date? {
        guard let string else { return nil }
        if let d = try? Date(string, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true)) {
            return d
        }
        return try? Date(string, strategy: .iso8601)
    }
}
