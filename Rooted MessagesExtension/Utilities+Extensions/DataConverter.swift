//
//  DataConverter.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/29/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages
import CoreData

class DataConverter {

  public struct Meetings {
    public static func jsonToCoreData(_ result: Meeting) -> NSManagedObject? {
      let coreDataManager = CoreDataManager()
      let context = coreDataManager.managedContext
      guard let entity = coreDataManager.meetingEntity, let objectString = result.toJSONString() else {
        return nil
      }

      let object = NSManagedObject(entity: entity, insertInto: context)

      object.setValuesForKeys([
        "id": RanStringGen(length: 10).returnString(),
        "object": objectString,
      ])
      return object
    }

    public static func coreDataToJson(_ result: NSManagedObject) -> Meeting? {
      let keys = Array(result.entity.attributesByName.keys)
      let dict = result.dictionaryWithValues(forKeys: keys) as [String: Any]
      guard let jsonString = dict["object"] as? String else { return nil }
      return Meeting(JSONString: jsonString)
    }

    // TODO: - Move this method to `MessageFactory`
    public static func meetingToMessage(_ meeting: Meeting) -> MSMessage? {
      guard let meetingname = meeting.meetingName, let startdate = meeting.meetingDate?.startDate, let enddate = meeting.meetingDate?.endDate else {
          return nil
      }

      let message = MSMessage()
      var subcaption = ""

      let layout = MSMessageTemplateLayout()
      layout.caption = String(format: captionString, arguments: [meetingname, startdate.convertToDate().toString(.rooted)])

      message.md.set(value: meetingname, forKey: kMessageTitleKey)
      message.md.set(value: startdate.convertToDate().toString(), forKey: kMessageStartDateKey)
      message.md.set(value: enddate.convertToDate().toString(), forKey: kMessageEndDateKey)

      if let meetingjson = meeting.toJSONString() {
        message.md.set(value: meetingjson, forKey: kMessageObjectKey)
      }

      if let loc = meeting.meetingLocation, let locationString = loc.toJSONString() {
        subcaption += loc.readableWhereString
        message.md.set(value: loc.readableWhereString, forKey: kMessageSubCaptionKey)
        message.md.set(value: locationString, forKey: kMessageLocationStringKey)
      }

      layout.subcaption = subcaption
      message.layout = layout
      //  message.url =

      return message
    }

    public static func messageToMeeting(_ message: MSMessage) -> Meeting? {
      guard let jsonString = message.md.string(forKey: kMessageObjectKey), let meeting = Meeting(JSONString: jsonString) else {
        return nil
      }
      return meeting
    }
  }
}
