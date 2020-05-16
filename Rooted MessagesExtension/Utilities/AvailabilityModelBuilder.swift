//
//  AvailabilityModelBuilder.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/16/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit
import Branch
import SSSpinnerButton
import CoreData
import FSCalendar
import SwiftDate
import Messages

class AvailabilityModelBuilder {
  var dictionary: [String: Any]?
  var availability: Availability?

  func start() -> AvailabilityModelBuilder {
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

  func add(key: String, value: Any) -> AvailabilityModelBuilder {
    if dictionary != nil {
      dictionary![key] = value
      return self
    } else {
      return start().add(key: key, value: value)
    }
  }
  func remove(key: String, value: Any) -> AvailabilityModelBuilder {
    if dictionary != nil, dictionary![key] != nil {
      dictionary!.removeValue(forKey: key)
      return self
    } else {
      return self
    }
  }
  func generateModel() -> AvailabilityModelBuilder {
    if dictionary != nil {
      var meetingDict: [String: Any] = [:]

      if let availabledates = retrieve(forKey: "available_dates") as? [MeetingDateClass] {
        meetingDict["availability_dates"] = availabledates.toJSON()
      }

      availability = Availability(JSON: meetingDict)
      return self
    } else {
      return self
    }
  }
}
