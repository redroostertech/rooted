import UIKit
import Messages
import iMessageDataKit
import EventKit
import MapKit
import NotificationCenter
import CoreData
import Branch
import OnboardKit

class MyInvitesViewController: ResponsiveViewController, RootedContentDisplayLogic, MeetingsManagerDelegate, RootedCellDelegate, FloatingMenuBtnAction, AuthenticationLogic {

  // MARK: - IBOutlets
  @IBOutlet private weak var refreshButton: UIButton!
  @IBOutlet private weak var segmentedControl: ScrollableSegmentedControl!
  @IBOutlet private weak var segmentControlHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var collectionView: UICollectionView!
  @IBOutlet private weak var menuButton: UIButton!

  // Floating Menu
  public var floatingMenu: FloatingMenuBtn?
  public var toggleMenuButton = false
  private var menuSelection = 0
  private var menuItemImages: [UIImage] {
    return [UIImage(named: "calendar-plus")!, UIImage(named: "user-outline-male-symbol-of-interface")!]
  }
//  private var menuItemImages: [UIImage] {
//    return [UIImage(named: "plus")!, UIImage(named: "info")!, UIImage(named: "addavailability")!]
//  }

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
    setupManagedSession()
    setupBranchIO()
    setupConversationManager(using: conversation)
  }

  override func didBecomeActive(with conversation: MSConversation) {
    super.didBecomeActive(with: conversation)
    log(presentationStyle: presentationStyle)
    switch presentationStyle {
    case .compact, .transcript:
      self.layoutOption = .horizontalList
      self.segmentControlHeightConstraint.constant = 0
      break
    default:
      self.layoutOption = .list
      self.segmentControlHeightConstraint.constant = 49
      break
    }
  }

  override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    super.willTransition(to: presentationStyle)
    log(presentationStyle: presentationStyle)
    switch presentationStyle {
    case .compact, .transcript:
      self.layoutOption = .horizontalList
      self.segmentControlHeightConstraint.constant = 0
      break
    default:
      self.layoutOption = .list
      self.segmentControlHeightConstraint.constant = 49
      break
    }
  }

  override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    super.didTransition(to: presentationStyle)
    log(presentationStyle: presentationStyle)
    switch presentationStyle {
    case .compact, .transcript:
      self.toggleMenuButton = false
      self.floatingMenu?.isOpen = true
      self.floatingMenu?.toggleMenu()
      self.segmentControlHeightConstraint.constant = 0
      break
    default:
      if toggleMenuButton {
        self.floatingMenu = FloatingMenuBtn(parentView: self.view, mainButton: self.menuButton, images: self.menuItemImages)
        self.floatingMenu?.delegate = self
        self.floatingMenu?.toggleMenu()
      }
      self.segmentControlHeightConstraint.constant = 49
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
//    menuButton.applyCornerRadius()
//    menuButton.imageView?.contentMode = .scaleAspectFit
    menuButton.tintColor = .darkGray
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
    // Authentication does not exist yet so set up a empty anonymous user
    if !SessionManager.shared.sessionExists {
      RRLogger.log(message: "Session does not exist, start an anonymous one.", owner: self)
      self.presentPhoneLoginViewController()
    } else {
      self.checkCalendarPermissions()
    }
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
    interactor?.retrieveMeetings(request: request)
  }

  func didFailToLoad(_ manager: Any?, error: Error) {
    dismissHUD()
    RRLogger.logError(message: "didFailToLoad with an error", owner: self, error: error)
    showError(title: "Error", message: error.localizedDescription)
  }

  func didFinishLoading(_ manager: Any?, invites: [MeetingContextWrapper]) {
    dismissHUD()
    // Filter invites by segment index
    let rootedCollectionViewModel = EngagementFactory.Meetings.convert(contextWrappers: invites, for: menuSelection, withDelegate: self)
    loadCells(cells: rootedCollectionViewModel)
  }

  // MARK: - Use Case: App should handle selection within `ScrollableSegmentedControl` to update the type of meeting data that is displayed in the table view
  @objc
  private func segmentSelected(sender: ScrollableSegmentedControl) {
    menuSelection = sender.selectedSegmentIndex
    dismissMenu()
    refreshMeetings()
  }

  // MARK: - IBActions
  // MARK: - Use Case: When a user taps on the refresh button, the current view should refresh
  @IBAction func refreshAction(_ sender: UIButton) {
    refreshMeetings()
  }

  @objc
  private func refreshMeetings() {
    retrieveMeetings()
  }

  // MARK: - Use Case: When a user taps on the menu button, the floating menu button should toggle show/hide
  @IBAction func menuButtonAction(_ sender: UIButton) {
    NavigationCoordinator.performExpandedNavigation(from: self) {
      self.toggleMenu()
    }
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
        let alert = UIAlertController(title: "More Actions", message: "You can perform any of the following actions on this event invite.", preferredStyle: .actionSheet)

        // MARK: - Use Case: Share a meeting from the table view
        let share = UIAlertAction(title: "Share to Conversation", style: .default, handler: { action in
          self.share(meeting: meeting)
        })
        alert.addAction(share)

        // MARK: - Use Case: Delete a meeting from the table view
        let delete = UIAlertAction(title: "Remove from Calendar", style: .destructive, handler: { action in
          self.removeFromCalendar(viewmodel)
        })
        alert.addAction(delete)

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

  // MARK: - Use Case: Share a meeting from the table view by inserting it into the current conversation
  private func share(meeting: Meeting?) {
    guard
      let subject = meeting,
      let message = EngagementFactory.Meetings.meetingToMessage(subject) else {
      self.showError(title: "Error", message: "There was an error trying to share the invite into the current conversation. Please try again.")
      return
    }

    // Insert into conversation
    ConversationManager.shared.conversation?.insert(message, completionHandler: { error in
      if let err = error {
        RRLogger.logError(message: "There was an error", owner: self, error: err)
        self.showError(title: err.localizedDescription, message: err.localizedDescription)
      } else {
        // Do something if it was successful
      }
    })
  }

  // MARK: - Use Case: Remove meeting from users calendar
  private func removeFromCalendar(_ meeting: RootedCellViewModel?) {
    guard let subject = meeting else {
      self.showError(title: "Error", message: "There was an error trying to remove the meeting. Please try again.")
      return
    }

    // MARK: - Use Case: Show a confirmation to the user due to the action not being able to be undone
    let alert = UIAlertController(title: kDeleteTitle, message: kDeleteMessage, preferredStyle: .alert)

    // MARK: - Use Case: Delete a meeting from local storage and remove from calendar
    let yes = UIAlertAction(title: "Yes", style: .default, handler: { action in

      var request = RootedContent.RemoveFromCalendar.Request()
      request.meeting = subject
      self.interactor?.removeMeetingFromCalendar(request: request)

    })
    alert.addAction(yes)

    // MARK: - Use Case: Cancel the deletion action
    let no = UIAlertAction(title: "No", style: .default, handler: { action in
      alert.dismiss(animated: true, completion: nil)
    })
    alert.addAction(no)

    self.present(alert, animated: true, completion: nil)
  }

  func onSuccessfulCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel) {
    print("Removed from calendar")
    delete(viewModel.meeting)
  }

  // MARK: - Use Case: Delete a meeting from the table view
  private func delete(_ meeting: RootedCellViewModel?) {
    var request = RootedContent.DeleteMeeting.Request()
    request.meetingManagerDelegate = self
    request.meeting = meeting
    self.interactor?.deleteMeeting(request: request)
  }

  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper) {
    print("Did delete invite")
    showError(title: "Meeting Deleted", message: "Meeting was successfully deleted.", style: .alert, defaultButtonText: "OK")
  }

  // MARK: - RootedFormDelegate
  func didReturn(_ form: RegistrationForm, textField: UITextField) {
    guard anonymousUser != nil else { return }
    // Start session with anonymous user when input is done
    SessionManager.start(with: anonymousUser!)
  }

  func didBeginEditing(_ form: RegistrationForm, textField: UITextField) {
    NavigationCoordinator.performExpandedNavigation(from: self) {
      // Do something when user did start providing input
    }
  }

  func valueFrom(_ form: RegistrationForm, key: String, value: Any?) {
    guard anonymousUser != nil, let val = value as? String else { return }
    // Set full name for anonymous users of value
    anonymousUser!.fullName = val
  }

  func form(_ form: RegistrationForm, error: Error) {
    showError(title: "Error", message: error.localizedDescription)
  }

  func didCancel(_ form: RegistrationForm) {
    // Do something when user input for form is cancelled
  }


  // MARK: - Routing Logic
  // MARK: - Use Case: Go to add an meeting view
  func goToCreateNewMeetingView() {
    let request = RootedContent.CreateNewMeeting.Request()
    interactor?.goToCreateNewMeetingView(request: request)
  }

  func handleError(viewModel: RootedContent.DisplayError.ViewModel) {
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
}
