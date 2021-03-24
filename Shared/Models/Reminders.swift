// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let reminders = try? newJSONDecoder().decode(Reminders.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Reminders
public class Reminders: DataClass {
  public var order: Int?
  public var title: String?
  public var minimumUserTypeRequired: Int?
  public var isPremium: Bool?
  public var ownerId: Int?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    order <- map["order"]
    title <- map["title"]
    ownerId <- map["owner_id"]
    minimumUserTypeRequired <- map["minimum_user_type_required"]
    isPremium <- map["is_premium"]
  }
}

// MARK: - Invites
public class Invites: DataClass {
  public var firstName: String?
  public var lastName: String?
  public var email: String?
  public var phone: String?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    firstName <- map["firstName"]
    lastName <- map["lastName"]
    email <- map["email"]
    phone <- map["phone"]
  }

}
