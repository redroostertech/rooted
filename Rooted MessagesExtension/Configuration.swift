//
//  Configuration.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Core
public let kAppName = "Rooted"
public let kGroupName = "group.com.rrtech.rooted.Rooted"

public let maximumInvites = 3

// MARK: - Networking
public let kPagination : UInt = 10
public let kMaxConcurrentImageDownloads = 2

public var isDebug = false

public let kLocalBaseURL = "http://localhost:3000/"
public let kTestBaseURL = "https://rooted-test-web.herokuapp.com/"
public let kLiveBaseURL = "https://rootedapp.herokuapp.com/"

public let kLocalURL = kLocalBaseURL + "api/v1/"
public let kTestURL = kTestBaseURL + "api/v1/"
public let kLiveURL = kLiveBaseURL + "api/v1/"

// MARK :- UI + Sizes
public let kJPEGImageQuality : CGFloat = 0.4

public let kIconSizeWidth : CGFloat = 32
public let kIconSizeHeight : CGFloat = 32

public let kPhotoShadowRadius : CGFloat = 10.0
public let kPhotoShadowColor : UIColor = UIColor(white: 0, alpha: 0.1)
public let kProfilePhotoSize : CGFloat = 100

public let kTopOfScreen = UIScreen.main.bounds.minY
public let kBottomOfScreen = UIScreen.main.bounds.maxY
public let kFarLeftOfScreen = UIScreen.main.bounds.minX
public let kFarRightOfScreen = UIScreen.main.bounds.maxX
public let kWidthOfScreen = UIScreen.main.bounds.width
public let kHeightOfScreen = UIScreen.main.bounds.height

public let kSearchTextFieldHeight: CGFloat = 42
public let kContainerViewHeightForMyPicks: CGFloat = 225
public let kRemainingHeightForContainer: CGFloat = 250
public let kAnimationDuration: Double = 2.0

public let kPrimarySpacing: CGFloat = 8.0
public let kPrimaryNoSpacing: CGFloat = 0.0
public let kPrimaryCellHeight: CGFloat = 200.0

public let kBarBtnSize = CGSize(width: 32.0, height: 32.0)
public let kBarBtnPoint = CGPoint(x: 0.0, y: 0.0)

public let kTextFieldPadding: CGFloat = 10.0
public let kTextFieldIndent: CGFloat = 16.0

public let kButtonRadius: CGFloat = 15.0

//  MARK:- UI + Colors
public let kEnabledTextColor: UIColor = .darkText
public let kDisabledTextColor: UIColor = .gray

//  MARK:- UI + Fonts
public let kFontTitle = ""
public let kFontSubHeader = ""
public let kFontMenu = ""
public let kFontBody = ""
public let kFontCaption = ""
public let kFontButton = ""
public var kFontSizeTitle: CGFloat { return 28 }
public var kFontSizeSubHeader: CGFloat { return 24 }
public var kFontSizeMenu: CGFloat { return 18 }
public var kFontSizeBody: CGFloat { return 18 }
public var kFontSizeCaption: CGFloat { return 12 }
public var kFontSizeButton: CGFloat { return 16 }

//  MARK:- UI + Strings
public let kLocationEnabled = "Location services enabled"
public let kLocationDisabled = "Location services not enabled"
public let kNotificationEnabled = "Notification services enabled"
public let kNotificationDisabled = "Notification services not enabled"
public let kLoginText = "Sign In"
public let kSignUpText = "Sign Up"
public let kLoginSwitchText = kLoginText
public let kSignUpSwitchText = kSignUpText
public let kMobileApiAgent = "mobile"
public let kGenericSaving = "Saving"
public let kLoadingPosts = "Loading Posts"
public let kLoadingPost = "Loading Post"
public let kGenericError = "Something went wrong."
public let kLoginError = "Invalid email/password combination. Please try again."
public let kCreatingPost = "Creating Post"

// MARK: - UI + Alerts + Strings
public let kCalendarPermissions = "Calendar Permissions"
public let kCalendarAccess = "To use Rooted, please go to your settings and enable access to your calendar."

// MARK:- Observer Keys
public let kLocationAccessCheckObservationKey = "observeLocationAccessCheck"
public let kSaveLocationObservationKey = "saveLocationObservationKey"
public let kNotificationAccessCheckObservationKey = "observeNotificationAccessCheck"
public let kAddUserObservationKey = "addUserObservationKey"
public let kLoadFirstUserObservationKey = "loadFirstUserObservationKey"

