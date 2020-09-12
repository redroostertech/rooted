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
  func checkContactPermissions(request: RootedContent.CheckContactPermissions.Request)
  func getCalendarPermissions(request: RootedContent.CheckCalendarPermissions.Request)
  func retrieveMeetings(request: RootedContent.RetrieveMeetings.Request)
  func retrieveMeetingById(request: RootedContent.RetrieveMeetingById.Request)
  func retrieveSentMeetings(request: RootedContent.RetrieveSentMeetings.Request)
  func deleteMeeting(request: RootedContent.DeleteMeeting.Request)
  func cancelMeeting(request: RootedContent.CancelMeeting.Request)
  func goToCreateNewMeetingView(request: RootedContent.CreateNewMeeting.Request)
  func saveMeeting(request: RootedContent.SaveMeeting.Request)
  func addToCalendar(request: RootedContent.AddToCalendar.Request)
  func checkMaximumMeetingsReached(request: RootedContent.CheckMaximumMeetingsReached.Request)
  func removeMeetingFromCalendar(request: RootedContent.RemoveFromCalendar.Request)
  func retrieveAvailability(request: RootedContent.RetrieveAvailability.Request)
  func saveAvailability(request: RootedContent.SaveAvailability.Request)
  func goToInfoView(request: RootedContent.InfoView.Request)
  func acceptMeeting(request: RootedContent.AcceptMeeting.Request)
  func declineMeeting(request: RootedContent.DeclineMeeting.Request)
  func refreshSession(request: RootedContent.RefreshSession.Request)
  func goToViewCalendar(request: RootedContent.ViewCalendar.Request)
  func editMeeting(request: RootedContent.EditMeeting.Request)
  func retrieveMeetingDrafts(request: RootedContent.RetrieveDraftMeetings.Request)
  func saveMeetingDraft(request: RootedContent.SaveMeetingDraft.Request)
  func updateMeetingDraft(request: RootedContent.UpdateDraft.Request)
  func deleteMeetingDraft(request: RootedContent.DeleteDraftMeeting.Request)
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
  private var contactKitManager = ContactKitManager()
  private var availabilityManager = AvailabilityManager()

  func retrieveErrorMessage(_ error: Error) -> String {
    if let rerror = error as? RError {
      return rerror.localizedDescription
    } else {
      return error.localizedDescription
    }
  }

  // MARK: - Use Case: Refresh session
  func refreshSession(request: RootedContent.RefreshSession.Request) {
    SessionManager.refreshSession()
    let response = RootedContent.RefreshSession.Response()
    presenter?.didRefreshSession(response: response)
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
  func getCalendarPermissions(request: RootedContent.CheckCalendarPermissions.Request) {
    var response = RootedContent.CheckCalendarPermissions.Response()
    eventKitManager.checkCalendarPermissions { granted in
      response.isGranted = granted
      self.isCalendarPermissionGranted = granted
      self.presenter?.handleCalendarPermissionsCheck(response: response)
    }
  }

  func checkCalendarPermissions(request: RootedContent.CheckCalendarPermissions.Request) {
    var response = RootedContent.CheckCalendarPermissions.Response()
    eventKitManager.getCalendarPermissions { granted in
      response.isGranted = granted
      self.isCalendarPermissionGranted = granted
      self.presenter?.handleCalendarPermissions(response: response)
    }
  }

  func checkContactPermissions(request: RootedContent.CheckContactPermissions.Request) {
    var response = RootedContent.CheckContactPermissions.Response()
    contactKitManager.getPermissions { granted in
      response.isGranted = granted
      self.presenter?.handleContactPermissions(response: response)
    }
  }

  // MARK: - Use Case: As a business, we want to limit access to creating more than (n) meetings based on account type
  func checkMaximumMeetingsReached(request: RootedContent.CheckMaximumMeetingsReached.Request) {
    var response = RootedContent.CheckMaximumMeetingsReached.Response()
    guard let userMeetings = SessionManager.shared.currentUser?.meetings, let userAccount = SessionManager.shared.currentUser?.accountType?.first else {
      response.isMaximumumReached = false
      self.presenter?.handleMaximumLimitReached(response: response)
      return
    }

    if userMeetings.count >= userAccount.maximumEventsCount ?? 3 {
      self.branchWorker.customEvent(withName: kBranchMaximumReached)
      response.isMaximumumReached = true
      self.presenter?.handleMaximumLimitReached(response: response)
    } else {
      response.isMaximumumReached = false
      self.presenter?.handleMaximumLimitReached(response: response)
    }
  }

  // MARK: - Use Case: Retrieve meetings for user
  func retrieveMeetings(request: RootedContent.RetrieveMeetings.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }
    switch request.contentDB {
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: String] = [
        "action": "retrieve_upcoming_meetings_for_user",
        "uid": userId,
        "date": request.date == nil ? Date().toString() : request.date!.toString()
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let data = resultsDict["data"] as? [String: Any] {
                                        var response = RootedContent.RetrieveMeetings.Response()
                                        response.meetings = (data["meetings"] as? [[String: Any]]).map({ dicts -> [MeetingContextWrapper] in
                                          var array = [MeetingContextWrapper]()
                                          for dict in dicts {
                                            if let meeting = Meeting(JSON: dict) {
                                              let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: nil)
                                              array.append(meetingWrapper)
                                            }
                                          }
                                          return array
                                        })?.sorted(by: { $0.meeting?.meetingDate?.startDate?.toDate()?.date ?? Date() < $1.meeting?.meetingDate?.startDate?.toDate()?.date ?? Date() }) ?? [MeetingContextWrapper]()

                                        // Refresh removed meeting
                                        SessionManager.refreshSession()

                                        self.presenter?.onDidFinishLoading(response: response)
                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "No data is available."
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
    default:
      self.meetingsManager.delegate = request.meetingManagerDelegate
      self.meetingsManager.retrieveMeetings()
    }
  }

  // MARK: - Use Case: Retrieve meetings for user
  func retrieveMeetingById(request: RootedContent.RetrieveMeetingById.Request) {
    guard SessionManager.shared.sessionExists, let meetingId = request.meetingId else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }
    switch request.contentDB {
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: String] = [
        "action": "retrieve_meeting_for_id",
        "meetingId": meetingId
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let data = resultsDict["data"] as? [String: Any] {
                                        var response = RootedContent.RetrieveMeetings.Response()
                                        response.meetings = (data["meetings"] as? [[String: Any]]).map({ dicts -> [MeetingContextWrapper] in
                                          var array = [MeetingContextWrapper]()
                                          for dict in dicts {
                                            if let meeting = Meeting(JSON: dict) {
                                              let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: nil)
                                              array.append(meetingWrapper)
                                            }
                                          }
                                          return array
                                        }) ?? [MeetingContextWrapper]()

                                        // Refresh removed meeting
                                        SessionManager.refreshSession()

                                        self.presenter?.onDidFinishLoading(response: response)
                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "No data is available."
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
    default:
      self.meetingsManager.delegate = request.meetingManagerDelegate
      self.meetingsManager.retrieveMeetings()
    }
  }

  // MARK: - Use Case: Retrieve meetings sent by user
  func retrieveSentMeetings(request: RootedContent.RetrieveSentMeetings.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    switch request.contentDB {
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: String] = [
        "action": "retrieve_sent_meetings_for_user",
        "uid": userId
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let data = resultsDict["data"] as? [String: Any] {
                                        var response = RootedContent.RetrieveMeetings.Response()
                                        response.meetings = (data["meetings"] as? [[String: Any]]).map({ dicts -> [MeetingContextWrapper] in
                                          var array = [MeetingContextWrapper]()
                                          for dict in dicts {
                                            if let meeting = Meeting(JSON: dict) {
                                              let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: nil)
                                              array.append(meetingWrapper)
                                            }
                                          }

                                          return array
                                        }) ?? [MeetingContextWrapper]()

                                        // Refresh removed meeting
                                        SessionManager.refreshSession()

                                        self.presenter?.onDidFinishLoading(response: response)
                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "No data is available."
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
    default:
      self.meetingsManager.delegate = request.meetingManagerDelegate
      self.meetingsManager.retrieveMeetings()
    }
  }

  // MARK: - Use Case: As a user, I want to be able to delete a meeting
  func deleteMeeting(request: RootedContent.DeleteMeeting.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let meeting = request.meeting?.data, let meetingId = meeting.id, let _ = meeting.ownerId else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

    branchWorker.customEvent(withName: kBranchMeetingDeleteMeeting)
    switch request.contentDB {
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: String] = [
        "action": "delete_meeting",
        "meeting_id": meetingId,
        "owner_id": userId
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {

                                      var response = RootedContent.DeleteMeeting.Response()
                                      response.meeting = request.meeting

                                      // Refresh removed meeting
                                      SessionManager.refreshSession()

                                      self.presenter?.onDidDeleteMeeting(response: response)

                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
    default:
      guard let managedObject = request.meeting?.managedObject else { return }
      meetingsManager.delegate = request.meetingManagerDelegate
      meetingsManager.deleteMeeting(managedObject)
    }
  }

  // MARK: - Use Case: As a user, I want to be able to cancel a meeting
  func cancelMeeting(request: RootedContent.CancelMeeting.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let meeting = request.meeting?.data, let meetingId = meeting.id else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

    branchWorker.customEvent(withName: kBranchMeetingDeleteMeeting)
    switch request.contentDB {
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: Any] = [
        "action": "cancel_meeting",
        "meeting_id": meetingId,
        "user_id": userId
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {

                                      var response = RootedContent.CancelMeeting.Response()
                                      response.meeting = request.meeting

                                      // Refresh removed meeting
                                      SessionManager.refreshSession()

                                      self.presenter?.onDidCancelMeeting(response: response)

                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
    default:
      guard let meeting = request.meeting?.managedObject else { return }
      meetingsManager.delegate = request.meetingManagerDelegate
      meetingsManager.deleteMeeting(meeting)
    }
  }

  // MARK: - Use Case: Remove meeting from users calendar
  func removeMeetingFromCalendar(request: RootedContent.RemoveFromCalendar.Request) {
    
    guard SessionManager.shared.sessionExists, let _ = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let meeting = request.meeting else { return }
    eventKitManager.removeFromCalendar(meeting: meeting) { (mtng, success, error) in
      if let err = error {
        var response = RootedContent.RemoveFromCalendar.Response()
        response.errorMessage = self.retrieveErrorMessage(err)
        self.presenter?.onFailedCalendarRemoval(response: response)
      } else {
        if success {
          var response = RootedContent.RemoveFromCalendar.Response()
          response.meeting = request.meeting
          self.presenter?.onSuccessfulCalendarRemoval(response: response)
        } else {
          var response = RootedContent.RemoveFromCalendar.Response()
          response.errorMessage = "Something went wrong. Please try again."
          self.presenter?.onFailedCalendarRemoval(response: response)
        }
      }
    }
  }

  // MARK: - Use Case: As a user, when I create a meeting, I want to save it
  func saveMeeting(request: RootedContent.SaveMeeting.Request) {
    guard SessionManager.shared.sessionExists, let _ = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    guard let meeting = request.meeting, let _ = meeting.id else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

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
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: Any] = [
        "action": "save_meeting",
        "data": meeting.toJSONString()!,
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    error.meeting = meeting
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    error.meeting = meeting
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let _ = resultsDict["data"] as? [String: Any] {
                                        var response = RootedContent.SaveMeeting.Response()
                                        response.meeting = meeting
                                        response.contentDB = request.contentDB
                                        SessionManager.refreshSession()
                                        self.presenter?.onSuccessfulSave(response: response)
                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "Something went wrong. Please try again."
                                        error.errorTitle = "Oops!"
                                        error.meeting = meeting
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      error.errorTitle = "Oops!"
                                      error.meeting = meeting
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
      default:
      self.meetingsManager.delegate = request.meetingManagerDelegate
      self.meetingsManager.createInvite(meeting) { (success, error) in
        if let err = error {
          var response = RootedContent.DisplayError.Response()
          response.errorMessage = self.retrieveErrorMessage(err)
          self.presenter?.handleError(response: response)
        } else {
          if success {
            var response = RootedContent.SaveMeeting.Response()
            response.meeting = meeting
            response.contentDB = request.contentDB
            self.presenter?.onSuccessfulSave(response: response)
          } else {
            var response = RootedContent.DisplayError.Response()
            response.errorMessage = "Something went wrong. Please try again."
            self.presenter?.handleError(response: response)
          }
        }
      }
    }
  }

  // MARK: - Use Case: As a user, I want to insert meeting into my on-device apple calendar
  func addToCalendar(request: RootedContent.AddToCalendar.Request) {

    guard SessionManager.shared.sessionExists, let _ = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    guard let meeting = request.meeting, let _ = meeting.id else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

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
  }

  // MARK: - Use Case: As a user I want to accpet a meeting I receive
  func acceptMeeting(request: RootedContent.AcceptMeeting.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    guard let meeting = request.meeting, let meetingId = meeting.id else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

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
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: Any] = [
        "action": "accept_meeting",
        "meeting_id": meetingId,
        "user_id": userId,
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let _ = resultsDict["data"] as? [String: Any] {

                                        var response = RootedContent.AcceptMeeting.Response()
                                        response.meeting = meeting

                                        // Refresh removed meeting
                                        SessionManager.refreshSession()

                                        self.presenter?.onSuccessfulAcceptance(response: response)

                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "Something went wrong. Please try again."
                                        error.errorTitle = "Oops!"
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      error.errorTitle = "Oops!"
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
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
  }

  // MARK: - Use Case: As a user I want to decline a meeting I receive
  func declineMeeting(request: RootedContent.DeclineMeeting.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    guard let meeting = request.meeting, let meetingId = meeting.id else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

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
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: Any] = [
        "action": "decline_meeting",
        "meeting_id": meetingId,
        "user_id": userId,
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let _ = resultsDict["data"] as? [String: Any] {

                                        var response = RootedContent.DeclineMeeting.Response()
                                        response.meeting = meeting

                                        // Refresh removed meeting
                                        SessionManager.refreshSession()

                                        self.presenter?.onSuccessfulDecline(response: response)

                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "Something went wrong. Please try again."
                                        error.errorTitle = "Oops!"
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      error.errorTitle = "Oops!"
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
      default:
        var response = RootedContent.DisplayError.Response()
        response.errorMessage = "Something went wrong. Please try again."
        self.presenter?.handleError(response: response)
    }
  }

  // MARK: - Use Case: As a user I want to edit a meeting
  func editMeeting(request: RootedContent.EditMeeting.Request) {

  }
}

// MARK: - Drafts
extension RootedContentInteractor {
  // MARK: - Use Case: Retrieve draft meetings created by user
  func retrieveMeetingDrafts(request: RootedContent.RetrieveDraftMeetings.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    switch request.contentDB {
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: String] = [
        "action": "retrieve_meeting_drafts_for_user",
        "uid": userId
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let data = resultsDict["data"] as? [String: Any] {
                                        var response = RootedContent.RetrieveMeetings.Response()
                                        response.meetings = (data["meetings"] as? [[String: Any]]).map({ dicts -> [MeetingContextWrapper] in
                                          var array = [MeetingContextWrapper]()
                                          for dict in dicts {
                                            if let meeting = Meeting(JSON: dict) {
                                              let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: nil)
                                              array.append(meetingWrapper)
                                            }
                                          }

                                          return array
                                        }) ?? [MeetingContextWrapper]()

                                        // Refresh removed meeting
                                        SessionManager.refreshSession()

                                        self.presenter?.onDidFinishLoading(response: response)
                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "No data is available."
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
    default:
      self.meetingsManager.delegate = request.meetingManagerDelegate
      self.meetingsManager.retrieveMeetings()
    }
  }

  // MARK: - Use Case: As a user, I want to be able to delete a draft meeting
  func deleteMeetingDraft(request: RootedContent.DeleteDraftMeeting.Request) {
    guard SessionManager.shared.sessionExists, let userId = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let meeting = request.meeting?.data, let meetingId = meeting.id, let _ = meeting.ownerId else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

    branchWorker.customEvent(withName: kBranchMeetingDeleteMeeting)
    switch request.contentDB {
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: String] = [
        "action": "delete_meeting",
        "meeting_id": meetingId,
        "owner_id": userId
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {

                                      var response = RootedContent.DeleteMeeting.Response()
                                      response.meeting = request.meeting

                                      // Refresh removed meeting
                                      SessionManager.refreshSession()

                                      self.presenter?.onDidDeleteMeeting(response: response)

                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
    default:
      guard let meetingContext = request.meetingContext, let managedObject = meetingContext.managedObject else {
        var response = RootedContent.DisplayError.Response()
        response.errorMessage = "Something went wrong. Please try again."
        self.presenter?.handleError(response: response)
        return
      }

      branchWorker.customEvent(withName: kBranchMeetingDeleteMeeting)
      meetingsManager.delegate = request.meetingManagerDelegate
      meetingsManager.deleteDraftMeeting(managedObject)
    }
  }

  // MARK: - Use Case: As a user I want to edit a draft meeting
  func updateMeetingDraft(request: RootedContent.UpdateDraft.Request) {
    guard SessionManager.shared.sessionExists else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    guard let managedObject = request.meeting?.managedObject, let meetingJson = request.meeting?.meeting?.toJSONString() else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }
    meetingsManager.updateMeeting(managedObject, withValue: meetingJson, forKey: "object") { (success, error) in
      RRLogger.log(message: "Updating meeting \(String(describing: managedObject.value(forKey: "object")))", owner: self)
    }
  }

  // MARK: - Use Case: As a user, when I create a draft meeting, I want to save it
  func saveMeetingDraft(request: RootedContent.SaveMeetingDraft.Request) {
    guard SessionManager.shared.sessionExists, let _ = SessionManager.shared.currentUser?.uid else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    guard let meeting = request.meeting, let _ = meeting.id else {
      var response = RootedContent.DisplayError.Response()
      response.errorMessage = "Something went wrong. Please try again."
      self.presenter?.handleError(response: response)
      return
    }

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
    case .remote:
      let path = PathBuilder.build(.Test, in: .Core, with: "eggman")
      let params: [String: Any] = [
        "action": "save_draft",
        "data": meeting.toJSONString()!,
      ]
      let apiService = Api()
      apiService.performRequest(path: path,
                                method: .post,
                                parameters: params) { (results, error) in

                                  guard error == nil else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    error.meeting = meeting
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  guard let resultsDict = results as? [String: Any] else {
                                    RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                    var error = RootedContent.DisplayError.Response()
                                    error.errorMessage = "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    error.meeting = meeting
                                    self.presenter?.handleError(response: error)
                                    return
                                  }

                                  RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                  if let success = resultsDict["success"] as? Bool {
                                    if success {
                                      if let _ = resultsDict["data"] as? [String: Any] {
                                        var response = RootedContent.SaveMeetingDraft.Response()
                                        response.meeting = meeting
                                        response.contentDB = request.contentDB

                                        // Refresh removed meeting
                                        SessionManager.refreshSession()

                                        self.presenter?.onSuccessfulDraftSave(response: response)
                                      } else {
                                        var error = RootedContent.DisplayError.Response()
                                        error.errorMessage = "Something went wrong. Please try again."
                                        error.errorTitle = "Oops!"
                                        error.meeting = meeting
                                        self.presenter?.handleError(response: error)
                                      }
                                    } else {
                                      var error = RootedContent.DisplayError.Response()
                                      error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                      error.errorTitle = "Oops!"
                                      error.meeting = meeting
                                      self.presenter?.handleError(response: error)
                                    }
                                  }
      }
      default:
      self.meetingsManager.delegate = request.meetingManagerDelegate
      self.meetingsManager.createInvite(meeting) { (success, error) in
        if let err = error {
          var response = RootedContent.DisplayError.Response()
          response.errorMessage = self.retrieveErrorMessage(err)
          self.presenter?.handleError(response: response)
        } else {
          if success {
            var response = RootedContent.SaveMeeting.Response()
            response.meeting = meeting
            response.contentDB = request.contentDB
            self.presenter?.onSuccessfulSave(response: response)
          } else {
            var response = RootedContent.DisplayError.Response()
            response.errorMessage = "Something went wrong. Please try again."
            self.presenter?.handleError(response: response)
          }
        }
      }
    }
  }
}

// MARK: - Navigation
extension RootedContentInteractor {
  // MARK: - Use Case: Go to add an meeting view
  func goToCreateNewMeetingView(request: RootedContent.CreateNewMeeting.Request) {
    guard SessionManager.shared.sessionExists else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    var response = RootedContent.CreateNewMeeting.Response()
    response.draftMeeting = request.draftMeeting
    self.presenter?.presentCreateNewMeetingView(response: response)
  }

  // MARK: - Use Case: Go to `InfoViewController`
  func goToInfoView(request: RootedContent.InfoView.Request) {
   guard SessionManager.shared.sessionExists else {
     self.presenter?.onPresentPhoneLoginViewController()
     return
   }

   guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
     let request = RootedContent.CheckCalendarPermissions.Request()
     self.checkCalendarPermissions(request: request)
     return
   }

   let response = RootedContent.InfoView.Response()
   self.presenter?.presentInfoView(response: response)
  }

  // MARK: - Use Case: Go to `ViewCalendarViewController`
  func goToViewCalendar(request: RootedContent.ViewCalendar.Request) {
    guard SessionManager.shared.sessionExists else {
      self.presenter?.onPresentPhoneLoginViewController()
      return
    }

    guard let calendarAccessGranted = isCalendarPermissionGranted, calendarAccessGranted else {
      let request = RootedContent.CheckCalendarPermissions.Request()
      self.checkCalendarPermissions(request: request)
      return
    }

    let response = RootedContent.ViewCalendar.Response()
    self.presenter?.presentViewCalendar(response: response)
  }

}

