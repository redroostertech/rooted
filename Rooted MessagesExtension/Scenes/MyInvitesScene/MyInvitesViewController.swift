import UIKit
import Messages
import iMessageDataKit
import EventKit
import MapKit
import NotificationCenter
import CoreData
import Branch
import OnboardKit
import Aztec
import WordPressEditor
import EggRating

class MyInvitesViewController: ResponsiveViewController, RootedContentDisplayLogic, MeetingsManagerDelegate, RootedCellDelegate, FloatingMenuBtnAction, AuthenticationLogic {

  // MARK: - IBOutlets
  @IBOutlet private weak var refreshButton: UIButton!
  @IBOutlet private weak var calendarButton: UIButton!
  @IBOutlet private weak var segmentedControl: ScrollableSegmentedControl!
  @IBOutlet private weak var segmentControlHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var collectionView: UICollectionView!
  @IBOutlet private weak var menuButton: UIButton!
  @IBOutlet private weak var welcomeLabel: UILabel!
  @IBOutlet private weak var welcomeLabelHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var activityCountLabel: UILabel!
  @IBOutlet private weak var activityCountLabelHeightConstraint: NSLayoutConstraint!

  // Floating Menu
  public var floatingMenu: FloatingMenuBtn?
  public var toggleMenuButton = false
  private var menuSelection = 0
  private var menuItemImages: [UIImage] {
    if isDebug {
    return [UIImage(named: "calendar-plus-sm")!, UIImage(named: "gear-outlined-symbol-sm")!, UIImage(named: "nine-oclock-on-circular-clock-sm")!, UIImage(named: "cube-of-notes-stack-sm")!]
    } else {
      return [UIImage(named: "calendar-plus-sm")!, UIImage(named: "gear-outlined-symbol-sm")!]
    }
  }

  // MARK: - Private Properties
  private var interactor: RootedContentBusinessLogic?

  // MARK: - Public Propreties
  public var anonymousUser: UserProfileData?

