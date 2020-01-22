import UIKit
import Messages
import iMessageDataKit
import EventKit
import MapKit
import NotificationCenter

private var activeConvo: MSConversation?
private var selectedMessage: MSMessage?

class MyInvitesVC: MSMessagesAppViewController {

  @IBOutlet private var invitesTable: UITableView!
  @IBOutlet private var addButton: UIButton!

  var myInvitesManager: MyInvitesManager!
  var eventKitManager = EventKitManager()

  // MARK: - Lifecycle events
  override func viewDidLoad() {
    super.viewDidLoad()

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
  }

  // MARK: - Private methods
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
    self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
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
          guard let destination = segue.destination as? InviteDetailsVC else { return }
          guard let selectedMessage = selectedMessage else { return }
          guard
              let title = selectedMessage.md.string(forKey: "title"),
              let startDate = selectedMessage.md.string(forKey: "startDate")?.toDate(),
              let endDate = selectedMessage.md.string(forKey: "endDate")?.toDate() else { return }

          destination.eventStore = eventKitManager.eventStore
          destination.titleText = title
          destination.startDate = startDate
          destination.endDate = endDate

          if
              let locationName = selectedMessage.md.string(forKey: "locationName"),
              let locationLat = selectedMessage.md.double(forKey: "locationLat"),
              let locationLon = selectedMessage.md.double(forKey: "locationLon"),
              let latDegrees = CLLocationDegrees(exactly: locationLat),
              let lonDegrees = CLLocationDegrees(exactly: locationLon) {
              let coordinate = CLLocationCoordinate2D(latitude: latDegrees, longitude: lonDegrees)
              let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: [
                  "subThoroughfare": selectedMessage.md.string(forKey: "locationStreet") ?? "",
                  "thoroughfare": selectedMessage.md.string(forKey: "locationAddress") ?? "",
                  "locality": selectedMessage.md.string(forKey: "locationCity") ?? "",
                  "administrativeArea": selectedMessage.md.string(forKey: "locationState") ?? "",
                  "countryCode": selectedMessage.md.string(forKey: "locationCountry") ?? "",
                  "postalCode" : selectedMessage.md.string(forKey: "locationZip") ?? ""
                  ])
              let mapItem = MKMapItem(placemark: placemark)
              mapItem.name = locationName
              destination.selectedLocation = (mapItem, placemark)
              destination.selectedLocationName = locationName
          }
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
  override func willBecomeActive(with conversation: MSConversation) {
    DispatchQueue.main.async {
      if self.presentationStyle != .expanded {
        self.requestPresentationStyle(.expanded)
      }
    }
    getCalendarPermissions(onSucces: {
      activeConvo = conversation
      if let selectedmessage = conversation.selectedMessage {
        selectedMessage = selectedmessage
        self.performSegue(withIdentifier: "goToInviteDetails", sender: self)
      }
    }) {
      self.showCalendarError()
    }
  }

  override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
      activeConvo = conversation
  }
}

// MARK: - MyInviteCell delegate
extension MyInvitesVC: MyInviteCellDelegate {
  func share(_ cell: UITableViewCell, invite: InviteObject?) {
    guard let subject = invite else {
        self.showError(title: "Error", message: "There was an error trying to share the invite into the current chat. Please try again.")
        return
    }
    let message = MSMessage()

    let layout = MSMessageTemplateLayout()
    layout.caption = subject.value(forKey: "title") as? String ?? ""
    layout.subcaption = subject.value(forKey: "locationName") as? String ?? ""
    message.layout = layout

    message.md.set(value: subject.value(forKey: "title") as? String ?? "", forKey: "title")
    message.md.set(value: subject.value(forKey: "locationName") as? String ?? "", forKey: "subcaption")
    message.md.set(value: (subject.value(forKey: "startDate") as? Date ?? Date()).toString(), forKey: "startDate")
    message.md.set(value: (subject.value(forKey: "endDate") as? Date ?? Date()).toString(), forKey: "endDate")
    message.md.set(value: subject.value(forKey: "locationName") as? String ?? "", forKey: "locationName")
    message.md.set(value: subject.value(forKey: "locationLat") as? Double ?? 0.0, forKey: "locationLat")
    message.md.set(value: subject.value(forKey: "locationLon") as? Double ?? 0.0, forKey: "locationLon")
    message.md.set(value: subject.value(forKey: "locationStreet") as? String ?? "", forKey: "locationStreet")
    message.md.set(value: subject.value(forKey: "locationAddress") as? String ?? "", forKey: "locationAddress")
    message.md.set(value: subject.value(forKey: "locationCity") as? String ?? "", forKey: "locationCity")
    message.md.set(value: subject.value(forKey: "locationState") as? String ?? "", forKey: "locationState")
    message.md.set(value: subject.value(forKey: "locationCountry") as? String ?? "", forKey: "locationCountry")
    message.md.set(value: subject.value(forKey: "locationZip") as? String ?? "", forKey: "locationZip")

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

    let alert = UIAlertController(title: "Trash", message: "You are about to delete an invite. Doing so will delete it forever. Are you sure?", preferredStyle: .alert)
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
