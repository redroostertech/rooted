// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let preference = try? newJSONDecoder().decode(Preference.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Preference
public class Preference: Mappable {
    public var priority, minimumUserTypeRequired, id: Int?
    public var title, type, preferenceDescription: String?
    public var isOn: Bool?
    public var action: Action?
    public var choices: [Reminders]?
    public var createdAt, updatedAt: String?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    priority <- map["priority"]
    minimumUserTypeRequired <- map["minimum_user_type_required"]
    title <- map["title"]
    type <- map["type"]
    preferenceDescription <- map["description"]
    isOn <- map["is_on"]
    action <- map["action"]
    choices <- map["choices"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
  }
}
