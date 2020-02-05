// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let userProfileDataDashboardSection = try? newJSONDecoder().decode(UserProfileDataDashboardSection.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - UserProfileDataDashboardSection
public class UserProfileDataDashboardSection: Mappable {
  public var dashboardId: Int?
  public var headerIsVisible: Bool?
  public var metaInformation: [JSONAny]?
  public var dashboardSection: DataDashboardSection?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    dashboardId <- map["dashboard_id"]
    headerIsVisible <- map["header_is_visible"]
    metaInformation <- map["meta_information"]
    dashboardSection <- map["dashboard_section"]
  }
}
