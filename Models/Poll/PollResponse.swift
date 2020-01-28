// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let pollResponse = try? newJSONDecoder().decode(PollResponse.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - PollResponse
public class PollResponse: DataClass {
  public var pollId, ownerId, pollResponse: Int?
  public var createdAt, updatedAt: String?

  public var owner: UserProfileShortData?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    pollId <- map["pollId"]
    ownerId <- map["owner_id"]
    pollResponse <- map["poll_response"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    owner <- map["owner"]
  }
}
