//
//  EngagementFactory.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/29/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages
import CoreData
import SwiftDate

class EngagementFactory {

  // MARK: - Meetings
  // Factory methods for quickly converting `Meeting` objects into `NSManagedObjects` and `MSMessage` objects and more.
  // The outputs are configured model objects; no additional functionality
  public struct Meetings {

    // MARK: - Use Case: Convert a `Meeting` object into a JSON string and add it to a `NSManagedObject` to be saved into local storage
    public static func jsonToCoreData(_ result: Meeting) -> NSManagedObject? {
      let coreDataManager = CoreDataManager()
      guard let objectString = result.toJSONString(), let managedObject = coreDataManager.meetingManagedObject else {
        return nil
      }
      managedObject.setValuesForKeys([
        "id": result.id ?? RanStringGen(length: 10).returnString(),
        "object": objectString,
        "createdAt": Date()
      ])
      return managedObject
    }

    // MARK: - Use Case: Convert a `NSManagedObject` into a `Meeting` object via the json string stored within the property `object`
    public static func coreDataToJson(_ result: NSManagedObject) -> Meeting? {
      let keys = Array(result.entity.attributesByName.keys)
      let dict = result.dictionaryWithValues(forKeys: keys) as [String: Any]
      guard let jsonString = dict["object"] as? String else { return nil }
      return Meeting(JSONString: jsonString)
    }

    // MARK: - Use Case: Convert a `Meeting` object into a `MSMessage` object
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

    // MARK: - Use Case: Retrieve the json string of the `Meeting` object from the `MSMessage` object
    public static func messageToMeeting(_ message: MSMessage) -> Meeting? {
      guard let jsonString = message.md.string(forKey: kMessageObjectKey), let model = Meeting(JSONString: jsonString) else {
        return nil
      }
      return model
    }

    // TODO: - What is this?
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

      return [RootedCollectionViewModel(section: .none, cells: rootedCellViewModels)]
    }

    // MARK: - MeetingResponse
    // Factory methods for quickly creating response objects when a use engages with a `Meeting` object retrieved from a `MSMessage` object
    // The outputs are configured model objects; no additional functionality
    public struct Response {
      public static func generateResponse(to meeting: Meeting, withText text: String) -> MSMessage {

        let message = MSMessage()
        let subcaption = ""

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

  // MARK: - Availability
  public struct AvailabilityFactory {

    // MARK: - Use Case: Convert a `Availability` object into a JSON string and add it to a `NSManagedObject` to be saved into local storage
    public static func jsonToCoreData(_ result: Availability) -> NSManagedObject? {
      let coreDataManager = CoreDataManager()
      guard let objectString = result.toJSONString(), let managedObject = coreDataManager.availabilityManagedObject else {
        return nil
      }
      managedObject.setValuesForKeys([
        "id": RanStringGen(length: 10).returnString(),
        "object": objectString,
        "createdAt": Date()
      ])
      return managedObject
    }

    // MARK: - Use Case: Convert a `NSManagedObject` into a `Availability` object via the json string stored within the property `object`
    public static func coreDataToJson(_ result: NSManagedObject) -> Availability? {
      let keys = Array(result.entity.attributesByName.keys)
      let dict = result.dictionaryWithValues(forKeys: keys) as [String: Any]
      guard let jsonString = dict["object"] as? String else { return nil }
      return Availability(JSONString: jsonString)
    }

    // MARK: - Use Case: Convert a `Availability` object into a `MSMessage` object
    public static func availabilityToMessage(_ object: Availability) -> MSMessage? {
      guard let availabilityDates = object.availabilityDates, availabilityDates.count > 0 else {
        return nil
      }

      let message = MSMessage()
      let subcaption = ""

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

    // MARK: - Use Case: Retrieve the json string of the `Availability` object from the `MSMessage` object
    public static func messageToAvailability(_ message: MSMessage) -> Availability? {
      guard let jsonString = message.md.string(forKey: kMessageObjectKey), let model = Availability(JSONString: jsonString) else {
        return nil
      }
      return model
    }

    // MARK: - AvailabilityResponse
    // Factory methods for quickly creating response objects when a use engages with a `Availability` object retrieved from a `MSMessage` object
    // The outputs are configured model objects; no additional functionality
    public struct AvailabilityResponse {
      public static func generateResponse(to model: Availability, withText text: String) -> MSMessage {

        let message = MSMessage()
        let subcaption = ""

        let layout = MSMessageTemplateLayout()
        layout.caption = text

        if let meetingjson = model.toJSONString() {
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
