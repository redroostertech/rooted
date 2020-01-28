// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let agendaItem = try? newJSONDecoder().decode(AgendaItem.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - AgendaItem
public class AgendaItem: DataClass {
  public var order: Int?
  public var itemName: String?
  public var meetingId, ownerId: Int?
  public var createdAt, updatedAt: String?

  public var owner: UserProfileShortData?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    order <- map["order"]
    itemName <- map["item_name"]
    meetingId <- map["meeting_id"]
    ownerId <- map["owner_id"]
    owner <- map["owner"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
  }
}

// MARK: - Check In
public class CheckIn: DataClass {
  public var meetingId, ownerId: Int?
  public var createdAt, updatedAt: String?

  public var owner: UserProfileShortData?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    meetingId <- map["meeting_id"]
    ownerId <- map["owner_id"]
    owner <- map["owner"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
  }

}
