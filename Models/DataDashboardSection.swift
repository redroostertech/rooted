// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let dataDashboardSection = try? newJSONDecoder().decode(DataDashboardSection.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - DataDashboardSection
public class DataDashboardSection: Mappable {
  public var priority, id: Int?
  public var headerTitle, headerDescription: String?

  enum CodingKeys: String, CodingKey {
      case priority, id
      case headerTitle = "header_title"
      case headerDescription = "header_description"
  }

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    priority <- map["priority"]
    headerTitle <- map["header_title"]
    headerDescription <- map["header_description"]
  }
}
