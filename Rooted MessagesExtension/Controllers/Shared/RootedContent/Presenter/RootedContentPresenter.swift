//
//  RootedContentPresenter.swift
//  Rooted
//
//  Created by Michael Westbrooks on 4/30/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol RootedContentPresentationLogic {
  func onPresentPhoneLoginViewController()

  func handleBranchIOResponse(response: RootedContent.SetupBranchIO.Response)
  func handleCalendarPermissions(response: RootedContent.CheckCalendarPermissions.Response)
  func handleCalendarPermissionsCheck(response: RootedContent.CheckCalendarPermissions.Response)
  func handleMaximumLimitReached(response: RootedContent.CheckMaximumMeetingsReached.Response)

  func presentCreateNewMeetingView(response: RootedContent.CreateNewMeeting.Response)
  func presentInfoView(response: RootedContent.InfoView.Response)

  func handleError(response: RootedContent.DisplayError.Response)
  func onSuccessfulSave(response: RootedContent.SaveMeeting.Response)
  func onSuccessfulCalendarAdd(response: RootedContent.AddToCalendar.Response)

  func onSuccessfulCalendarRemoval(response: RootedContent.RemoveFromCalendar.Response)

  func onSuccessfulAvailabilitySave(response: RootedContent.SaveAvailability.Response)

}

extension RootedContentPresentationLogic {
  func onPresentPhoneLoginViewController() { }

  func handleBranchIOResponse(response: RootedContent.SetupBranchIO.Response) { }
  func handleCalendarPermissions(response: RootedContent.CheckCalendarPermissions.Response) { }
  func handleCalendarPermissionsCheck(response: RootedContent.CheckCalendarPermissions.Response) { }
  func handleMaximumLimitReached(response: RootedContent.CheckMaximumMeetingsReached.Response) { }
  func presentCreateNewMeetingView(response: RootedContent.CreateNewMeeting.Response) { }
  func presentInfoView(response: RootedContent.InfoView.Response) { }

  func handleError(response: RootedContent.DisplayError.Response) { }

  func onSuccessfulSave(response: RootedContent.SaveMeeting.Response) { }
  func onSuccessfulCalendarAdd(response: RootedContent.AddToCalendar.Response) { }
  func onSuccessfulCalendarRemoval(response: RootedContent.RemoveFromCalendar.Response) { }

  func onSuccessfulAvailabilitySave(response: RootedContent.SaveAvailability.Response) { }
}

class RootedContentPresenter: RootedContentPresentationLogic {
  weak var viewController: RootedContentDisplayLogic?

  // MARK: - Use Case: Initialize session of BranchIO and handle response
  func handleBranchIOResponse(response: RootedContent.SetupBranchIO.Response) {
    var viewModel = RootedContent.SetupBranchIO.ViewModel()
    viewModel.meeting = response.meeting
    viewController?.handleBranchIOResponse(viewModel: viewModel)
  }

  // MARK: - Use Case: Check if app has access to calendar permissions
  func handleCalendarPermissions(response: RootedContent.CheckCalendarPermissions.Response) {
    var viewModel = RootedContent.CheckCalendarPermissions.ViewModel()
    viewModel.isGranted = response.isGranted
    viewController?.handleCalendarPermissions(viewModel: viewModel)
  }

  func handleCalendarPermissionsCheck(response: RootedContent.CheckCalendarPermissions.Response) {
    var viewModel = RootedContent.CheckCalendarPermissions.ViewModel()
    viewModel.isGranted = response.isGranted
    viewController?.handleCalendarPermissionsCheck(viewModel: viewModel)
  }

  // MARK: - Use Case: As a business, we want to limit access to creating more than (n) meetings based on account type
  func handleMaximumLimitReached(response: RootedContent.CheckMaximumMeetingsReached.Response) {
    var viewModel = RootedContent.CheckMaximumMeetingsReached.ViewModel()
    viewModel.isMaximumumReached = response.isMaximumumReached
    if response.isMaximumumReached {
      viewModel.errorTitle = "Maximum Reached"
      viewModel.errorMessage = "At this time, you can only create 3 meetings. Please delete old meetings or meetings not in use and try again."
    }
    viewController?.handleMaximumLimitReached(viewModel: viewModel)
  }

  // MARK: - Use Case: Go to add an meeting view
  func presentCreateNewMeetingView(response: RootedContent.CreateNewMeeting.Response) {
    let viewModel = RootedContent.CreateNewMeeting.ViewModel()
    viewController?.presentCreateNewMeetingView(viewModel: viewModel)
  }

  // MARK: - Use Case: Go to `InfoViewController`
  func presentInfoView(response: RootedContent.InfoView.Response) {
    let viewModel = RootedContent.InfoView.ViewModel()
    viewController?.presentInfoView(viewModel: viewModel)
  }

  // MARK: - Use Case: Handle an error
  func handleError(response: RootedContent.DisplayError.Response) {
    var viewModel = RootedContent.DisplayError.ViewModel()
    viewModel.errorTitle = response.errorTitle
    viewModel.errorMessage = response.errorMessage
    viewController?.handleError(viewModel: viewModel)
  }

  func onSuccessfulSave(response: RootedContent.SaveMeeting.Response) {
    var viewModel = RootedContent.SaveMeeting.ViewModel()
    viewModel.meeting = response.meeting
    viewController?.onSuccessfulSave(viewModel: viewModel)
  }

  func onSuccessfulCalendarAdd(response: RootedContent.AddToCalendar.Response) {
    var viewModel = RootedContent.AddToCalendar.ViewModel()
    viewModel.meeting = response.meeting
    viewController?.onSuccessfulCalendarAdd(viewModel: viewModel)
  }

  func onSuccessfulCalendarRemoval(response: RootedContent.RemoveFromCalendar.Response) {
    var viewModel = RootedContent.RemoveFromCalendar.ViewModel()
    viewModel.meeting = response.meeting
    viewController?.onSuccessfulCalendarRemoval(viewModel: viewModel)
  }

  func onSuccessfulAvailabilitySave(response: RootedContent.SaveAvailability.Response) {
    var viewModel = RootedContent.SaveAvailability.ViewModel()
    viewModel.availability = response.availability
    viewController?.onSuccessfulAvailabilitySave(viewModel: viewModel)
  }

  func onPresentPhoneLoginViewController() {
    viewController?.presentPhoneLoginViewController()
  }
}
