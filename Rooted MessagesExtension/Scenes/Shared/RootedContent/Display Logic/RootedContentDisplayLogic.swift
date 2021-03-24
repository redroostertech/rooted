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
  func dismissHUD()

  func presentPhoneLoginViewController()

  func handleBranchIOResponse(viewModel: RootedContent.SetupBranchIO.ViewModel)

  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel)
  func handleCalendarPermissionsCheck(viewModel: RootedContent.CheckCalendarPermissions.ViewModel)

  func handleContactPermissions(viewModel: RootedContent.CheckContactPermissions.ViewModel)
  func handleContactPermissionsCheck(viewModel: RootedContent.CheckContactPermissions.ViewModel)

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
  func onDidCancelMeeting(viewModel: RootedContent.CancelMeeting.ViewModel)

  func onSuccessfulAcceptance(viewModel: RootedContent.AcceptMeeting.ViewModel)
  func onSuccessfulDecline(viewModel: RootedContent.DeclineMeeting.ViewModel)

  func didRefreshSession(viewModel: RootedContent.RefreshSession.ViewModel)

  func presentViewCalendar(viewModel: RootedContent.ViewCalendar.ViewModel)

  func onSuccessfulDraftSave(viewModel: RootedContent.SaveMeetingDraft.ViewModel)
    
     func onDidFinishFetching(viewModel: RootedContent.FetchCalendarMeetings.ViewModel)
}

extension RootedContentDisplayLogic {
  func showHUD() { }
  func dismissHUD() { }
  func presentPhoneLoginViewController() { }

  func handleBranchIOResponse(viewModel: RootedContent.SetupBranchIO.ViewModel) { }

  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) { }
  func handleCalendarPermissionsCheck(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) { }

  func handleContactPermissions(viewModel: RootedContent.CheckContactPermissions.ViewModel) { }
  func handleContactPermissionsCheck(viewModel: RootedContent.CheckContactPermissions.ViewModel) { }

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
  func onDidCancelMeeting(viewModel: RootedContent.CancelMeeting.ViewModel) { }

  func onSuccessfulAcceptance(viewModel: RootedContent.AcceptMeeting.ViewModel) { }
  func onSuccessfulDecline(viewModel: RootedContent.DeclineMeeting.ViewModel) { }

  func didRefreshSession(viewModel: RootedContent.RefreshSession.ViewModel) { }

  func presentViewCalendar(viewModel: RootedContent.ViewCalendar.ViewModel) { }

  func onSuccessfulDraftSave(viewModel: RootedContent.SaveMeetingDraft.ViewModel) { }
    
    func onDidFinishFetching(viewModel: RootedContent.FetchCalendarMeetings.ViewModel) { }
}
