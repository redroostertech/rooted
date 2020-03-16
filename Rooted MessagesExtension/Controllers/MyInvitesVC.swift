import UIKit
import Messages
import iMessageDataKit
import EventKit
import MapKit
import NotificationCenter
import CoreData
import Branch

class MyInvitesVC: ResponsiveViewController {

  @IBOutlet private weak var refreshButton: UIButton!
  @IBOutlet private weak var segmentedControl: ScrollableSegmentedControl!
  @IBOutlet private weak var segmentControlHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var collectionView: UICollectionView!
  @IBOutlet private weak var addButton: UIButton!

  private var dataManager = MeetingsManager()
  private var eventKitManager = EventKitManager()
  private var progressHUD: RProgressHUD?
  private var menuSelection = 0

  public var anonymousUser: UserProfileData?
  public var toggleMenuButton = false
  public var floatingMenu: FloatingMenuBtn?

  var menuItemImages: [UIImage] {
    return [UIImage(named: "plus")!, UIImage(named: "info")!, UIImage(named: "addavailability")!]
  }

  // MARK: - Lifecycle events
  override func viewDidLoad() {
    super.viewDidLoad()

    progressHUD = RProgressHUD(on: self.view)
    progressHUD!.show()

    addButton.applyCornerRadius()
    addButton.backgroundColor = .gradientColor2

    segmentedControl.segmentStyle = .textOnly
    segmentedControl.insertSegment(withTitle: "Upcoming", image: nil, at: 0)
    segmentedControl.insertSegment(withTitle: "Sent", image: nil, at: 1)
    // TODO: - Work on editing an invite so that drafts can be done
//    segmentedControl.insertSegment(withTitle: "Drafts", image: nil, at: 2)
    segmentedControl.underlineHeight = 3.0
    segmentedControl.tintColor = .darkGray
    segmentedControl.underlineSelected = true
    segmentedControl.selectedSegmentIndex = menuSelection
    segmentedControl.fixedSegmentWidth = true

    segmentedControl.addTarget(self, action: #selector(self.segmentSelected(sender:)), for: .valueChanged)

    NotificationCenter.default.addObserver(self, selector: #selector(refreshInvites), name: Notification.Name(rawValue: kNotificationMyInvitesReload), object: nil)

    dataManager.delegate = self
    dataManager.loadInvites()
    
  }

  // TODO: - I don't believe that this is needed here
  // Uncomment this if it is needed
  /*
  override func viewWillAppear(_ animated: Bool) {
    getCalendarPermissions(onSucces: nil) {
      self.showCalendarError()
    }
  }
 */

  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)

    // Setup Branch
    let branch = Branch.getInstance()

    // Validate integration
    // TODO: - Comment this out before sending to production
    // branch.validateSDKIntegration()
    branch.initSession(launchOptions: [:], automaticallyDisplayDeepLinkController: false) { (parameters, error) in
      if let err = error {
        RRLogger.logError(message: "Error with Branch", owner: self, error: err)
      } else {
        guard let params = parameters as? [String: AnyObject] else {
          RRLogger.logError(message: "Error with Branch SDK", owner: self, rError: RError.generalError)
          return
        }
        // Check if meeting string is part of params
        RRLogger.log(message: "Found paramas \(params.description)", owner: self)
        // Check if selected message contains the `Meeting` json string
        // If so, then the user selected a rooted message therefore show them the details of it
        guard
          let meetingJSONObject = params["$custom_meta_tags"] as? String, let meeting = Meeting(JSONString: meetingJSONObject) else { return }

        NavigationCoordinator.performExpandedNavigation(from: self, {
          let destination = InviteDetailsVC.setupViewController(meeting: meeting)
          self.present(destination, animated: true, completion: nil)
        })
      }
    }

    // Authentication does not exist yet so set up a empty anonymous user
    if !SessionManager.shared.sessionExists {

      RRLogger.log(message: "Session does not exist, start an anonymous one.", owner: self)

      /*
      // Create an anonymous user
      self.anonymousUser = UserProfileData.anonymousUser
      guard self.anonymousUser != nil else { return }

      // Create a random string to be used as an ID
      anonymousUser!.id = RanStringGen(length: 25).returnString()

      // Get the user's name
      let registrationForm = RegistrationForm()
      registrationForm.translatesAutoresizingMaskIntoConstraints = false
      registrationForm.configure(delegate: self)

      self.view.addSubview(registrationForm)

      let constraints: [NSLayoutConstraint] = [
        registrationForm.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24.0),
        registrationForm.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -24.0),
        registrationForm.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 24.0),
        registrationForm.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -24.0),
      ]
      NSLayoutConstraint.activate(constraints)
     */
    }

    // Store a reference of the conversation
    ConversationManager.setup(withConversation: conversation)

    // Check that app has access to on device calendar
    getCalendarPermissions(onSucces: {

      // Check if selected message contains the `Meeting` json string
      // If so, then the user selected a rooted message therefore show them the details of it
      guard
        let selectedmessage = ConversationManager.shared.selectedMessage,
        selectedmessage.md.string(forKey: kMessageTitleKey) != nil,
        let meeting = MessageFactory.Meetings.messageToMeeting(selectedmessage) else { return }

      let destination = InviteDetailsVC.setupViewController(meeting: meeting)
      self.present(destination, animated: true, completion: nil)

    }) {
      self.showCalendarError()
    }

  }

