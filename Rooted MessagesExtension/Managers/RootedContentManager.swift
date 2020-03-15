//
//  RootedContentManager.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/12/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import EventKit

enum RootedContentManagerType {
  case receive
  case send
}

class RootedContentManager {
  private var eventKitManager = EventKitManager()
  private var coreDataManager = CoreDataManager()
  private let eventStore = EKEventStore()

  private var managerType: RootedContentManagerType!

  required init(managerType: RootedContentManagerType) {
    self.managerType = managerType
  }

  func checkCalendarPermissions(_ completion: @escaping (Bool) -> Void) {
    eventKitManager.getCalendarPermissions(completion)
  }

  func insert(_ meeting: Meeting, completion: @escaping (Bool, Error?) -> Void) {
    // TODO: - Track the name, location, and length of an event
    
    // Send meeting object to event kit manager to save as event into calendar
    eventKitManager.insertMeeting(meeting: meeting) { (success, error) in
      if let err = error {
        completion(false, err)
      } else {
        if success {
          // Save invite to Core Data
          self.saveToCoreData(meeting: meeting, completion: completion)
        } else {
          completion(false, RError.customError("Something went wrong. Please try again.").error)
        }
      }
    }
  }

  func saveToCoreData(meeting: Meeting, completion: @escaping (Bool, Error?) -> Void) {
    // Update meeting when receiving it to have a section of 1. Temporary
    switch managerType {
    case .some(.receive):
      meeting.dashboardSectionId = 0
    case .some(.send):
      meeting.dashboardSectionId = 1
    case .none:
      meeting.dashboardSectionId = 2 // Value of `2` is not in use so meeting just wont be accounted for
    }
    MeetingsManager().createInvite(meeting, completion)
  }
}
