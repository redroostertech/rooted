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
  public var id, priority, minimumUserTypeRequired: Int?
  public var isExtension, defaultIsOn, isActive, isMobile: Bool?
  public var description, key, title, type, defaultValue: String?
  public var metaInformation: [String: Any]?
  public var choices: [UserPreferenceChoice]?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    priority <- map["priority"]
    minimumUserTypeRequired <- map["minimum_user_type_required"]
    isExtension <- map["is_extension"]
    defaultIsOn <- map["default_is_on"]
    isActive <- map["is_active"]
    isMobile <- map["is_mobile"]
    description <- map["description"]
    key <- map["key"]
    title <- map["title"]
    type <- map["type"]

    switch type {
    case "picker":
      choices <- map["choices"]
      defaultValue <- map["default_value"]
    default: break
    }
    metaInformation <- map["meta_information"]
  }
}

// MARK: - UserPreferenceChoice
public class UserPreferenceChoice: Mappable {
  public var collectionName: String?
  public var values: [PreferenceChoice]?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    collectionName <- map["id"]
    values <- map["values"]
  }
}

// MARK: - PreferenceChoice
public class PreferenceChoice: Mappable {
  public var title, shortTitle, value: String?
  public var id, minimumUserTypeRequired, order: Int?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    title <- map["title"]
    shortTitle <- map["sh_title"]
    value <- map["value"]
    minimumUserTypeRequired <- map["minimum_user_type_required"]
    id <- map["id"]
    order <- map["order"]
  }
}
