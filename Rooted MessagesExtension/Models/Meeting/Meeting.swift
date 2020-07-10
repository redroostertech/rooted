// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let meeting = try? newJSONDecoder().decode(Meeting.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Meetings
public class Meetings: Mappable {
  var meetings: [Meeting]?

  public required init?(map: Map) { }

  public func mapping(map: Map) {
    meetings <- map["meetings"]
  }
}

// MARK: - Meeting
public class Meeting: Mappable {
  public var id, key, ownerId: String?
  public var metaInformation: [String: Any]?
  public var dashboardSectionId, meetingStatusId, meetingOwnerId: Int?
  public var meetingName, meetingDescription: String?
  public var meetingLocation: RLocation?
  public var meetingDate: MeetingDateClass?
  public var meetingParticipantsIds, meetingAgendaItemIds, meetingFilesIds, remindOnIds: [Int]?
  public var requireResponse, isPublic: Bool?
  public var meetingResponseIds: [Int]?
  public var createdAt, updatedAt: String?

  public var owner: [UserProfileData]?
  public var participants: [UserProfileData]?
  public var agendaItems: [AgendaItem]?
  public var files: [Media]?
  public var reminders: [Reminders]?
  public var meetingType: [MeetingType]?

  public var calendarId: String?

  public var meetingAgendaItems: [String]?
  public var isChatEnabled: String?
  
  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    key <- map["key"]
    ownerId <- map["owner_id"]
    metaInformation <- map["meta_information"]
    owner <- map["owner"]
    dashboardSectionId <- map["dashboard_section_id"]
    meetingStatusId <- map["meeting_status_id"]
    meetingOwnerId <- map["meeting_owner_id"]
    meetingName <- map["meeting_name"]
    meetingDescription <- map["meeting_description"]
    meetingLocation <- map["meeting_location"]
    meetingDate <- map["meeting_date"]
    meetingParticipantsIds <- map["meeting_participants_ids"]
    meetingAgendaItemIds <- map["meeting_agenda_item_ids"]
    meetingFilesIds <- map["meeting_files_ids"]
    remindOnIds <- map["remind_on_ids"]
    requireResponse <- map["require_response"]
    isPublic <- map["is_public"]
    meetingResponseIds <- map["meeting_response_ids"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    metaInformation <- map["meta_information"]
    owner <- map["owner"]
    participants <- map["meeting_participants"]
    agendaItems <- map["agenda_items"]
    files <- map["meeting_files"]
    reminders <- map["reminders"]
    meetingType <- map["meeting_type"]
    calendarId <- map["calendar_id"]
    meetingAgendaItems <- map["agenda_items_strings"]
    isChatEnabled <- map["is_chat_enabled"]
  }
}

// MARK: - Meeting Type
public class MeetingType: Mappable {
  public var id, typeOfMeeting, meetingMeta: String?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    typeOfMeeting <- map["type_of_meeting"]
    meetingMeta <- map["meeting_meta"]
  }
}

// MARK: - Meeting Invitation
public class MeetingInvitation: DataClass {
  public var meetingId, recipientId: Int?
  public var createdAt, updatedAt: String?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    meetingId <- map["meeting_id"]
    recipientId <- map["recipient_id"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
  }
}

// MARK: - Meeting Response
public class MeetingResponse: Mappable {
  public var id: String?
  public var metaInformation: [String: Any]?
  public var meetingId, ownerId: Int?
  public var meetingResponse, createdAt, updatedAt: String?

  public var owner: UserProfileShortData?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    metaInformation <- map["meta_information"]
    meetingId <- map["meeting_id"]
    ownerId <- map["owner_id"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    owner <- map["owner"]
  }
}
