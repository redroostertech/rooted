//
//  MessageFactory.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/29/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages
import CoreData
import SwiftDate

class MessageFactory {

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

    public static func meetingToMessage(_ meeting: Meeting) -> MSMessage? {
      guard let meetingname = meeting.meetingName, let startdate = meeting.meetingDate?.startDate?.toDate()?.date, let _ = meeting.meetingDate?.endDate?.toDate()?.date else {
          return nil
      }

      let message = MSMessage()
      var subcaption = ""

      let layout = MSMessageTemplateLayout()
      layout.caption = String(format: captionString, arguments: [meetingname, startdate.toString(.rooted)])

      message.md.set(value: meetingname, forKey: kMessageTitleKey)
      message.md.set(value: startdate.toString(.rooted), forKey: kMessageStartDateKey)
      message.md.set(value: startdate.toString(.rooted), forKey: kMessageEndDateKey)

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

    public static func convert(contextWrappers: [MeetingContextWrapper], for menuSelection: Int, withDelegate delegate: RootedCellDelegate?) -> [RootedCollectionViewModel] {

      var meetingContextWrappers = [MeetingContextWrapper]()

      switch menuSelection {
      case 1:
        meetingContextWrappers = contextWrappers.filter { meetingContextWrapper -> Bool in
          guard let meeting = meetingContextWrapper.meeting, let dashboardSectionId = meeting.dashboardSectionId else { return false }
          return dashboardSectionId == menuSelection
        }
        break
      default:
        meetingContextWrappers = contextWrappers
        break
      }

      let rootedCellViewModels: [RootedCellViewModel] = meetingContextWrappers.map { meetingContextWrapper -> RootedCellViewModel in
        let viewModel = RootedCellViewModel(data: meetingContextWrapper.meeting, delegate: delegate)
        viewModel.managedObject = meetingContextWrapper.managedObject
        return viewModel
      }

      // TODO: - Figure this part out then uncomment
      //    let rootedCollectionViewModels: [RootedCollectionViewModel] = meetingContextWrappers.map { meetingContextWrapper ->  RootedCollectionViewModel in
      //      return RootedCollectionViewModel(section: .none, cells: rootedCellViewModels)
      //    }

      return [RootedCollectionViewModel(section: .none, cells: rootedCellViewModels)]
    }

    public struct Response {
      public static func generateResponse(to meeting: Meeting, withText text: String) -> MSMessage {

        let message = MSMessage()
        var subcaption = ""

        let layout = MSMessageTemplateLayout()
        layout.caption = text

        if let meetingjson = meeting.toJSONString() {
          message.md.set(value: meetingjson, forKey: kMessageObjectKey)
        }

        layout.subcaption = subcaption
        message.layout = layout
        //  message.url =

        return message
      }
    }
  }
}
