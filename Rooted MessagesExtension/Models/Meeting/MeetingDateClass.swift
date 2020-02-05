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

// MARK: - MeetingDateClass
public class MeetingDateClass: Mappable {
  public var month, monthSh, dayOfWeek, dayNumerical: String?
  public var year, yearSh: String?
  public var startTime, endTime: Time?
  public var dateString: String?

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
  }
}
