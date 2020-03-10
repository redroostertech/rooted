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

  public struct Availabilities {
    public static func jsonToCoreData(_ result: Availability) -> NSManagedObject? {
      let coreDataManager = CoreDataManager()
      let context = coreDataManager.managedContext
      guard let entity = coreDataManager.availabilityEntity, let objectString =
        result.toJSONString() else {
        return nil
      }

      let object = NSManagedObject(entity: entity, insertInto: context)

      object.setValuesForKeys([
        "id": RanStringGen(length: 10).returnString(),
        "object": objectString,
        "createdAt": Date()
        ])
      return object
    }

    public static func coreDataToJson(_ result: NSManagedObject) -> Availability? {
      let keys = Array(result.entity.attributesByName.keys)
      let dict = result.dictionaryWithValues(forKeys: keys) as [String: Any]
      guard let jsonString = dict["object"] as? String else { return nil }
      return Availability(JSONString: jsonString)
    }

    // TODO: - Move this method to `MessageFactory`
    public static func objectToMessage(_ object: Availability) -> MSMessage? {
      
      guard let availabilityDates = object.availabilityDates, availabilityDates.count > 0 else {
        return nil
      }

      let message = MSMessage()
      var subcaption = ""

      let layout = MSMessageTemplateLayout()
      layout.caption = "Check out my available times over the next week"

      if let meetingjson = object.toJSONString() {
        message.md.set(value: meetingjson, forKey: kMessageObjectKey)
      }

      layout.subcaption = subcaption
      message.layout = layout
      //  message.url =

      return message
    }

    public static func messageToMeeting(_ message: MSMessage) -> Availability? {
      guard let jsonString = message.md.string(forKey: kMessageObjectKey), let meeting = Availability(JSONString: jsonString) else {
        return nil
      }
      return meeting
    }
  }

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
        "createdAt": Date()
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