extension RootedContentInteractor {
  // MARK: - Use Case: Retrieve availability for user
  func retrieveAvailability(request: RootedContent.RetrieveAvailability.Request) {
    switch request.contentDB {
    default:
      availabilityManager.delegate = request.availabilityManagerDelegate
      availabilityManager.retrieveAvailability()
    }
  }

  // MARK: - Use Case: Save availability for user
  func saveAvailability(request: RootedContent.SaveAvailability.Request) {
    guard let availability = request.availability else { return }
    branchWorker.customEvent(withName: request.branchEventID)
    switch request.contentDB {
    default:
      self.availabilityManager.createAvailability(availability) { (success, error) in
        if let err = error {
          var response = RootedContent.DisplayError.Response()
          response.errorMessage = self.retrieveErrorMessage(err)
          self.presenter?.handleError(response: response)
        } else {
          if success {
            var response = RootedContent.SaveAvailability.Response()
            response.availability = availability
            self.presenter?.onSuccessfulAvailabilitySave(response: response)
          } else {
            var response = RootedContent.DisplayError.Response()
            response.errorMessage = "Something went wrong. Please try again."
            self.presenter?.handleError(response: response)
          }
        }
      }
    }
  }

  // MARK: - Use Case: Delete availability for user
  func deleteAvailability(request: RootedContent.DeleteAvailability.Request) {
    guard let availabilityManagedObject = request.availability?.managedObject else { return }
//    branchWorker.customEvent(withName: kBranchMeetingDeleteMeeting)
    switch request.contentDB {
    default:
      availabilityManager.delegate = request.availabilityManagerDelegate
      availabilityManager.deleteAvailability(availabilityManagedObject )
    }
  }
}

extension Sequence {
    func groupSort(ascending: Bool = true, byDate dateKey: (Iterator.Element) -> Date) -> [[Iterator.Element]] {
        var categories: [[Iterator.Element]] = []
        for element in self {
            let key = dateKey(element)
            guard let dayIndex = categories.index(where: { $0.contains(where: { Calendar.current.isDate(dateKey($0), inSameDayAs: key) }) }) else {
                guard let nextIndex = categories.index(where: { $0.contains(where: { dateKey($0).compare(key) == (ascending ? .orderedDescending : .orderedAscending) }) }) else {
                    categories.append([element])
                    continue
                }
                categories.insert([element], at: nextIndex)
                continue
            }

            guard let nextIndex = categories[dayIndex].index(where: { dateKey($0).compare(key) == (ascending ? .orderedDescending : .orderedAscending) }) else {
                categories[dayIndex].append(element)
                continue
            }
            categories[dayIndex].insert(element, at: nextIndex)
        }
        return categories
    }
}
