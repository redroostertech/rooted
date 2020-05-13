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
  case none
  case receive
  case send
}

protocol RootedContentBusinessLogic: class {
  func setupBranchIO(request: RootedContent.SetupBranchIO.Request)
  func checkCalendarPermissions(request: RootedContent.CheckCalendarPermissions.Request)
  func retrieveMeetings(request: RootedContent.RetrieveMeetings.Request)
  func deleteMeeting(request: RootedContent.DeleteMeeting.Request)
  func goToCreateNewMeetingView(request: RootedContent.CreateNewMeeting.Request)
  func saveMeeting(request: RootedContent.SaveMeeting.Request)
  func addToCalendar(request: RootedContent.AddToCalendar.Request)
  func checkMaximumMeetingsReached(request: RootedContent.CheckMaximumMeetingsReached.Request)
  func removeMeetingFromCalendar(request: RootedContent.RemoveFromCalendar.Request)
}

protocol RootedContentDataStore {
  var isCalendarPermissionGranted: Bool? { get set }
  var maximumMeetingsReached: Bool? { get set }
}

class RootedContentInteractor: RootedContentBusinessLogic, RootedContentDataStore {

  // MARK: - Presenter
  var presenter: RootedContentPresentationLogic?

  // MARK: - Datastore
  var isCalendarPermissionGranted: Bool?
  var maximumMeetingsReached: Bool?

  // MARK: - Workers
  private var branchWorker = BranchWorker()
  private var meetingsManager = MeetingsManager()
  private var coreDataManager = CoreDataManager()
  private var eventKitManager = EventKitManager()

  func retrieveErrorMessage(_ error: Error) -> String {
    if let rerror = error as? RError {
      return rerror.localizedDescription
    } else {
      return error.localizedDescription
    }
  }
  // MARK: - Use Case: Initialize session of BranchIO and handle response
  func setupBranchIO(request: RootedContent.SetupBranchIO.Request) {
    branchWorker.initSession { meeting in
      if let meeting = meeting {
        var response = RootedContent.SetupBranchIO.Response()
        response.meeting = meeting
        self.presenter?.handleBranchIOResponse(response: response)
      }
    }
  }

  // MARK: - Use Case: Check if app has access to calendar permissions
  func checkCalendarPermissions(request: RootedContent.CheckCalendarPermissions.Request) {
    var response = RootedContent.CheckCalendarPermissions.Response()
    eventKitManager.getCalendarPermissions { granted in
      response.isGranted = granted
      self.isCalendarPermissionGranted = granted
      self.presenter?.handleCalendarPermissions(response: response)
    }
  }

  // MARK: - Use Case: As a business, we want to limit access to creating more than (n) meetings based on account type
  func checkMaximumMeetingsReached(request: RootedContent.CheckMaximumMeetingsReached.Request) {
    var response = RootedContent.CheckMaximumMeetingsReached.Response()
    meetingsManager.didUserReachMaximumInvites { success in
      if success {
        self.branchWorker.customEvent(withName: kBranchMaximumReached)
        response.isMaximumumReached = true
        self.presenter?.handleMaximumLimitReached(response: response)
      } else {
        response.isMaximumumReached = false
        self.presenter?.handleMaximumLimitReached(response: response)
      }
    }
  }

  // MARK: - Use Case: Retrieve meetings for user
  func retrieveMeetings(request: RootedContent.RetrieveMeetings.Request) {
    switch request.contentDB {
    default:
      meetingsManager.delegate = request.meetingManagerDelegate
      meetingsManager.retrieveMeetings()
    }
  }

