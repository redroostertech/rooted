// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let userPreference = try? newJSONDecoder().decode(UserPreference.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - UserPreference
public class UserPreference: Mappable {
  public var preferenceId, preferenceSelectionId: Int?
  public var metaInformation: [String: Any]?
  public var preference: Preference?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    preferenceId <- map["preference_id"]
    preferenceSelectionId <- map["preference_selection_id"]
    metaInformation <- map["meta_information"]
    preference <- map["preference"]
  }
}