  // MARK: - Lifecycle methods
  static func setupViewController() -> MyInvitesViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "MyInvitesViewController") as! MyInvitesViewController
    return viewController
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    let viewController = self
    let interactor = RootedContentInteractor()
    let presenter = RootedContentPresenter()
    viewController.interactor = interactor
    interactor.presenter = presenter
    presenter.viewController = viewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    NotificationCenter.default.addObserver(self, selector: #selector(refreshMeetings), name: Notification.Name(rawValue: kNotificationMyInvitesReload), object: nil)
  }

  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)
    refreshSession()
    setupBranchIO()
    setupConversationManager(using: conversation)
  }

  override func didBecomeActive(with conversation: MSConversation) {
    super.didBecomeActive(with: conversation)
    log(presentationStyle: presentationStyle)
    switch presentationStyle {
    case .compact, .transcript:
      self.configureCompactUI()
      break
    default:
      self.configureDefaultUI()
      break
    }
  }

  override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    super.willTransition(to: presentationStyle)
    log(presentationStyle: presentationStyle)
    switch presentationStyle {
    case .compact, .transcript:
      self.configureCompactUI()
      break
    default:
      self.configureDefaultUI()
      break
    }
  }

  override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    super.didTransition(to: presentationStyle)
    log(presentationStyle: presentationStyle)
    switch presentationStyle {
    case .compact, .transcript:
      self.hideFloatingMenuButton()
      self.configureCompactUI()
      break
    default:
      self.setupManagedSession()
      self.setupMenuButton()
      self.configureDefaultUI()
      break
    }
  }

  // MARK: - Use Case: Setup the UI for the view
  private func setupUI() {
    setup(collectionView: collectionView)
    setupSegmentedControl()
    setupMenuButton()
  }

  private func setupMenuButton() {
    menuButton.applyCornerRadius()
    menuButton.imageView?.contentMode = .scaleAspectFit
    menuButton.backgroundColor = .systemOrange
    menuButton.tintColor = .white

    setupFloatingMenuButton()
  }

  private func setupFloatingMenuButton() {
    if toggleMenuButton {
      self.floatingMenu = FloatingMenuBtn(parentView: self.view, mainButton: self.menuButton, images: self.menuItemImages)
      self.floatingMenu?.delegate = self
      self.floatingMenu?.toggleMenu()
    }
  }

  private func hideFloatingMenuButton() {
    toggleMenuButton = false
    floatingMenu?.isOpen = true
    floatingMenu?.toggleMenu()
  }

  private func setupSegmentedControl() {
    segmentedControl.segmentStyle = .textOnly
    segmentedControl.insertSegment(withTitle: "Upcoming", image: nil, at: 0)
    segmentedControl.insertSegment(withTitle: "Sent", image: nil, at: 1)
    segmentedControl.underlineHeight = 3.0
    segmentedControl.tintColor = .darkGray
    segmentedControl.underlineSelected = true
    segmentedControl.selectedSegmentIndex = menuSelection
    segmentedControl.fixedSegmentWidth = true
    segmentedControl.addTarget(self, action: #selector(self.segmentSelected(sender:)), for: .valueChanged)
  }

  private func configureCompactUI() {
    // Set layout option
    layoutOption = .horizontalList

    // Hide segment control
    hideSegmentControl()

    // Clear `UITableView`
    clearTable()

    // Hide top buttons
    hideTopBarButtons()

    // Hide `WelcomeLabel`
    hideWelcomeLabel()

    // Hide `ActivityCountLabel`
    hideActivityCountLabel()
  }

  private func configureDefaultUI() {
    // Set layout option
    layoutOption = .list

    // Show segment control
    showSegmentControl()

    // Clear `UITableView`
    clearTable()

    // Show top buttons
    showTopBarButtons()

    // Show `WelcomeLabel`
    showWelcomeLabel()

    // Show `ActivityCountLabel`
    showActivityCountLabel()
  }

  private func hideTopBarButtons() {
    // Hide `CalendarButton`
    hideCalendarButton()

    // Hide `RefreshButton`
    hideRefreshButton()
  }

  private func showTopBarButtons() {
    // Show `RefreshButton`
    showRefreshButton()

    // Show `CalendarButton`
    showCalendarButton()
  }

  private func hideCalendarButton() {
    calendarButton.isHidden = true
  }

  private func showCalendarButton() {
    calendarButton.isHidden = false
  }

  private func hideRefreshButton() {
    refreshButton.isHidden = true
  }

  private func showRefreshButton() {
    refreshButton.isHidden = false
  }

  private func hideSegmentControl() {
    segmentControlHeightConstraint.constant = 0
  }

  private func showSegmentControl() {
    segmentControlHeightConstraint.constant = 49
  }

  private func hideWelcomeLabel() {
    welcomeLabelHeightConstraint.constant = 0
  }

  private func showWelcomeLabel() {
    welcomeLabelHeightConstraint.constant = 55
  }

  private func hideActivityCountLabel() {
    activityCountLabelHeightConstraint.constant = 0
  }

  private func showActivityCountLabel() {
    activityCountLabelHeightConstraint.constant = 21
  }

  // MARK: - Use Case: Refresh session
  func refreshSession() {
    let request = RootedContent.RefreshSession.Request()
    interactor?.refreshSession(request: request)
  }

  func didRefreshSession(viewModel: RootedContent.RefreshSession.ViewModel) {
    // Did finish refreshing session
  }

  // MARK: - Use Case: Initialize session of BranchIO and handle response
  func setupBranchIO() {
    let request = RootedContent.SetupBranchIO.Request()
    interactor?.setupBranchIO(request: request)
  }

  func handleBranchIOResponse(viewModel: RootedContent.SetupBranchIO.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    NavigationCoordinator.performExpandedNavigation(from: self, {
      self.presentDetailsView(for: meeting)
    })
  }

  private func presentDetailsView(for meeting: Meeting) {
    let viewModel = RootedCellViewModel(data: meeting, delegate: self)
    let destination = InviteDetailsViewController.setupViewController(meeting: viewModel)
    self.present(destination, animated: true, completion: nil)
  }

  // MARK: - Use Case: Set up a managed session
  func setupManagedSession() {
    NavigationCoordinator.performExpandedNavigation(from: self, {
      // Authentication does not exist yet so set up a empty anonymous user
      if
        // Check if session exists; essentially sees if current user exists
        SessionManager.shared.sessionExists,
        // Retrieve current user from session manager
        let currentUser = SessionManager.shared.currentUser,
        // Get full name
        let currentUserFullName = currentUser.fullName,
        // Get first name
        let currentUserFirstName = currentUserFullName.components(separatedBy: " ").first

      {

        // Update heads up display labels
        // Parse full name
        self.updateLabel(self.welcomeLabel, text: "Hello, \(currentUserFirstName)!")
        self.updateLabel(self.activityCountLabel, text: "Upcoming meetings today")

        // Check calendar permissions
        self.checkCalendarPermissions()
      } else {
        RRLogger.log(message: "Session does not exist, start an anonymous one.", owner: self)
        self.presentPhoneLoginViewController()
      }
    })
  }

  // MARK: - Use Case: Set up conversation manager
  func setupConversationManager(using conversation: MSConversation) {
    // Store a reference of the conversation
    ConversationManager.setup(withConversation: conversation)
    selectedMessageCheck()
  }

  // MARK: - Use Case: Check if selected message contains a meeting json string
  func selectedMessageCheck() {
    guard
      let selectedmessage = ConversationManager.shared.selectedMessage,
      selectedmessage.md.string(forKey: kMessageTitleKey) != nil,
      let meeting = EngagementFactory.Meetings.messageToMeeting(selectedmessage) else { return }
    presentDetailsView(for: meeting)
  }

  // MARK: - Use Case: Retrieve meetings for user
  func retrieveMeetings() {
    showHUD()
    var request = RootedContent.RetrieveMeetings.Request()
    request.meetingManagerDelegate = self
    request.contentDB = .remote
    interactor?.retrieveMeetings(request: request)
  }

  func didFailToLoad(_ manager: Any?, error: Error) {
    dismissHUD()
    RRLogger.logError(message: "didFailToLoad with an error", owner: self, error: error)
    showError(title: "Error", message: error.localizedDescription)
  }

  func didFinishLoading(_ manager: Any?, invites: [MeetingContextWrapper]) {
    // Handle some additional business logic
  }

  func onDidFinishLoading(viewModel: RootedContent.RetrieveMeetings.ViewModel) {
    dismissHUD()
    guard let meetings = viewModel.meetings else { return }

    // Update activity label
    updateLabel(activityCountLabel, text: "You have \(meetings.count) upcoming meetings")

    // Update table for meetings
    let rootedCollectionViewModel = EngagementFactory.Meetings.convert(contextWrappers: meetings, for: menuSelection, withDelegate: self)
    loadCells(cells: rootedCollectionViewModel)
  }

  // MARK: - Use Case: App needs to quickly update text value within a UILabel
  private func updateLabel(_ label: UILabel, text: String) {
    label.text = text
  }

  // MARK: - Use Case: App should handle selection within `ScrollableSegmentedControl` to update the type of meeting data that is displayed in the table view
  @objc
  private func segmentSelected(sender: ScrollableSegmentedControl) {
    menuSelection = sender.selectedSegmentIndex
    dismissMenu()
    switch menuSelection {
    case 1:
      self.retrieveSentMeetings()
    default:
      self.retrieveMeetings()
    }
  }

  func retrieveSentMeetings() {
    showHUD()
    var request = RootedContent.RetrieveSentMeetings.Request()
    request.meetingManagerDelegate = self
    request.contentDB = .remote
    interactor?.retrieveSentMeetings(request: request)
  }

  // MARK: - IBActions
  // MARK: - Use Case: When a user taps on the refresh button, the current view should refresh
  @IBAction func refreshAction(_ sender: UIButton) {
    refreshMeetings()
  }

  @objc
  private func refreshMeetings() {
    switch menuSelection {
    case 1:
      self.retrieveSentMeetings()
    default:
      self.retrieveMeetings()
    }
  }

  // MARK: - Use Case: When a user taps on the menu button, the floating menu button should toggle show/hide
  @IBAction func menuButtonAction(_ sender: UIButton) {
    NavigationCoordinator.performExpandedNavigation(from: self) {
      self.toggleMenu()
    }
//    openInMessagingURL(urlString: "https://zoom.us/wc/93599844792/start")
  }

  private func toggleMenu() {
    if self.toggleMenuButton {
      self.dismissMenu()
    } else {
      self.showMenu()
    }
  }

  // MARK: - Use Case: Show toggle menu
  func showMenu() {
    toggleMenuButton = true
    if self.presentationStyle == .expanded {
      if self.floatingMenu == nil {
        self.floatingMenu = FloatingMenuBtn(parentView: self.view, mainButton: self.menuButton, images: self.menuItemImages)
        self.floatingMenu?.delegate = self
      }
      floatingMenu?.isOpen = false
      self.floatingMenu!.toggleMenu()
    }
  }

  // MARK: - Use Case: Dismiss toggle menu
  func dismissMenu() {
    toggleMenuButton = false
    floatingMenu?.isOpen = true
    floatingMenu?.toggleMenu()
  }

  // MARK: - Use Case: When a user makes a selection from the floating menu button
  func btnClicked(tag: Int) {
    RRLogger.log(message: "\(tag) Button in floating menu tapped", owner: self)

    self.dismissMenu()

    switch tag {
    case 0:
      // MARK: - Use Case: Check if maximum is reached and then go to create a new meeting
      self.checkMaximumMeetingsReached()
    case 1:
      // MARK: - Use Case: Go to `InfoViewController`
      self.goToInfoView()
    case 2:
      // MARK: - Use Case: Go to `AvailabilityNavigationViewController`
      self.goToAvailabilityNavigationView()
    case 3:
      // MARK: - Use Case: Go to `BeginCollaborationViewController`
      let controller = EditorDemoController(wordPressMode: false)
      self.present(controller, animated: true, completion: nil)
    default:
      RRLogger.log(message: "Unsupported menu action", owner: self)
      break
    }
  }

  // MARK: - RootedCellDelegate
  // MARK: - Use Case: As a user, I would like to perform additional actions on items in the table view
  func performActions(_ cell: UICollectionViewCell, ofType: ActionType, on viewModel: Any?) {
    guard let viewmodel = viewModel as? RootedCellViewModel else { return }

    if let meeting = viewmodel.data {

      RRLogger.log(message: "RootedCellDelegate performActions(_:on:) was called", owner: self)

      NavigationCoordinator.performExpandedNavigation(from: self) {

        // MARK: - Use Case: Show an alert for a user to perform more actions
        let alert = UIAlertController(title: "Quick Actions", message: "You can perform any of the following actions on this event invite.", preferredStyle: .actionSheet)

        // MARK: - Use Case: View details from the table view
        let viewDetails = UIAlertAction(title: "View Details", style: .default, handler: { action in
          let destination = InviteDetailsViewController.setupViewController(meeting: viewmodel)
          NavigationCoordinator.performExpandedNavigation(from: self) {
            self.present(destination, animated: true, completion: nil)
          }
        })
        alert.addAction(viewDetails)

        // MARK: - Use Case: View participant information
        let viewParticipants = UIAlertAction(title: "Confirmed Participants (\(meeting.participants?.count ?? 0))", style: .default, handler: { action in
          let destination = ViewParticipantsViewController.setupViewController(meeting: viewmodel)
          NavigationCoordinator.performExpandedNavigation(from: self) {
            self.present(destination, animated: true, completion: nil)
          }
        })
        alert.addAction(viewParticipants)

        if let meetingOwner = meeting.ownerId, let currentUserId = SessionManager.shared.currentUser?.uid, meetingOwner != currentUserId {

          if let meetingParticipants = meeting.meetingParticipantsIds, meetingParticipants.contains(currentUserId) {
            // MARK: - Use Case: View details from the table view
            let decline = UIAlertAction(title: "Remove Attendance", style: .default, handler: { action in
              self.declineInvite(meeting: viewmodel)
            })
            alert.addAction(decline)
          }
        } else {

          // MARK: - Use Case: Share a meeting from the table view
          let share = UIAlertAction(title: "Share to Conversation", style: .default, handler: { action in
            self.share(meeting: meeting)
          })
          alert.addAction(share)


          // MARK: - Use Case: Delete a meeting from the table view
          let delete = UIAlertAction(title: "Cancel Meeting", style: .destructive, handler: { action in
            self.delete(viewmodel)
          })
          alert.addAction(delete)

        }

        // MARK: - Use Case: Dismiss the action sheet if a desired function is not available
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
          // Do something on cancel
        })
        alert.addAction(cancel)

        // Show the alert
        self.present(alert, animated: true, completion: nil)
      }
    }
  }

  // MARK: - Use Case: Decline the meeting
  private func declineInvite(meeting: RootedCellViewModel) {
    let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
      self.removeFromCalendar(meeting: meeting)
    })

    let noAction = UIAlertAction(title: "No", style: .cancel, handler: { action in
      // Do something if user changes their mind
    })

    HUDFactory.displayAlert(with: "Remove Attendance", message: "Are you sure you are not attending the meeting anymore?", and: [yesAction, noAction], on: self)
  }

  func removeFromCalendar(meeting: RootedCellViewModel) {
    var request = RootedContent.RemoveFromCalendar.Request()
    request.meeting = meeting
    interactor?.removeMeetingFromCalendar(request: request)
  }

  func declineMeeting(meeting: Meeting) {
    var request = RootedContent.DeclineMeeting.Request()
    request.meeting = meeting
    request.branchEventID = kBranchInviteAccepted
    request.saveType = .receive
    request.contentDB = .remote
    interactor?.declineMeeting(request: request)
  }

  func onSuccessfulDecline(viewModel: RootedContent.DeclineMeeting.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    retrieveMeetings()
  }

  // MARK: - Use Case: Share a meeting from the table view by inserting it into the current conversation
  private func share(meeting: Meeting?) {
    guard
      let subject = meeting,
      let meetingname = subject.meetingName,
      let startdate = subject.meetingDate?.startDate?.toDate()?.date,
      let _ = subject.meetingDate?.endDate?.toDate()?.date,
      let message = EngagementFactory.Meetings.meetingToMessage(subject) else {
      self.showError(title: "Error", message: "There was an error trying to share the invite into the current conversation. Please try again.")
      return
    }

    // Insert into conversation
    ConversationManager.shared.send(message: message, of: .insert) { (success, error) in
      if let err = error {
        RRLogger.logError(message: "There was an error", owner: self, error: err)
        self.showError(title: "Oops!", message: err.localizedDescription)
      } else {
        // Do something if it was successful
        let pasteboard = UIPasteboard.general
        pasteboard.string = String(format: kCaptionString, arguments: [meetingname, startdate.toString(.rooted)])

        self.displayError(with: "Copied to Clipboard!", and: "Event invitation was copied to your clipboard.")
      }
    }
  }

  // MARK: - Use Case: Delete a meeting from the table view
  private func delete(_ meeting: RootedCellViewModel?) {
    // MARK: - Use Case: Show a confirmation to the user due to the action not being able to be undone
    let alert = UIAlertController(title: kDeleteTitle, message: kDeleteMessage, preferredStyle: .alert)

    // MARK: - Use Case: Delete a meeting from local storage and remove from calendar
    let yes = UIAlertAction(title: "Yes", style: .default, handler: { action in
      self.showHUD()

      var request = RootedContent.DeleteMeeting.Request()
      request.meetingManagerDelegate = self
      request.meeting = meeting
      request.contentDB = .remote
      self.interactor?.deleteMeeting(request: request)

    })
    alert.addAction(yes)

    // MARK: - Use Case: Cancel the deletion action
    let no = UIAlertAction(title: "No", style: .default, handler: { action in
      alert.dismiss(animated: true, completion: nil)
    })
    alert.addAction(no)

    self.present(alert, animated: true, completion: nil)
  }

  func onDidDeleteMeeting(viewModel: RootedContent.DeleteMeeting.ViewModel) {
    dismissHUD()
    showError(title: "Meeting Deleted", message: "Meeting was successfully deleted.", style: .alert, defaultButtonText: "OK")

    // Try to remove from Calendar
    removeFromCalendar(viewModel.meeting)

    // Refresh
    refreshMeetings()
  }

  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper) {
    print("Did delete invite")
    showError(title: "Meeting Deleted", message: "Meeting was successfully deleted.", style: .alert, defaultButtonText: "OK")
  }

  // MARK: - Use Case: Remove meeting from users calendar
  private func removeFromCalendar(_ meeting: RootedCellViewModel?) {
    guard let subject = meeting else {
      RRLogger.log(message: "There was an error trying to remove the meeting. Please try again.", owner: self)
      return
    }
    var request = RootedContent.RemoveFromCalendar.Request()
    request.meeting = subject
    self.interactor?.removeMeetingFromCalendar(request: request)
  }

  func onSuccessfulCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel) {
    RRLogger.log(message: "Successfully removed meeting from calendar", owner: self)
    guard let meeting = viewModel.meeting?.data else { return }
    declineMeeting(meeting: meeting)
  }

  func onFailedCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel) {
    RRLogger.log(message: "Failed to remove meeting from calendar. Error message: \(viewModel.errorMessage)", owner: self)
  }

  // MARK: - Routing Logic
  // MARK: - Use Case: Go to add an meeting view
  func goToCreateNewMeetingView() {
    let request = RootedContent.CreateNewMeeting.Request()
    interactor?.goToCreateNewMeetingView(request: request)
  }

  func handleError(viewModel: RootedContent.DisplayError.ViewModel) {
    dismissHUD()
    showError(title: viewModel.errorTitle, message: viewModel.errorMessage)
  }

  func presentCreateNewMeetingView(viewModel: RootedContent.CreateNewMeeting.ViewModel) {
    let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let destinationVC = sb.instantiateViewController(withIdentifier: kViewControllerMessagesNavigation) as! UINavigationController
    present(destinationVC, animated: true, completion: nil)
  }

  // MARK: - Use Case: Go to `InfoViewController`
  func goToInfoView() {
    let request = RootedContent.InfoView.Request()
    interactor?.goToInfoView(request: request)
  }

  func presentInfoView(viewModel: RootedContent.InfoView.ViewModel) {
    let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let destinationVC = sb.instantiateViewController(withIdentifier: kSettingsNavigationController) as! UINavigationController
    present(destinationVC, animated: true, completion: nil)
  }

  // MARK: - Use Case: Go to `AvailabilityNavigationViewController`
  func goToAvailabilityNavigationView() {
    let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let destinationVC = sb.instantiateViewController(withIdentifier: kViewControllerAvailabilityNavigation) as! AvailabilityViewController
    present(destinationVC, animated: true, completion: nil)
  }

  // MARK: - Use Case: Check if user is logged in and if not, show login screen
  func presentPhoneLoginViewController() {

    // Dismiss HUD
    dismissHUD()

    // Clear table
    clearTable()

    // Handle presentation of PhoneLoginViewController
    let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)

    let middleVC = sb.instantiateViewController(withIdentifier: kPhoneLoginViewController) as! PhoneLoginViewController
    var middleVCDS = middleVC.router!.dataStore!
    middleVCDS.authenticationLogicDelegate = self

    let leftVC = sb.instantiateViewController(withIdentifier: kRegistrationViewController) as! RegistrationViewController
    var leftVCDS = leftVC.router!.dataStore!

    let snapContainer = SnapContainerViewController.containerViewWith(leftVC,
                                                                      middleVC: middleVC)

    self.present(snapContainer, animated: true, completion: nil)

  }

  // MARK: - Use Case: On Successful login resume setting up the view controller
  func onSucessfulLogin(_ sender: PhoneLoginViewController, uid: String?) {
    getCalendarPermissions()
  }

  // MARK: - Use Case: On failed login attempt, resume setting up the view controller
  func handleFailedLogin(_ sender: PhoneLoginViewController, reason: String) {
    // Don't do anything yet
  }
}

