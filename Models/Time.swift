// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let time = try? newJSONDecoder().decode(Time.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Time
public class Time: Mappable {
  public var hours, minutes, meridiemType: Int?
  public var primaryString: String?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    hours <- map["hours"]
    minutes <- map["minutes"]
    meridiemType <- map["meridiem_type"]
    primaryString <- map["primary_string"]
  }
}
