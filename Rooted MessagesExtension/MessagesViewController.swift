import UIKit
import Messages
import EventKit
import iMessageDataKit
import MapKit
import SSSpinnerButton
import CoreLocation
import CoreData

let kButtonRadius: CGFloat = 15.0
let kTextFieldIndent: CGFloat = 16.0

class MessagesViewController: MSMessagesAppViewController {

    @IBOutlet var titleField: UITextField!
    @IBOutlet var locationField: UITextField!
    @IBOutlet var startDateAndTimeField: UITextField!
    @IBOutlet var endDateAndTimeField: UITextField!
    @IBOutlet var premiumFeaturesLabel: UILabel!
    @IBOutlet var setAsReOcurringButton: SSSpinnerButton!
    @IBOutlet var setAsReocurringLabel: UILabel!
    @IBOutlet var sendToFriendsButton: SSSpinnerButton!
    @IBOutlet var resetButton: SSSpinnerButton!
    @IBOutlet var cancelButton: UIButton!

    var isReOcurring: Bool = false
    var isPremium: Bool = false
    let eventStore = EKEventStore()
    var activeConvo: MSConversation?
    var timeSelectorType: TimeSelectorType?
    var startDate: Date? {
        didSet {
            startDateAndTimeField.text = startDate?.toString(CustomDateFormat.normal)
        }
    }
    var endDate: Date? {
        didSet {
            endDateAndTimeField.text = endDate?.toString(CustomDateFormat.normal)
        }
    }
    var selectedLocation: (MKMapItem, MKPlacemark)? {
        didSet {
            locationField.text = selectedLocation?.0.name
        }
    }

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
    var selectedMessage: MSMessage?
    var locationManager: CLLocationManager?

    var invites: [NSManagedObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.applyPrimaryGradient()
        setUpTextFields()
        setUpButtons()
        setUpLabels()
        getCalendarPermissions()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }

    func setUpLabels() {
        premiumFeaturesLabel.isHidden = true
        setAsReocurringLabel.isHidden = true
    }

    func setUpTextFields() {
        titleField.delegate = self
        titleField.addLeftPadding(withWidth: kTextFieldIndent)
        locationField.delegate = self
        locationField.addLeftPadding(withWidth: kTextFieldIndent)
        startDateAndTimeField.delegate = self
        startDateAndTimeField.addLeftPadding(withWidth: kTextFieldIndent)
        endDateAndTimeField.delegate = self
        endDateAndTimeField.addLeftPadding(withWidth: kTextFieldIndent)
    }

    func setUpButtons() {
        setAsReOcurringButton.layer.cornerRadius = setAsReOcurringButton.frame.height / 2
        setAsReOcurringButton.clipsToBounds = true
        setAsReOcurringButton.spinnerColor = UIColor.gradientColor1
        setAsReOcurringButton.isHidden = true
        sendToFriendsButton.layer.cornerRadius = sendToFriendsButton.frame.height / 2
        sendToFriendsButton.clipsToBounds = true
        sendToFriendsButton.spinnerColor = UIColor.gradientColor1
    }

