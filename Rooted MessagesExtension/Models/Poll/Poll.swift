// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let poll = try? newJSONDecoder().decode(Poll.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Poll
public class Poll: DataClass {
  public var pollStatus, pollOwnerId: Int?
  public var pollName, pollDescription: String?
  public var pollEndDate: MeetingDateClass?
  public var pollParticipantsIds: [Int]?
  public var pollChoices: [PollChoice]?
  public var pollResponsesIds, remindOnIds: [Int]?
  public var isPublic: Bool?
  public var createdAt, updatedAt: String?

  public var owner: UserProfileShortData?
  public var participants: [UserProfileData]?
  public var responses: [PollResponse]?
  public var reminders: [Reminders]?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    owner <- map["owner"]
    pollStatus <- map["poll_status"]
    pollOwnerId <- map["poll_owner_id"]
    pollName <- map["poll_name"]
    pollDescription <- map["poll_description"]
    pollEndDate <- map["poll_end_date"]
    pollParticipantsIds <- map["poll_participants_ids"]
    pollChoices <- map["poll_choices"]
    pollResponsesIds <- map["poll_responses_ids"]
    remindOnIds <- map["remind_on_ids"]
    isPublic <- map["is_public"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    owner <- map["owner"]
    responses <- map["responses"]
  }
}

// MARK: - Poll Choice
public class PollChoice: DataClass {
  public var order, minimumUserTypeRequired: Int?
  public var title: String?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    order <- map["order"]
    title <- map["title"]
    minimumUserTypeRequired <- map["minimum_user_type_required"]
  }
}
