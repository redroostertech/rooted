import Foundation

//  MARK:- Custom date formats
enum CustomDateFormat: String {
    case normal = "MMMM dd YYYY"
    case abbr = "MMM d YY"
    case fullMonthDay = "MMMM dd"
    case abbrMonthDay = "MMM dd"
    case fullMonthYear = "MMMM YYYY"
    case abbrMonthYear = "MMM YY"
    case month = "MMMM"
    case abbrMonth = "MMM"
    case timeDate = "yyyy-MM-dd'T'HH:mm:ssZ"
    case regular = "yyyy-MM-dd hh:mm a"
    case rooted = "MMMM d YYYY @ h:mm a"
}

//  MARK:- Initializers
extension Date {
    public init?(day: Int, month: Int, year: Int) {
        guard let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        self.init(timeIntervalSince1970: date.timeIntervalSince1970)
    }
}

//  MARK:- Calculations
extension Date {
  public func retrieveNextInterval(interval: Int) -> Date? {
    let calendar = Calendar.current
    let rightNow = Date()
    let nextDiff = interval - calendar.component(.minute, from: rightNow) % interval
    let nextDate = calendar.date(byAdding: .minute, value: nextDiff, to: rightNow) ?? Date()
    return nextDate
  }

  public func add(minutes: Int) -> Date? {
    return Calendar.current.date(byAdding: DateComponents(minute: minutes), to: self)
  }

    public func add(months: Int) -> Date? {
        return Calendar.current.date(byAdding: DateComponents(month: months), to: self)
    }

    public func add(days: Int) -> Date? {
        return Calendar.current.date(byAdding: DateComponents(day: days), to: self)
    }

    public func add(years: Int) -> Date? {
        return Calendar.current.date(byAdding: DateComponents(year: years), to: self)
    }

    public func add(months: Int, days: Int, years: Int) -> Date? {
        return Calendar.current.date(byAdding: DateComponents(year: years, month: months, day: days), to: self)
    }

    func calcAge(birthday: String) -> Int {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "MM/dd/yyyy"
        let birthdayDate = dateFormater.date(from: birthday)
        let calendar: NSCalendar! = NSCalendar(calendarIdentifier: .gregorian)
        let now = Date()
        let calcAge = calendar.components(.year, from: birthdayDate!, to: now, options: [])
        let age = calcAge.year
        return age!
    }
}

//  MARK:- Date comparisons
extension Date {
    public func isGreaterThanDate(_ dateToCompare: Date) -> Bool {
        return compare(dateToCompare) == ComparisonResult.orderedDescending
    }

    public func isLessThanDate(_ dateToCompare: Date) -> Bool {
        return compare(dateToCompare) == ComparisonResult.orderedAscending
    }

    public func isEqualToDate(_ dateToCompare: Date) -> Bool {
        return compare(dateToCompare) == ComparisonResult.orderedSame
    }

    public func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
        let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date())!
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        if minuteAgo < self {
            let diff = Calendar.current.dateComponents([.second], from: self, to: Date()).second ?? 0
            return "\(diff) sec ago"
        } else if hourAgo < self {
            let diff = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute ?? 0
            return "\(diff) min ago"
        } else if dayAgo < self {
            let diff = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour ?? 0
            return "\(diff) hrs ago"
        } else if weekAgo < self {
            let diff = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
            return "\(diff) days ago"
        }
        let diff = Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear ?? 0
        return "\(diff) weeks ago"
    }
}

//  MARK:- Generic functions
extension Date {

    enum Error: LocalizedError {
        case firstOfTheMonth(date: Date)
        case lastOfTheMonth(date: Date)

        var errorDescription: String? {
            switch self {
            case .firstOfTheMonth(let date):
                return String(format: "Failed to calculate the first day the month based on %@", date.description)
            case .lastOfTheMonth(let date):
                return String(format: "Failed to calculate the last day the month based on %@", date.description)
            }
        }
    }

    func getMonth(withFormat format: CustomDateFormat = .month) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        let strMonth = dateFormatter.string(from: self)
        return strMonth
    }

    func getMonth(withStringFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let strMonth = dateFormatter.string(from: self)
        return strMonth
    }

    public func toString(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    func toString(_ format: CustomDateFormat = .timeDate) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        return dateFormatter.string(from: self)
    }

    public func firstOfTheMonth() throws -> Date {
        let startOfDay = Calendar.current.startOfDay(for: self)
        let monthYearDateComponents = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        guard let firstOfTheMonth = Calendar.current.date(from: monthYearDateComponents) else {
            throw Date.Error.firstOfTheMonth(date: self)
        }
        return firstOfTheMonth
    }

    public func lastOfTheMonth() throws -> Date {
        let firstOfTheMonthDate = try firstOfTheMonth()
        guard let lastOfTheMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfTheMonthDate) else {
            throw Date.Error.lastOfTheMonth(date: self)
        }
        return lastOfTheMonth
    }

    public func monthYearComponents() -> (month: Int, year: Int)? {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        guard let month = components.month, let year = components.year else { return nil }
        return (month, year)
    }

    public func daysInMonth() -> Int? {
        return Calendar.current.range(of: .day, in: .month, for: self)?.count
    }

}

//  MARK:- Deprecated
extension Date {
    func getMonthDayName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let strMonth = dateFormatter.string(from: self)
        return strMonth
    }

    func getMonthYearName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM YYYY"
        let strMonth = dateFormatter.string(from: self)
        return strMonth
    }

    func getMonthDayYearName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d YY"
        let strMonth = dateFormatter.string(from: self)
        return strMonth
    }
}

extension DateFormatter {

    @objc public class func isSystemFormat24Hours() -> Bool {
        let formatter = Foundation.DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let formattedCurrentTime = formatter.string(from: Date())
        return formattedCurrentTime.range(of: formatter.amSymbol) == nil && formattedCurrentTime.range(of: formatter.pmSymbol) == nil
    }

    //    public class func getFormattedDate(_ date: String) -> String {
    //        return self.stringWithFormatEEEMMMddy(forTimestamp: date)
    //    }
    //
    //    public class func getFormattedTime(_ date: String) -> String {
    //        return self.DateFormatter.stringWithLocalizedTimeFormat(forTimestamp: date)
    //    }
    //
    public class func stringWithFormatMMMDDCOMMAYYYY(_ date: String, timeZone: TimeZone) -> String {
        if let date = dateWithFormatMMMDDCOMMAYYYY(date, timeZone: timeZone) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            dateFormatter.timeZone = timeZone
            return dateFormatter.string(from: date)
        }
        return ""
    }

    public class func detectAndFormat(_ date: String, timeZone: TimeZone) -> Date? {
        let possibleFormats = [
            "yyyy-MM-dd'T'HH:mm:ssZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]
        return possibleFormats.compactMap { (format) -> Date? in
            return dateWithFormat(date, format: format, timeZone: timeZone)
            }.first
    }

    public class func dateWithFormat(_ date: String, format: String, timeZone: TimeZone) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = timeZone
        let date = dateFormatter.date(from: date)
        return date
    }

    public class func dateWithFormatMMMDDCOMMAYYYY(_ date: String, timeZone: TimeZone) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        dateFormatter.timeZone = timeZone
        let date = dateFormatter.date(from: date)
        return date
    }

}
