import UIKit
import Messages
import iMessageDataKit
import EventKit
import MapKit
import NotificationCenter

private var activeConvo: MSConversation?
private var selectedMessage: MSMessage?

public let kDeleteTitle = "Delete Invite"
public let kDeleteMessage = "You are about to delete a meeting invite. Are you sure?"

class MyInvitesVC: BaseAppViewController {

  @IBOutlet private var invitesTable: UITableView!
  @IBOutlet private var addButton: UIButton!
  @IBOutlet weak var tutorialView: UIView!

  var myInvitesManager: MyInvitesManager!
  var eventKitManager = EventKitManager()
  var activeConvo: MSConversation?

  var isTutorialVisible: Bool = true {
    didSet {
      tutorialView.isHidden = !self.isTutorialVisible
    }
  }

  // MARK: - Lifecycle events
  override func viewDidLoad() {
    super.viewDidLoad()

    tutorialView.applyCornerRadius(0.5)

    isTutorialVisible = true

    RProgressHUD.show(on: view)

    setUpInterface()
    loadObservers()

    myInvitesManager = MyInvitesManager()
    myInvitesManager.cellDelegate = self
    myInvitesManager.invitesDelegate = self

    invitesTable.delegate = myInvitesManager
    invitesTable.dataSource = myInvitesManager
    invitesTable.register(UINib(nibName: MyInviteCell.identifier,
                                bundle: nil),
                          forCellReuseIdentifier: MyInviteCell.identifier)

    myInvitesManager.loadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    getCalendarPermissions(onSucces: nil) {
      self.showCalendarError()
    }

    // Add gesture to `tutorialView`
    let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissTutoriaView))
    gesture.numberOfTapsRequired = 1
    tutorialView.addGestureRecognizer(gesture)
  }

  // MARK: - Private methods
  @objc func dismissTutoriaView() {
    self.isTutorialVisible = false
  }

  private func setUpInterface() {
    view.applyPrimaryGradient()
    addButton.applyCornerRadius()
    setupRefreshControl()
  }

  private func setupRefreshControl() {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action:  #selector(refreshInvites), for: .valueChanged)
    invitesTable.refreshControl = refreshControl
  }

  private func loadObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(inviteCountCheck), name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil)
  }

  private func showCalendarError() {
    self.showError(title: kCalendarPermissions, message: kCalendarAccess)
  }

  // MARK: - Class methods
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "goToAddInviteVC" {
          if
            let vc = segue.destination as? MessagesViewController,
            let convo = activeConvo {
              vc.activeConvo = convo
          }
      }
      if segue.identifier == "goToInviteDetails" {
        guard let selectedMessage = selectedMessage else { return }
        guard
          let title = selectedMessage.md.string(forKey: kMessageTitleKey),
          let startDate = selectedMessage.md.string(forKey: kMessageStartDateKey)?.toDate(),
          let endDate = selectedMessage.md.string(forKey: kMessageEndDateKey)?.toDate(), let destination = segue.destination as? InviteDetailsVC  else { return }

        destination.titleText = title
        destination.startDate = startDate
        destination.endDate = endDate
        destination.activeConvo = self.activeConvo

        if
          // See if the location string will map to the RLocation object
          let locationString = selectedMessage.md.string(forKey: kMessageLocationStringKey), let rLocation = RLocation(JSONString: locationString) {
            destination.rLocation = rLocation
        }
        destination.viewDidLoad()
      }
  }

  // MARK: - Public methods
  func getCalendarPermissions(onSucces: (() -> Void)?,
                              onFailure: (() -> Void)?) {
    eventKitManager.getCalendarPermissions { (success) in
      if success {
        onSucces?()
      } else {
        onFailure?()
      }
    }
  }

  @objc func inviteCountCheck() {
    if myInvitesManager.isMaximumReached() {
      showError(title: "Maximum Invites Reached",
                message: "At this time you can only have 3 live calendar invites. Please delete ones not in use and then try again.")
    } else {
      performSegue(withIdentifier: "goToAddInviteVC", sender: self)
    }
  }

  @objc func refreshInvites() {
      myInvitesManager.refreshInvites()
  }

  // MARK: - IBActions
  @IBAction func addAction(_ sender: UIButton) {
    getCalendarPermissions(onSucces: {
      self.inviteCountCheck()
    }) {
      self.showCalendarError()
    }
  }
}

