//
//  MeetingModelBuilder.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/11/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftDate

class MeetingModelBuilder {
  var dictionary: [String: Any]?
  var meeting: Meeting?

  func start() -> MeetingModelBuilder {
    self.dictionary = [String: Any]()
    return self
  }

  func retrieve(forKey key: String) -> Any? {
    if dictionary != nil {
      if dictionary![key] != nil {
        return dictionary![key]
      } else {
        return nil
      }
    } else {
      return nil
    }
  }

  func has(key: String) -> Bool {
    if dictionary != nil {
      return dictionary!.keys.contains(key)
    } else {
      return false
    }
  }

  func add(key: String, value: Any) -> MeetingModelBuilder {
    if dictionary != nil {
      dictionary![key] = value
      return self
    } else {
      return start().add(key: key, value: value)
    }
  }
  func remove(key: String, value: Any) -> MeetingModelBuilder {
    if dictionary != nil, dictionary![key] != nil {
      dictionary!.removeValue(forKey: key)
      return self
    } else {
      return self
    }
  }
  func generateMeeting() -> MeetingModelBuilder {
    if dictionary != nil {
      var meetingDict: [String: Any] = [
        "meeting_name": retrieve(forKey: "meeting_name") as? String ?? ""
      ]

      if let meetinglocation = retrieve(forKey: "meeting_location") as? String, let rlocation = RLocation(JSONString: meetinglocation) {
        meetingDict["meeting_location"] = rlocation.toJSON()
      }

      if let startdate = retrieve(forKey: "start_date") as? Date, let enddate = retrieve(forKey: "end_date") as? Date {

        var dateDict = [
          "start_date": startdate.toString(),
          "end_date": enddate.toString()
        ]

        if let timezone = retrieve(forKey: "time_zone") as? String {
          dateDict["time_zone"] = timezone
        }

        if let dateclass = MeetingDateClass(JSON: dateDict) {
          meetingDict["meeting_date"] = dateclass.toJSON()
        }
      }

      if let meetingTypes = retrieve(forKey: "meeting_type") as? [[String: Any]] {

        var meetingtypes = [MeetingType]()

        for meetingType in meetingTypes {
          if let meetingtype = MeetingType(JSON: meetingType) {
            meetingtypes.append(meetingtype)
          }
        }

        meetingDict["meeting_type"] = meetingtypes.toJSON()

      }

      if let meetingAgendas = retrieve(forKey: "agenda_items") as? [[String: Any]] {
        var agendaItems = [AgendaItem]()

        for agendaItem in meetingAgendas {
          if let item = AgendaItem(JSON: agendaItem) {
            agendaItems.append(item)
          }
        }
        meetingDict["agenda_items"] = agendaItems.toJSON()
        RRLogger.log(message: "Agenda Items:\n\(agendaItems.toJSON())", owner: self)
      }

      if let meetingDescription = retrieve(forKey: "meeting_description") as? String {
        meetingDict["meeting_description"] = meetingDescription
      }

      if let meetingOwner = retrieve(forKey: "owner_id") as? String {
        meetingDict["owner_id"] = meetingOwner
      }

      meetingDict["id"] = RanStringGen(length: 26).returnString()
      meetingDict["dashboard_section_id"] = 1
      meeting = Meeting(JSON: meetingDict)
      return self
    } else {
      return self
    }
  }
}