  // MARK: - Use Case: Remove meeting from users calendar
  func removeMeetingFromCalendar(request: RootedContent.RemoveFromCalendar.Request) {
    guard let meeting = request.meeting?.data else { return }
    eventKitManager.removeFromCalendar(meeting: meeting) { (mtng, success, error) in
      if let err = error {
        var response = RootedContent.DisplayError.Response()
        response.errorMessage = self.retrieveErrorMessage(err)
        self.presenter?.handleError(response: response)
      } else {
        if success {
          var response = RootedContent.RemoveFromCalendar.Response()
          response.meeting = request.meeting
          self.presenter?.onSuccessfulCalendarRemoval(response: response)
        } else {
          var response = RootedContent.DisplayError.Response()
          response.errorMessage = "Something went wrong. Please try again."
          self.presenter?.handleError(response: response)
        }
      }
    }
  }

  // MARK: - Use Case: As a user, I want to be able to delete a meeting
  func deleteMeeting(request: RootedContent.DeleteMeeting.Request) {
    guard let meeting = request.meeting?.managedObject else { return }
    branchWorker.customEvent(withName: kBranchMeetingDeleteMeeting)
    switch request.contentDB {
    default:
      meetingsManager.delegate = request.meetingManagerDelegate
      meetingsManager.deleteMeeting(meeting)
    }
  }

  // MARK: - Use Case: Go to add an meeting view
  func goToCreateNewMeetingView(request: RootedContent.CreateNewMeeting.Request) {
    let response = RootedContent.CreateNewMeeting.Response()
    presenter?.presentCreateNewMeetingView(response: response)
  }

  // MARK: - Use Case: As a user, when I create a meeting, I want to do the following:
  // - Insert meeting into my on-device apple calendar
  // - Save meeting to local storage/core data
  // - Save meeting to remote storage/firebase
  func saveMeeting(request: RootedContent.SaveMeeting.Request) {
    guard let calendarAccessGranted = isCalendarPermissionGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }
    if calendarAccessGranted {
      guard let meeting = request.meeting else { return }
      switch request.saveType {
      case .receive:
        meeting.dashboardSectionId = 0
      case .send:
        meeting.dashboardSectionId = 1
      default:
        meeting.dashboardSectionId = 2
      }
      branchWorker.customEvent(withName: request.branchEventID)
      switch request.contentDB {
        default:
        self.meetingsManager.createInvite(meeting) { (success, error) in
          if let err = error {
            var response = RootedContent.DisplayError.Response()
            response.errorMessage = self.retrieveErrorMessage(err)
            self.presenter?.handleError(response: response)
          } else {
            if success {
              var response = RootedContent.SaveMeeting.Response()
              response.meeting = meeting
              self.presenter?.onSuccessfulSave(response: response)
            } else {
              var response = RootedContent.DisplayError.Response()
              response.errorMessage = "Something went wrong. Please try again."
              self.presenter?.handleError(response: response)
            }
          }
        }
      }
    } else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
    }
  }

  func addToCalendar(request: RootedContent.AddToCalendar.Request) {
    guard let calendarAccessGranted = isCalendarPermissionGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    if calendarAccessGranted {
      guard let meeting = request.meeting else { return }
      eventKitManager.saveToCalendar(meeting: meeting) { (mtng, success, error) in
        if let err = error {
          var response = RootedContent.DisplayError.Response()
          response.errorMessage = self.retrieveErrorMessage(err)
          self.presenter?.handleError(response: response)
        } else {
          if success {
            var response = RootedContent.AddToCalendar.Response()
            response.meeting = mtng
            self.presenter?.onSuccessfulCalendarAdd(response: response)
          } else {
            var response = RootedContent.DisplayError.Response()
            response.errorMessage = "Something went wrong. Please try again."
            self.presenter?.handleError(response: response)
          }
        }
      }
    } else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
    }
  }
}

// MARK: - Availability Management
extension RootedContentInteractor {
  // Manage Availability objects
//  func insert(_ availability: Availability, completion: @escaping (Bool, Error?) -> Void) {
//    self.saveToCoreData(availability: availability, completion: completion)
//  }
//
//  func saveToCoreData(availability: Availability, completion: @escaping (Bool, Error?) -> Void) {
//    AvailabilityManager().createAvailability(availability, completion)
//  }
}