// MARK: - Conversation handler
extension MyInvitesVC {
  override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    if presentationStyle == .expanded {
      self.isTutorialVisible = false
    }
  }
  override func didBecomeActive(with conversation: MSConversation) {
    super.didBecomeActive(with: conversation)
    if self.presentationStyle != .expanded {
      
    }
  }
  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)
    getCalendarPermissions(onSucces: {
      self.activeConvo = conversation
      if let selectedmessage = conversation.selectedMessage {
        selectedMessage = selectedmessage
        guard let _ = selectedmessage.md.string(forKey: kMessageTitleKey) else { return }
        self.performSegue(withIdentifier: "goToInviteDetails", sender: self)
      }
    }) {
      self.showCalendarError()
    }
  }

  override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
      self.activeConvo = conversation
  }
}

public let captionString = "%@ on %@"

// MARK: - MyInviteCell delegate
extension MyInvitesVC: MyInviteCellDelegate {
  func share(_ cell: UITableViewCell, invite: InviteObject?) {
    guard let subject = invite else {
        self.showError(title: "Error", message: "There was an error trying to share the invite into the current chat. Please try again.")
        return
    }

    let message = MSMessage()
    var subcaption = ""

    let layout = MSMessageTemplateLayout()
    layout.caption = String(format: captionString, arguments: [subject.value(forKey: kMessageTitleKey) as? String ?? "", (subject.value(forKey: kMessageStartDateKey) as? Date ?? Date()).toString(.rooted)])

    message.md.set(value: subject.value(forKey: kMessageTitleKey) as? String ?? "", forKey: kMessageTitleKey)
    message.md.set(value: (subject.value(forKey: kMessageStartDateKey) as? Date ?? Date()).toString(), forKey: kMessageStartDateKey)
    message.md.set(value: (subject.value(forKey: kMessageEndDateKey) as? Date ?? Date()).toString(), forKey: kMessageEndDateKey)

    if let locationString = subject.value(forKey: kMessageLocationStringKey) as? String, let loc = RLocation(JSONString: locationString) {
      subcaption += loc.readableWhereString
      message.md.set(value: loc.readableWhereString, forKey: kMessageSubCaptionKey)
      message.md.set(value: locationString, forKey: kMessageLocationStringKey)
    }

    layout.subcaption = subcaption
    message.layout = layout

    if self.activeConversation == nil {
      activeConvo?.insert(message) { (error) in
        if let err = error {
          print("There was an error \(err.localizedDescription)")
        }
        DispatchQueue.main.async {
          if self.presentationStyle != .compact {
            self.requestPresentationStyle(.compact)
          }
        }
      }
    } else {
      self.activeConversation!.insert(message) { (error) in
        if let err = error {
          print("There was an error \(err.localizedDescription)")
        }
        DispatchQueue.main.async {
          if self.presentationStyle != .compact {
            self.requestPresentationStyle(.compact)
          }
        }
      }
    }
  }

  func trash(_ cell: UITableViewCell, invite: InviteObject?) {
    guard let subject = invite else {
      self.showError(title: "Error", message: "There was an error trying to delete the object. Please try again.")
      return
    }

    let alert = UIAlertController(title: kDeleteTitle, message: kDeleteMessage, preferredStyle: .alert)
    let yes = UIAlertAction(title: "Yes", style: .default, handler: { action in
      self.myInvitesManager.deleteInvite(subject, atIndex: cell.tag)
    })
    let no = UIAlertAction(title: "No", style: .default, handler: { action in
        alert.dismiss(animated: true, completion: nil)
    })
    alert.addAction(yes)
    alert.addAction(no)
    self.present(alert, animated: true, completion: nil)
  }
}

extension MyInvitesVC: MyInvitesDelegate {
  func didFinishLoading(_ manager: Any) {
    print("Did finish loading")
    RProgressHUD.dismiss()
    invitesTable.reloadData()
  }

  func didFailToLoad(_ manager: Any, error: Error) {
    print("didFailToLoad with an error. Error message: \(error.localizedDescription)")
    fatalError(error.localizedDescription)
  }

  func willDeleteInvite(_ manager: Any) {
    print("Will remove invite")
  }

  func didDeleteInvite(_ manager: Any) {
    print("Removed invite")
    invitesTable.reloadData()
    invitesTable.refreshControl?.endRefreshing()
  }

  func willRefreshInvites(_ manager: Any) {
    print("Started refreshing invites")
  }

  func didRefreshInvites(_ manager: Any) {
    print("Finished refreshing invites")
    invitesTable.reloadData()
    invitesTable.refreshControl?.endRefreshing()
  }

  func didFailRefreshingInvites(_ manager: Any, error: Error) {
    print("didFailToRefreshInvites with an error. Error message: \(error.localizedDescription)")
    fatalError(error.localizedDescription)
  }

}