// Reusable components
extension MyInvitesViewController {
  // MARK: - Use Case: Show ProgressHUD
  func showHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.show()
    }
  }

  // MARK: - Use Case: Dismiss ProgressHUD
  func dismissHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.dismiss()
    }
  }

  // MARK: - Use Case: Check if app has access to calendar permissions
  func getCalendarPermissions() {
    let request = RootedContent.CheckCalendarPermissions.Request()
    interactor?.getCalendarPermissions(request: request)
  }

  func handleCalendarPermissionsCheck(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) {
    if viewModel.isGranted {
      self.retrieveMeetings()
    } else {
      let appearance = OnboardViewController.AppearanceConfiguration(tintColor: .systemBlue,
                                                                     titleColor: .black,
                                                                     textColor: .black,
                                                                     backgroundColor: .white,
                                                                     imageContentMode: .scaleAspectFit,
                                                                     titleFont:UIFont.boldSystemFont(ofSize: 32.0),
                                                                     textFont: UIFont.boldSystemFont(ofSize: 17.0),
                                                                     advanceButtonStyling: { button in

                                                                      button.setTitleColor(.systemBlue, for: .normal)
                                                                      button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
      }) { button in
        button.setTitleColor(.lightGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
      }
      let page = OnboardPage(title: "Welcome to Rooted!",
                                 imageName: "calendar",
                                 description: "Grant access to your calendar to start creating and receiving meeting invites that sync to your calendar, set reminders and keep up with your schedule.",
                                 advanceButtonTitle: "Decide Later",
                                 actionButtonTitle: "Enable Calendar Access",
                                 action: { [weak self] completion in
                                  self?.checkCalendarPermissions()
                                  self?.dismiss(animated: true, completion: nil)
      })
      let onboardingViewController = OnboardViewController(pageItems: [page],
                                                           appearanceConfiguration: appearance)
      onboardingViewController.presentFrom(self, animated: true)
    }
  }

  func checkCalendarPermissions() {
    let request = RootedContent.CheckCalendarPermissions.Request()
    interactor?.checkCalendarPermissions(request: request)
  }

  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) {
    RRLogger.log(message: "Calendar Permissions: \(viewModel.isGranted)", owner: self)
    if viewModel.isGranted {
      // Prompt user to provide feedback
      self.setupRatingSystem()

      // Get meetings
      self.retrieveMeetings()
    } else {
      self.showCalendarError()
    }
  }

  private func showCalendarError() {
     self.showError(title: kCalendarPermissions, message: kCalendarAccess)
  }

  // MARK: - Use Case: As a business, we want to limit access to creating more than (n) meetings based on account type
  func checkMaximumMeetingsReached() {
    let request = RootedContent.CheckMaximumMeetingsReached.Request()
    interactor?.checkMaximumMeetingsReached(request: request)
  }

  func handleMaximumLimitReached(viewModel: RootedContent.CheckMaximumMeetingsReached.ViewModel) {
    if viewModel.isMaximumumReached {
      self.showError(title: viewModel.errorTitle, message: viewModel.errorMessage)
    } else {
      self.goToCreateNewMeetingView()
    }
  }

  // MARK: - Use Case: As a business, I want a user to be prompted to provide feedback on the app
  func setupRatingSystem() {
    EggRating.itunesId = "1458363262"
    EggRating.minRatingToAppStore = 3.5
    EggRating.daysUntilPrompt = 30
    EggRating.remindPeriod = 15
    EggRating.debugMode = isDebug
    EggRating.minuteUntilPrompt = 1
    EggRating.minuteRemindPeriod = 1
    EggRating.promptRateUsIfNeededMessageExt(in: self)
  }

  // MARK: - Use Case: Go to Calendar view
  @IBAction func calendarButtonAction(_ sender: UIButton) {
    // show calendar view
  }
}