    func getCalendarPermissions() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            self.sendToFriendsButton.isEnabled = true
        case .denied:
            sendToFriendsButton.isEnabled = false
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion: { (granted: Bool, error: Error?) -> Void in
                if granted {
                    self.sendToFriendsButton.isEnabled = true
                } else {
                    self.sendToFriendsButton.isEnabled = false
                }
            })
        default: print("Case default")
        }
    }

    func createRootedCalendar() {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = MessagesViewController.calendarIdentifier
        let sourcesInEventStore = eventStore.sources
        newCalendar.source = sourcesInEventStore.filter{
            (source: EKSource) -> Bool in
            source.sourceType == EKSourceType.local
        }.first
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
        } catch {
            print(error)
            print("Error saving calendar")
        }
    }

    @IBAction func sendToFriends(_ sender: UIButton) {
        sendToFriendsButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {
            if let title = self.titleField.text, let startDate = self.startDate, let endDate = self.endDate {
                self.insertEvent(store: self.eventStore, title: title, startDate: startDate, endDate: endDate, location: self.selectedLocation, locationName: self.locationField.text ?? "")
                let message = MSMessage()
                let layout = MSMessageTemplateLayout()
                layout.caption = title
                layout.subcaption = self.locationField.text ?? ""
                message.layout = layout
                message.md.set(value: title, forKey: "title")
                message.md.set(value: self.locationField.text ?? "", forKey: "subcaption")
                message.md.set(value: startDate.toString(), forKey: "startDate")
                message.md.set(value: endDate.toString(), forKey: "endDate")
                if let loc = self.selectedLocation {
                    message.md.set(value: loc.0.name ?? "", forKey: "locationName")
                    message.md.set(value: loc.1.coordinate.latitude, forKey: "locationLat")
                    message.md.set(value: loc.1.coordinate.longitude, forKey: "locationLon")
                    message.md.set(value: loc.1.subThoroughfare ?? "", forKey: "locationStreet")
                    message.md.set(value: loc.1.thoroughfare ?? "Address Unavailable", forKey: "locationAddress")
                    message.md.set(value: loc.1.locality ?? "", forKey: "locationCity")
                    message.md.set(value: loc.1.administrativeArea ?? "", forKey: "locationState")
                    message.md.set(value: loc.1.countryCode ?? "", forKey: "locationCountry")
                    message.md.set(value: loc.1.postalCode ?? "", forKey: "locationZip")
                    message.md.set(value: loc.1.region?.identifier ?? "", forKey: "locationRegion")
                }
                if self.activeConversation == nil {
                    self.activeConvo?.insert(message) { (error) in
                        if let err = error {
                            self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail,backToDefaults: true, complete: {
                                print("There was an error \(err.localizedDescription)")
                            })
                        } else {
                            self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
                                self.sendToFriendsButton.setTitle("", for: .normal)
                                self.sendToFriendsButton.isHidden = true
                                self.cancelButton.setTitle("DONE", for: .normal)
                                self.save(endDate: endDate,
                                          locationAddress: message.md.string(forKey: "locationAddress") ?? "",
                                          locationCity: message.md.string(forKey: "locationCity") ?? "",
                                          locationCountry: message.md.string(forKey: "locationCountry") ?? "",
                                          locationLat: message.md.double(forKey: "locationLat") ?? 0.0,
                                          locationLon: message.md.double(forKey: "locationLon") ?? 0.0,
                                          locationName: message.md.string(forKey: "locationName") ?? "",
                                          locationState: message.md.string(forKey: "locationState") ?? "",
                                          locationStreet: message.md.string(forKey: "locationStreet") ?? "",
                                          locationZip: message.md.string(forKey: "locationZip") ?? "",
                                          startDate: startDate,
                                          title: title)
                            })
                        }
                    }
                } else {
                    self.activeConversation!.insert(message) { (error) in
                        if let err = error {
                            self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
                                print("There was an error \(err.localizedDescription)")
                            })
                        } else {
                            self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
                                self.sendToFriendsButton.setTitle("", for: .normal)
                                self.sendToFriendsButton.isHidden = true
                                self.cancelButton.setTitle("DONE", for: .normal)
                            })
                        }
                    }
                }
            } else {
                self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
                    let alert = UIAlertController(title: "Incomplete Form", message: "Please fill out the form", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                })
            }
        })
    }

    @IBAction func resetForm(_ sender: UIButton) {
        resetView()
    }

    @IBAction func setPremium(_ sender: UIButton) {
        if !isPremium {
            setAsReOcurringButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {
                self.setAsReOcurringButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: false, complete: {
                    self.isPremium = true
                })
            })
        } else {
            self.setAsReOcurringButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .none, backToDefaults: true, complete: {
                self.isPremium = false
            })
        }
    }

    func insertEvent(store: EKEventStore, title: String, startDate: Date, endDate: Date, location: (MKMapItem, MKPlacemark)?, locationName name: String) {
        let calendars = store.calendars(for: .event)
        var done = false
        for calendar in calendars {
            if calendar.type == MessagesViewController.calendarType && done == false {
                let event = EKEvent(eventStore: store)
                event.calendar = calendar
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.addAlarm(EKAlarm(relativeOffset: -10800))
                if let loc = location {
                    event.location = name
                    event.structuredLocation = EKStructuredLocation(mapItem: loc.0)
                }
                do {
                    try store.save(event, span: .thisEvent)
                    done = true
                } catch {
                    print(error.localizedDescription)
                    print("Error saving event in calendar")
                }
            }
        }
        DispatchQueue.main.async {
            if self.presentationStyle == .expanded {
                self.requestPresentationStyle(.compact)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goSelectTime" {
            let destination = segue.destination as! TimeSelectorVC
            destination.delegate = self
            destination.timeSelectorType = self.timeSelectorType
            if let proxyDate = startDate {
                destination.proxyDate = proxyDate
            }
        }
        if segue.identifier == "goSelectLocation" {
            let destination = segue.destination as! LocationSearchVC
            destination.locSearchDelegate = self
        }
        if segue.identifier == "goToInviteDetails" {
            guard let selectedMessage = self.selectedMessage else { return }
            sendToFriendsButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {
                self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
                    guard
                        let title = selectedMessage.md.string(forKey: "title"),
                        let startDate = selectedMessage.md.string(forKey: "startDate")?.toDate(),
                        let endDate = selectedMessage.md.string(forKey: "endDate")?.toDate() else { return }

                    let destination = segue.destination as! InviteDetailsVC
                    destination.eventStore = self.eventStore
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
                    destination.viewDidLoad()
                })
            })
        }
    }

    func resetView() {
        titleField.text = ""
        timeSelectorType = nil
        startDate = nil
        endDate = nil
        selectedLocation = nil
    }

    func save(endDate: Date,
              locationAddress: String,
              locationCity: String,
              locationCountry: String,
              locationLat: Double,
              locationLon: Double,
              locationName: String,
              locationState: String,
              locationStreet: String,
              locationZip: String,
              startDate: Date,
              title: String) {
        let managedContext = persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "Invite", in: managedContext) else { return }
        let invite = NSManagedObject(entity: entity, insertInto: managedContext)
        invite.setValuesForKeys([
            "endDate": endDate,
            "locationAddress": locationAddress,
            "locationCity": locationCity,
            "locationCountry": locationCountry,
            "locationLat": locationLat,
            "locationLon": locationLon,
            "locationName": locationName,
            "locationState": locationState,
            "locationStreet": locationStreet,
            "locationZip": locationZip,
            "startDate": startDate,
            "title": title,
        ])
        do {
            try managedContext.save()
            invites.append(invite)
        } catch let error {
            print("Could not save. \(error.localizedDescription)")
            let alert = UIAlertController(title: "Error", message: "There was an error please try again.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil, userInfo: [:])
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Conversation Handling
extension MessagesViewController {
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
        resetView()
    }
}

extension MessagesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        DispatchQueue.main.async {
            if self.presentationStyle != .expanded {
                self.requestPresentationStyle(.expanded)
            }
        }
        if textField == startDateAndTimeField {
            timeSelectorType = .start
            performSegue(withIdentifier: "goSelectTime", sender: self)
        }
        if textField == endDateAndTimeField {
            timeSelectorType = .end
            performSegue(withIdentifier: "goSelectTime", sender: self)
        }
        if textField == locationField {
            if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .notDetermined {
                self.locationManager?.requestWhenInUseAuthorization()
            } else {
                performSegue(withIdentifier: "goSelectLocation", sender: self)
            }
        }
        return true
    }
}

extension MessagesViewController: TimeSelectorDelegate {
    func selectDate(_ selectorVC: TimeSelectorVC, selectedDate date: Date, selectorType type: TimeSelectorType) {
        if type == .start {
            startDate = date
        }

        if type == .end {
            endDate = date
        }
    }
}

extension MessagesViewController: LocationSearchDelegate {
    func selectLocation(_ searchVC: LocationSearchVC, selectedLocation location: (MKMapItem, MKPlacemark)) {
        selectedLocation = location
    }
}

extension MessagesViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.view.endEditing(true)
    }
}

extension MessagesViewController {
    static var calendarIdentifier: String {
        return "Calendar"
    }
    static var calendarType: EKCalendarType {
        return EKCalendarType.calDAV
    }
}

// MARK: - Core Data Stack
extension MessagesViewController {
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