  override func didBecomeActive(with conversation: MSConversation) {
    super.didBecomeActive(with: conversation)
    log(presentationStyle: presentationStyle)
    switch presentationStyle {
    case .compact, .transcript:
      self.dismiss(animated: true, completion: nil)
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
      self.dismiss(animated: true, completion: nil)
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
        self.floatingMenu = FloatingMenuBtn(parentView: self.view, mainButton: self.addButton, images: self.menuItemImages)
        self.floatingMenu?.delegate = self
        self.floatingMenu?.toggleMenu()
      }
      self.segmentControlHeightConstraint.constant = 49
      break
    }
  }

  // MARK: - Private methods
  private func log(presentationStyle: MSMessagesAppPresentationStyle) {
    switch presentationStyle {
    case .compact:
      RRLogger.log(message: "Presentation is transitioning to compact", owner: self)
    case .expanded:
      RRLogger.log(message: "Presentation is transitioning to expanded", owner: self)
    case .transcript:
      RRLogger.log(message: "Presentation is transitioning to transcript", owner: self)
    }
  }

  private func showCalendarError() {
    self.showError(title: kCalendarPermissions, message: kCalendarAccess)
  }

  private func getCalendarPermissions(onSucces: (() -> Void)?, onFailure: (() -> Void)?) {
    eventKitManager.getCalendarPermissions { (success) in
      if success {
        onSucces?()
      } else {
        onFailure?()
      }
    }
  }

  private func share(_ invite: Meeting?) {
    guard let subject = invite, let message = MessageFactory.Meetings.meetingToMessage(subject) else {
      self.showError(title: "Error", message: "There was an error trying to share the invite into the current chat. Please try again.")
      return
    }

    ConversationManager.shared.conversation?.insert(message, completionHandler: { error in
      if let err = error {
        RRLogger.logError(message: "There was an error", owner: self, error: err)
        self.showError(title: err.localizedDescription, message: err.localizedDescription)
      }
    })
  }

  private func trash(_ object: NSManagedObject?) {
    guard let subject = object else {
      self.showError(title: "Error", message: "There was an error trying to delete the object. Please try again.")
      return
    }

    let alert = UIAlertController(title: kDeleteTitle, message: kDeleteMessage, preferredStyle: .alert)
    let yes = UIAlertAction(title: "Yes", style: .default, handler: { action in
      self.dataManager.deleteInvite(subject)
    })
    let no = UIAlertAction(title: "No", style: .default, handler: { action in
      alert.dismiss(animated: true, completion: nil)
    })
    alert.addAction(yes)
    alert.addAction(no)
    self.present(alert, animated: true, completion: nil)
  }

  @objc
  private func inviteCountCheck() {
    if self.dataManager.maximumReached {

      BranchEvent.customEvent(withName: "maximum_reached")

      self.showError(title: "Oops!", message: "At this time, you can only have 3 live calendar invites. Please delete ones not in use and then try again.")
    } else {
      let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
      let vc = sb.instantiateViewController(withIdentifier: kViewControllerMessagesNavigation)
      self.present(vc, animated: true, completion: nil)
    }
  }

  @objc
  private func refreshInvites() {
    dataManager.refreshMeetings()
  }

  @objc
  private func segmentSelected(sender:ScrollableSegmentedControl) {
    print("Segment at index \(sender.selectedSegmentIndex)  selected")
    menuSelection = sender.selectedSegmentIndex

    toggleMenuButton = false
    floatingMenu?.isOpen = true
    floatingMenu?.toggleMenu()

    refreshInvites()

  }

  // MARK: - IBActions
  @IBAction func refreshAction(_ sender: UIButton) {
    progressHUD?.show()
    dataManager.refreshMeetings()
  }

  @IBAction func addAction(_ sender: UIButton) {
    NavigationCoordinator.performExpandedNavigation(from: self) {

      if self.toggleMenuButton {
        self.toggleMenuButton = false
        self.floatingMenu?.toggleMenu()
      } else {
        self.toggleMenuButton = true
        if self.presentationStyle == .expanded {
          if self.floatingMenu == nil {
            self.floatingMenu = FloatingMenuBtn(parentView: self.view, mainButton: self.addButton, images: self.menuItemImages)
            self.floatingMenu?.delegate = self
          }
          self.floatingMenu!.toggleMenu()
        }
      }
    }
  }

}

