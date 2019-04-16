import UIKit
import Messages
import iMessageDataKit
import EventKit
import MapKit
import NotificationCenter

class MyInvitesVC: MSMessagesAppViewController {

    @IBOutlet var invitesTable: UITableView!
    @IBOutlet var addButton: UIButton!

    var myInvitesManager = MyInvitesManager()
    var eventKitManager = EventKitManager()
    var activeConvo: MSConversation?
    var selectedMessage: MSMessage?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.applyPrimaryGradient()
        addButton.applyCornerRadius()

        myInvitesManager.delegate = self

        invitesTable.delegate = myInvitesManager
        invitesTable.dataSource = myInvitesManager
        invitesTable.register(UINib(nibName: MyInviteCell.identifier, bundle: nil), forCellReuseIdentifier: MyInviteCell.identifier)
        invitesTable.reloadData()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshInvites), for: .valueChanged)
        invitesTable.refreshControl = refreshControl

        NotificationCenter.default.addObserver(self, selector: #selector(inviteCountCheck), name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        eventKitManager.getCalendarPermissions { (success) in
            if !success {
                self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
            }
        }
    }

    // MARK: - Class methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToAddInviteVC" {
            if let vc = segue.destination as? MessagesViewController, let convo = activeConvo {
                vc.activeConvo = convo
            }
        }
        if segue.identifier == "goToInviteDetails" {
            guard let destination = segue.destination as? InviteDetailsVC else { return }
            guard let selectedMessage = self.selectedMessage else { return }
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

    @objc func inviteCountCheck() {
        guard let count = myInvitesManager.checkCount() else {
            showError(title: "Error", message: "There was an error. Please try again.")
            return
        }
        if count >= 3 {
            showError(title: "Maximum Invites Reached",
                      message: "At this time you can only have 3 live calendar invites. Please delete ones not in use and then try again.")
        } else {
            performSegue(withIdentifier: "goToAddInviteVC", sender: self)
        }
    }

    @objc func refreshInvites() {
        myInvitesManager.refreshInvites {
            self.invitesTable.reloadData()
            self.invitesTable.refreshControl?.endRefreshing()
        }
    }

    @IBAction func addAction(_ sender: UIButton) {
        eventKitManager.getCalendarPermissions { (success) in
            if success {
                self.inviteCountCheck()
            } else {
                self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
            }
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
        activeConvo = conversation
        eventKitManager.getCalendarPermissions { (success) in
            if success {
                guard let selectedMessage = conversation.selectedMessage else { return }
                self.selectedMessage = selectedMessage
                self.performSegue(withIdentifier: "goToInviteDetails", sender: self)
            } else {
                self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
            }
        }
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        activeConvo = conversation
    }
}

// MARK: - MyInviteCell delegate
extension MyInvitesVC: MyInviteCellDelegate {
    func share(_ cell: UITableViewCell) {
        eventKitManager.getCalendarPermissions { (success) in
            if success {
                guard let invites = self.myInvitesManager.invites else {
                    self.showError(title: "Error", message: "There was an error trying to share the invite into the current chat. Please try again.")
                    return
                }
                let message = MSMessage()
                let layout = MSMessageTemplateLayout()
                layout.caption = invites[cell.tag].value(forKey: "title") as? String ?? ""
                layout.subcaption = invites[cell.tag].value(forKey: "locationName") as? String ?? ""
                message.layout = layout

                message.md.set(value: invites[cell.tag].value(forKey: "title") as? String ?? "", forKey: "title")
                message.md.set(value: invites[cell.tag].value(forKey: "locationName") as? String ?? "", forKey: "subcaption")
                message.md.set(value: (invites[cell.tag].value(forKey: "startDate") as? Date ?? Date()).toString(), forKey: "startDate")
                message.md.set(value: (invites[cell.tag].value(forKey: "endDate") as? Date ?? Date()).toString(), forKey: "endDate")
                message.md.set(value: invites[cell.tag].value(forKey: "locationName") as? String ?? "", forKey: "locationName")
                message.md.set(value: invites[cell.tag].value(forKey: "locationLat") as? Double ?? 0.0, forKey: "locationLat")
                message.md.set(value: invites[cell.tag].value(forKey: "locationLon") as? Double ?? 0.0, forKey: "locationLon")
                message.md.set(value: invites[cell.tag].value(forKey: "locationStreet") as? String ?? "", forKey: "locationStreet")
                message.md.set(value: invites[cell.tag].value(forKey: "locationAddress") as? String ?? "", forKey: "locationAddress")
                message.md.set(value: invites[cell.tag].value(forKey: "locationCity") as? String ?? "", forKey: "locationCity")
                message.md.set(value: invites[cell.tag].value(forKey: "locationState") as? String ?? "", forKey: "locationState")
                message.md.set(value: invites[cell.tag].value(forKey: "locationCountry") as? String ?? "", forKey: "locationCountry")
                message.md.set(value: invites[cell.tag].value(forKey: "locationZip") as? String ?? "", forKey: "locationZip")

                if self.activeConversation == nil {
                    self.activeConvo?.insert(message) { (error) in
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
            } else {
                self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
            }
        }
    }

    func trash(_ cell: UITableViewCell) {
        eventKitManager.getCalendarPermissions { (success) in
            if success {
                let alert = UIAlertController(title: "Trash", message: "You are about to delete an invite. Doing so will delete it forever. Are you sure?", preferredStyle: .alert)
                let yes = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                    guard let invites = self.myInvitesManager.invites else {
                        self.showError(title: "Error", message: "There was an error trying to delete the invite in the current chat. Please try again.")
                        return
                    }
                    self.myInvitesManager.coreDataManager.delete(object: invites[cell.tag], { (success, error) in
                        if let err = error {
                            fatalError("Unresolved error \(err), \(err.localizedDescription)")
                            self.showError(title: "Error", message: "There was an error trying to delete the invite in the current chat. Please try again.")
                        } else {
                            self.myInvitesManager.removeInvite(atIndex: cell.tag)
                            self.invitesTable.reloadData()
                            self.inviteCountCheck()
                        }
                    })
                })
                let no = UIAlertAction(title: "No", style: .default, handler: { (action) in
                    alert.dismiss(animated: true, completion: nil)
                })
                alert.addAction(yes)
                alert.addAction(no)
                self.present(alert, animated: true, completion: nil)
            } else {
                self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
            }
        }
    }
}
