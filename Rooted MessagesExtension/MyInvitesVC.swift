import UIKit
import Messages
import CoreData
import iMessageDataKit
import EventKit
import MapKit
import NotificationCenter

class MyInvitesVC: MSMessagesAppViewController {
    @IBOutlet var invitesTable: UITableView!
    @IBOutlet var addButton: UIButton!
    var myInvitesManager = MyInvitesManager()
    let eventStore = EKEventStore()
    var activeConvo: MSConversation?
    var selectedMessage: MSMessage?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.applyPrimaryGradient()
        addButton.applyCornerRadius()
        myInvitesManager.delegate = self
        invitesTable.delegate = myInvitesManager
        invitesTable.dataSource = myInvitesManager
        invitesTable.register(UINib(nibName: MyInviteCell.identifier, bundle: nil), forCellReuseIdentifier: MyInviteCell.identifier)
        invitesTable.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(inviteCountCheck), name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        inviteCountCheck()
    }
    @IBAction func addAction(_ sender: UIButton) {
        performSegue(withIdentifier: "goToAddInviteVC", sender: self)
    }
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

            destination.eventStore = eventStore
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
        myInvitesManager.retrieveInvites {
            self.invitesTable.reloadData()
            if self.myInvitesManager.invites.count >= 3 {
                self.addButton.isEnabled = false
            } else {
                self.addButton.isEnabled = true
            }
        }
    }
}

extension MyInvitesVC {
    override func willBecomeActive(with conversation: MSConversation) {
        DispatchQueue.main.async {
            if self.presentationStyle != .expanded {
                self.requestPresentationStyle(.expanded)
            }
        }
        activeConvo = conversation
        guard let selectedMessage = conversation.selectedMessage else { return }
        self.selectedMessage = selectedMessage
        performSegue(withIdentifier: "goToInviteDetails", sender: self)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        activeConvo = conversation
    }
}

extension MyInvitesVC: MyInviteCellDelegate {
    func share(_ cell: UITableViewCell) {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        layout.caption = myInvitesManager.invites[cell.tag].value(forKey: "title") as? String ?? ""
        layout.subcaption = myInvitesManager.invites[cell.tag].value(forKey: "locationName") as? String ?? ""
        message.layout = layout

        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "title") as? String ?? "", forKey: "title")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationName") as? String ?? "", forKey: "subcaption")
        message.md.set(value: (myInvitesManager.invites[cell.tag].value(forKey: "startDate") as? Date ?? Date()).toString(), forKey: "startDate")
        message.md.set(value: (myInvitesManager.invites[cell.tag].value(forKey: "endDate") as? Date ?? Date()).toString(), forKey: "endDate")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationName") as? String ?? "", forKey: "locationName")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationLat") as? Double ?? 0.0, forKey: "locationLat")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationLon") as? Double ?? 0.0, forKey: "locationLon")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationStreet") as? String ?? "", forKey: "locationStreet")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationAddress") as? String ?? "", forKey: "locationAddress")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationCity") as? String ?? "", forKey: "locationCity")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationState") as? String ?? "", forKey: "locationState")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationCountry") as? String ?? "", forKey: "locationCountry")
        message.md.set(value: myInvitesManager.invites[cell.tag].value(forKey: "locationZip") as? String ?? "", forKey: "locationZip")

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
    }

    func trash(_ cell: UITableViewCell) {
        let alert = UIAlertController(title: "Trash", message: "You are about to delete an invite. Doing so will delete it forever. Are you sure?", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.myInvitesManager.persistentContainer.viewContext.delete(self.myInvitesManager.invites[cell.tag])
            do {
                try self.myInvitesManager.persistentContainer.viewContext.save()
                self.myInvitesManager.invites.remove(at: cell.tag)
                self.invitesTable.reloadData()
                self.inviteCountCheck()
            } catch let error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        })
        let no = UIAlertAction(title: "No", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(yes)
        alert.addAction(no)
        self.present(alert, animated: true, completion: nil)
    }
}

class MyInvitesManager: NSObject, UITableViewDelegate, UITableViewDataSource {

    var invites: [NSManagedObject] = []

    lazy var applicationDocumentsDirectory: URL? = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.yourdomain.YourAwesomeApp" in the application's documents Application Support directory.
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rrtech.rooted.Rooted") ?? nil
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Invites")
        var persistentStoreDescriptions: NSPersistentStoreDescription

        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = applicationDocumentsDirectory ?? nil

        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: applicationDocumentsDirectory!.appendingPathComponent("Rooted.sqlite"))]

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Successfully connected to store.")
            }
        })
        return container
    }()
    var delegate: MyInviteCellDelegate?

    override init() {
        super.init()
        retrieveInvites()
    }

    // MARK: - Fetch data
    func retrieveInvites(_ completion: (() -> Void)? = nil) {
        let managedContext = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Invite")
        do {
            invites = try managedContext.fetch(fetchRequest)
            completion?()
        } catch let error {
            print("Could not retrieve results. \(error.localizedDescription)")
            completion?()
        }
    }

    func deleteInvite(_ invite: NSManagedObject) {
        let managedContext = persistentContainer.viewContext
        managedContext.delete(invite)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MyInviteCell.identifier) as? MyInviteCell else {
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        cell.delegate = delegate
        let item = invites[indexPath.row]
        if let title = item.value(forKey: "title") as? String {
            cell.titleLabel?.text = title
        }
        if let locationName = item.value(forKey: "locationName") as? String {
            cell.whereLabel?.text = locationName
        }
        if let startDate = item.value(forKey: "startDate") as? Date, let endDate = item.value(forKey: "endDate") as? Date {
            cell.whenLabel?.text = startDate.toString(.rooted) + " to " + endDate.toString(.rooted)
        }
        return cell
    }
}