// MARK: - MyInvitesDelegate
extension MyInvitesVC: MyInvitesDelegate {
  func willDeleteInvite(_ manager: Any?) {
    // Will remove invite
  }

  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper){
    // Invite was deleted
  }

  func didFailToLoad(_ manager: Any?, error: Error) {
    progressHUD?.dismiss()
    RRLogger.logError(message: "didFailToLoad with an error", owner: self, error: error)
    showError(title: "Error", message: error.localizedDescription)
  }

  func didFinishLoading(_ manager: Any?, invites: [MeetingContextWrapper]) {
    progressHUD?.dismiss()

    let rootedCollectionViewModel = MessageFactory.Meetings.convert(contextWrappers: invites, for: menuSelection, withDelegate: self)

    setup(collectionView: collectionView, cells: rootedCollectionViewModel)
  }

}

// MARK: - RootedFormDelegate
extension MyInvitesVC: RootedFormDelegate {
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
}

// MARK: - RootedCellDelegate
extension MyInvitesVC: RootedCellDelegate {
  func performActions(_ cell: UICollectionViewCell, ofType: ActionType, on model: Any?, andManagedObject managedObject: [NSManagedObject]?) {
    if let meeting = model as? Meeting {
      RRLogger.log(message: "RootedCellDelegate performActions(_:on:) was called", owner: self)
      NavigationCoordinator.performExpandedNavigation(from: self) {
        let alert = UIAlertController(title: "More Actions", message: "You can perform any of the following actions on this event invite.", preferredStyle: .actionSheet)
        let share = UIAlertAction(title: "Share", style: .default, handler: { action in
          guard let managedObject = managedObject?.first else { return }
          self.share(meeting)
        })
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { action in
          guard let managedObject = managedObject?.first else { return }
          self.trash(managedObject)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
        })
        alert.addAction(share)
        alert.addAction(delete)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
      }
    }
  }
}

// MARK: - FloatingMenuBtnAction
extension MyInvitesVC: FloatingMenuBtnAction {
  func btnClicked(tag: Int) {
    RRLogger.log(message: "\(tag) Button in floating menu tapped", owner: self)
    switch tag {
    case 0:
      self.getCalendarPermissions(onSucces: {

        self.toggleMenuButton = false
        self.floatingMenu?.isOpen = true
        self.floatingMenu?.toggleMenu()
        
        self.inviteCountCheck()
      }) {
        self.showCalendarError()
      }
    case 1:

      self.toggleMenuButton = false
      self.floatingMenu?.isOpen = true
      self.floatingMenu?.toggleMenu()

      let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
      let vc = sb.instantiateViewController(withIdentifier: "InfoVC")
      self.present(vc, animated: true, completion: nil)
    default:
      RRLogger.log(message: "Unsupported menu action", owner: self)
      break
    }
  }
}
