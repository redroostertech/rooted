// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let meetingDateClass = try? newJSONDecoder().decode(MeetingDateClass.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper
import SwiftDate

// MARK: - MeetingDateClass
public class MeetingDateClass: Mappable {
  public var month, monthSh, dayOfWeek, dayNumerical: String?
  public var year, yearSh: String?
  public var endMonth, endMonthSh, endDayOfWeek, endDayNumerical: String?
  public var endYear, endYearSh: String?
  public var startTime, endTime: Time?
  public var dateString: String?
  public var startDate, endDate: String?
  public var timeZone: String?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    month <- map["month"]
    monthSh <- map["month_sh"]
    dayOfWeek <- map["day_of_week"]
    dayNumerical <- map["day_numerical"]
    year <- map["year"]
    yearSh <- map["year_sh"]
    startTime <- map["start_time"]
    endTime <- map["end_time"]
    dateString <- map["date_string"]
    endMonth <- map["end_month"]
    endMonthSh <- map["end_month_sh"]
    endDayOfWeek <- map["end_day_of_week"]
    endDayNumerical <- map["end_day_numerical"]
    endYear <- map["end_year"]
    endYearSh <- map["end_year_sh"]
    startDate <- map["start_date"]
    endDate <- map["end_date"]
    timeZone <- map["time_zone"]
  }

  public var readableTime: String {
    var string = ""
    guard let startdate = startDate?.toDate()?.date, let enddate = endDate?.toDate()?.date else { return string }
    if startdate.toString() == enddate.toString() {
      string += startdate.toString(.proper)
      string += " to \(enddate.toString(.timeOnly))"
    } else {
      string += startdate.toString(.abbrMonthDayTime)
      string += " to \(enddate.toString(.abbrMonthDayTime))"
    }
    return string
  }

  public var startTimeOnly: String {
    var string = ""
    guard let startdate = startDate?.toDate()?.date, let _ = endDate?.toDate()?.date else { return string }
    string += "on \(startdate.toString(.rooted))"
    return string
  }

}
