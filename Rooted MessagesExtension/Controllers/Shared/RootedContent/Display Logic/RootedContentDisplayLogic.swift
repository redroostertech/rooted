//
//  RootedContentDisplayLogic.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 4/30/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation

protocol RootedContentDisplayLogic: class {
  func showHUD()
  func presentPhoneLoginViewController()

  func handleBranchIOResponse(viewModel: RootedContent.SetupBranchIO.ViewModel)
  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel)
  func handleCalendarPermissionsCheck(viewModel: RootedContent.CheckCalendarPermissions.ViewModel)

  func handleMaximumLimitReached(viewModel: RootedContent.CheckMaximumMeetingsReached.ViewModel)
  func presentCreateNewMeetingView(viewModel: RootedContent.CreateNewMeeting.ViewModel)
  func presentInfoView(viewModel: RootedContent.InfoView.ViewModel)
  func handleError(viewModel: RootedContent.DisplayError.ViewModel)

  func onSuccessfulSave(viewModel: RootedContent.SaveMeeting.ViewModel)
  func onSuccessfulCalendarAdd(viewModel: RootedContent.AddToCalendar.ViewModel)

  func onSuccessfulCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel)
  func onFailedCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel)

  func onSuccessfulAvailabilitySave(viewModel: RootedContent.SaveAvailability.ViewModel)

  func onDidFinishLoading(viewModel: RootedContent.RetrieveMeetings.ViewModel)
  func onDidDeleteMeeting(viewModel: RootedContent.DeleteMeeting.ViewModel)

  func onSuccessfulAcceptance(viewModel: RootedContent.AcceptMeeting.ViewModel)

  func onSuccessfulAppleCalendarRead(viewModel: RootedContent.ReadEventsAppleCalendar.ViewModel)
  func onSuccessfulGoogleCalendarRead(viewModel: RootedContent.ReadEventsGoogleCalendar.ViewModel)
  func onSuccessfulOutlookCalendarRead(viewModel: RootedContent.ReadEventsOutlookCalendar.ViewModel)
}

extension RootedContentDisplayLogic {
  func showHUD() { }
  func presentPhoneLoginViewController() { }

  func handleBranchIOResponse(viewModel: RootedContent.SetupBranchIO.ViewModel) { }
  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) { }
  func handleCalendarPermissionsCheck(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) { }
  func handleMaximumLimitReached(viewModel: RootedContent.CheckMaximumMeetingsReached.ViewModel) { }
  func presentCreateNewMeetingView(viewModel: RootedContent.CreateNewMeeting.ViewModel) { }
  func presentInfoView(viewModel: RootedContent.InfoView.ViewModel) { }
  func handleError(viewModel: RootedContent.DisplayError.ViewModel) { }

  func onSuccessfulSave(viewModel: RootedContent.SaveMeeting.ViewModel) { }
  func onSuccessfulCalendarAdd(viewModel: RootedContent.AddToCalendar.ViewModel) { }

  func onSuccessfulCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel) { }
  func onFailedCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel) { }

  func onSuccessfulAvailabilitySave(viewModel: RootedContent.SaveAvailability.ViewModel) { }

  func onDidFinishLoading(viewModel: RootedContent.RetrieveMeetings.ViewModel) { }
  func onDidDeleteMeeting(viewModel: RootedContent.DeleteMeeting.ViewModel) { }

  func onSuccessfulAcceptance(viewModel: RootedContent.AcceptMeeting.ViewModel) { }

  func onSuccessfulAppleCalendarRead(viewModel: RootedContent.ReadEventsAppleCalendar.ViewModel) { }
  func onSuccessfulGoogleCalendarRead(viewModel: RootedContent.ReadEventsGoogleCalendar.ViewModel) { }
  func onSuccessfulOutlookCalendarRead(viewModel: RootedContent.ReadEventsOutlookCalendar.ViewModel) { }
}