// MARK: - UserDefaults Keys
public let kAuthIsLoggedIn = "isUserLoggedIn"
public let kAuthIsGuestUser = "isGuestUser"

// MARK: - Message Object Keys
public let kMessageTitleKey = "title"
public let kMessageSubCaptionKey = "subcaption"
public let kMessageStartDateKey = "startDate"
public let kMessageEndDateKey = "endDate"
public let kMessageLocationStringKey = "locationString"
public let kMessageLocationNameKey = "locationName"
public let kMessageLocationLatKey = "locationLat"
public let kMessageLocationLonKey = "locationLon"
public let kMessageLocationAddressKey = "locationAddress"
public let kMessageLocationCityKey = "locationCity"
public let kMessageLocationStateKey = "locationState"
public let kMessageLocationCountryKey = "locationCountry"
public let kMessageLocationZipCodeKey = "locationZip"
public let kMessageObjectKey = "meetingJSON"

// MARK: - Storyboard
public let kStoryboardMain = "MainInterface"

// MARK: - ViewControllers
public let kViewControllerAvailability = "AvailabilityViewController"
public let kViewControllerAvailabilityNavigation = "AvailabilityNavigationViewController"
public let kViewControllerMessagesNavigation = "MessagesNavigationController"
public let kMyInvitesViewController = "MyInvitesViewController"
public let kPhoneLoginViewController = "PhoneLoginViewController"
public let kRegistrationViewController = "RegistrationViewController"
public let kInfoViewController = "InfoViewController"
public let kSettingsNavigationController = "SettingsNavigationController"

// MARK: - Segues
public let kGoToDashboardSegue = "goToDashboard"
public let kGoToLoginSegue = "goToLoginSegue"
public let kGoToInviteDetails = "goToInviteDetails"
public let kGoToAddInviteVC = "goToAddInviteVC"

// MARK: - User Experience Strings
public let kDeleteTitle = "Delete Invite"
public let kDeleteMessage = "You are about to delete a meeting invite. Are you sure?"
public let captionString = "%@ on %@"
public let kBackText = "Back"

// MARK: - NotificationCenter Methods
public let kNotificationMyInvitesReload = "MyInvitesViewController.reload"
public let kNotificationKeyboardWillShowNotification = "keyboardWillShowNotification"
public let kNotificationKeyboardWillHideNotification = "keyboardWillHideNotification"

// MARK: - Branch Custom Event Keys
public let kBranchEventSharedConversation = "event_shared_conversation"
public let kBranchEventSharedConversationFailed = "event_shared_conversation_failed"
public let kBranchUserStartedSharingAvailability = "user_started_sharing_availability"
public let kBranchEventAddedAppleCalendar = "event_added_apple_calendar"
public let kBranchAvailabilityAddedCoreData = "availability_added_core_data"
public let kBranchMaximumReached = "maximum_reached"
public let kBranchInviteAccepted = "event_invite_accepted"
public let kBranchMeetingStartedSave = "user_started_save"
public let kBranchMeetingDeleteMeeting = "user_deleted_meeting"

// MARK: - Session strings
public var kSessionUser = "currentUser"
public var kSessionUserId = "currentUserId"
public var kSessionStart = "sessionStart"
public var kSessionLastLogin = "lastLogin"
public var kSessionCart = "sessionCart" // Not in use yet

// MARK: - Entities
public var kEntityMeeting = "MeetingEntity"

// MARK: - Form tags
public var kFormEmailAddress = "emailAddress"
public var kFormEmailPlaceholder = "Enter your email here"
public var kFormPassword = "password"
public var kFormPasswordPlaceholder = "Enter your Password"
public var kFormPhoneNumber = "phoneNumber"
public var kFormPhoneNumberPlaceholder = "Enter your phone number"
public var kFormFullname = "fullName"
public var kFormFullnamePlaceholder = "Provide your full name"
public var kFormCountryCode = "countryCode"

// MARK: - Debug Credentials
public var kDebugEmail = "mwestbrooksjr@gmail.com"
public var kDebugPassword = "abc123456"
public var kDebugFullName = "John Doe"
public var kDebugPhone = "9082178274"
