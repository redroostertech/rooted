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

private var dateFormatString = "M/dd/yyyy h:mm aa"

class MessagesViewController: MSMessagesAppViewController {

  @IBOutlet private weak var titleField: UITextField!
  @IBOutlet private weak var locationField: UITextField!
  @IBOutlet private weak var startDateAndTimeButton: UIButton!
  @IBOutlet private weak var endDateAndTimeButton: UIButton!
  @IBOutlet private weak var premiumFeaturesLabel: UILabel!
  @IBOutlet private weak var setAsReOcurringButton: SSSpinnerButton!
  @IBOutlet private weak var setAsReocurringLabel: UILabel!
  @IBOutlet private weak var sendToFriendsButton: SSSpinnerButton!
  @IBOutlet private weak var resetButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!

  var eventKitManager = EventKitManager()
  var coreDataManager = CoreDataManager()
  var invitesManager = MyInvitesManager()

  var isReOcurring: Bool = false
  var isPremium: Bool = false
  let eventStore = EKEventStore()
  var activeConvo: MSConversation?
  var startDate: Date? {
      didSet {
        startDateAndTimeButton.setTitle(startDate?.toString(format: dateFormatString), for: .normal)
      }
  }
  var endDate: Date? {
      didSet {
        endDateAndTimeButton.setTitle(endDate?.toString(format: dateFormatString), for: .normal)
      }
  }
  var selectedLocation: (MKMapItem, MKPlacemark)? {
      didSet {
          locationField.text = selectedLocation?.0.name
      }
  }
  var selectedMessage: MSMessage?
  var locationManager: CLLocationManager?

  var invites: [NSManagedObject] = []

  var isCalendarShowing: Bool = false
  var startDatePicker: DateTimePicker!
  var endDatePicker: DateTimePicker!

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupDatePickers()
    setupUI()
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.desiredAccuracy = kCLLocationAccuracyBest
  }

    override func viewWillAppear(_ animated: Bool) {
        eventKitManager.getCalendarPermissions { (success) in
            if success {
                self.sendToFriendsButton.isEnabled = true
            } else {
                self.sendToFriendsButton.isEnabled = false
                self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. Please go to your settings and enable this feature.")
            }
        }
    }

    // MARK: - Class functions
    func send(message: MSMessage, toConversation conversation: MSConversation?, _ completion: @escaping (Bool) -> Void) {
        conversation?.insert(message) { (error) in
            if let err = error {
                self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail,backToDefaults: true, complete: {
                    print("There was an error \(err.localizedDescription)")
                    completion(false)
                })
            } else {
                self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
                    completion(true)
                })
            }
        }
    }

    func saveInviteToCoreData(endDate: Date, startDate: Date, title: String, message: MSMessage) {
        self.invitesManager.saveInvite(endDate: endDate,
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
                                       title: title, {
                                        (success, error) in
                                        DispatchQueue.main.async {
                                            if self.presentationStyle == .expanded {
                                                self.requestPresentationStyle(.compact)
                                            }
                                        }
        })
    }

    func sendToFriendsAction() {
        sendToFriendsButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {
            guard let title = self.titleField.text,
                let startDate = self.startDate,
                let endDate = self.endDate else {
                    self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
                        self.showError(title: "Incomplete Form", message: "Please fill out the form")
                    })
                    return
            }
            self.eventKitManager.insertEvent(title: title,
                                             startDate: startDate,
                                             endDate: endDate,
                                             location: self.selectedLocation,
                                             locationName: self.locationField.text ?? "", {
                                                (success, error) in
                                                if let err = error {
                                                    DispatchQueue.main.async {
                                                        if self.presentationStyle == .expanded {
                                                            self.requestPresentationStyle(.compact)
                                                        }
                                                    }
                                                } else {
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

                                                    self.send(message: message, toConversation: self.activeConvo ?? self.activeConversation, { (success) in
                                                        if success {
                                                            self.sendToFriendsButton.setTitle("", for: .normal)
                                                            self.sendToFriendsButton.isHidden = true
                                                            self.cancelButton.setTitle("DONE", for: .normal)
                                                            self.saveInviteToCoreData(endDate: endDate, startDate: startDate, title: title, message: message)
                                                        }
                                                    })
                                                }
            })
        })
    }

    func setPremiumAction() {
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

    func resetView() {
        titleField.text = ""
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

        invitesManager.saveInvite(endDate: endDate,
                                  locationAddress: locationAddress,
                                  locationCity: locationCity,
                                  locationCountry: locationCountry,
                                  locationLat: locationLat,
                                  locationLon: locationLon,
                                  locationName: locationName,
                                  locationState: locationState,
                                  locationStreet: locationStreet,
                                  locationZip: locationZip,
                                  startDate: startDate,
                                  title: title) { (success, error) in

                                    if let err = error {
                                        print("Could not save. \(err.localizedDescription)")
                                        self.showError(title: "Error", message: "There was an error trying to save invite. Please try again.")
                                    } else {

                                    }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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

  private var isStartCalendarShowing: Bool = false
  private var isEndCalendarShowing: Bool = false

    // MARK: - UI actions
  @IBAction func showStartCalendar(_ sender: UIButton) {
    // If both are empty
    if !isStartCalendarShowing {

      isStartCalendarShowing = true

      isEndCalendarShowing = false
      if endDatePicker != nil {
        endDatePicker.removeFromSuperview()
      }

      let yOrigin = self.view.frame.maxY - startDatePicker.frame.size.height
      let width = startDatePicker.frame.size.width
      let height = startDatePicker.frame.size.height
      startDatePicker.frame = CGRect(x: 0, y: yOrigin, width: width, height: height)
      self.view.addSubview(startDatePicker)

    } else {

      isStartCalendarShowing = false
      startDatePicker.removeFromSuperview()

    }

  }

  @IBAction func showEndCalendar(_ sender: UIButton) {
    if let proxyDate = startDate {
      self.setupEndDatePicker(withDate: proxyDate)
    } else {
      self.setupEndDatePicker(withDate: Date())
    }

    // If both are empty
    if !isEndCalendarShowing {

      isEndCalendarShowing = true

      isStartCalendarShowing = false
      if startDatePicker != nil {
        startDatePicker.removeFromSuperview()
      }

      let yOrigin = self.view.frame.maxY - endDatePicker.frame.size.height
      let width = endDatePicker.frame.size.width
      let height = endDatePicker.frame.size.height
      endDatePicker.frame = CGRect(x: 0, y: yOrigin, width: width, height: height)
      self.view.addSubview(endDatePicker)

    } else {

      isEndCalendarShowing = false
      endDatePicker.removeFromSuperview()

    }

  }

  @IBAction func sendToFriends(_ sender: UIButton) {
        sendToFriendsAction()
    }

    @IBAction func resetForm(_ sender: UIButton) {
        resetView()
    }

    @IBAction func setPremium(_ sender: UIButton) {
        setPremiumAction()
    }

    @IBAction func cancelAction(_ sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil, userInfo: [:])
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UI updates
extension MessagesViewController {
  func setupUI() {
    view.applyPrimaryGradient()
    setUpTextFields()
    setUpButtons()
    setUpLabels()
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

  func setupDatePickers() {
    setupStartDatePicker()
  }

  func setupStartDatePicker() {
    let max = Date().addingTimeInterval(60 * 60 * 24 * 7)
    let picker = DateTimePicker.create(minimumDate: Date(), maximumDate: max)

    picker.identifier = "start"

    // Set the container view as without it, view will not be able to render
    picker.containerView = self.view

    picker.timeInterval = DateTimePicker.MinuteInterval.thirty
    picker.locale = .autoupdatingCurrent

    picker.todayButtonTitle = "Today"
    picker.is12HourFormat = true
    picker.dateFormat = dateFormatString
    picker.includeMonth = true
    picker.highlightColor = .gradientColor1
    picker.doneButtonTitle = "Done"
    picker.doneBackgroundColor = .gradientColor1
    picker.customFontSetting = DateTimePicker.CustomFontSetting(selectedDateLabelFont: .boldSystemFont(ofSize: 20))
    picker.normalColor = UIColor.white
    picker.darkColor = UIColor.black
    picker.contentViewBackgroundColor = UIColor.white
    picker.completionHandler = { date in
      self.isCalendarShowing = false
    }
    picker.delegate = self
    picker.dismissHandler = {
      self.isCalendarShowing = false
      picker.removeFromSuperview()
    }
    startDatePicker = picker
  }

  func setupEndDatePicker(withDate date: Date) {
    let max = date.addingTimeInterval(60 * 60 * 24 * 7)
    let picker = DateTimePicker.create(minimumDate: date, maximumDate: max)

    picker.identifier = "end"

    // Set the container view as without it, view will not be able to render
    picker.containerView = self.view

    picker.timeInterval = DateTimePicker.MinuteInterval.thirty
    picker.locale = .autoupdatingCurrent

    picker.todayButtonTitle = "Today"
    picker.is12HourFormat = true
    picker.dateFormat = dateFormatString
    picker.includeMonth = true
    picker.highlightColor = .gradientColor1
    picker.doneButtonTitle = "Done"
    picker.doneBackgroundColor = .gradientColor1
    picker.customFontSetting = DateTimePicker.CustomFontSetting(selectedDateLabelFont: .boldSystemFont(ofSize: 20))
    picker.normalColor = UIColor.white
    picker.darkColor = UIColor.black
    picker.contentViewBackgroundColor = UIColor.white
    picker.completionHandler = { date in
      self.isCalendarShowing = false
    }
    picker.delegate = self
    picker.dismissHandler = {
      self.isCalendarShowing = false
      picker.removeFromSuperview()
    }
    endDatePicker = picker
  }
}

// MARK: - DateTimePickerDelegate
extension MessagesViewController: DateTimePickerDelegate {
  func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {

    if let identifier = picker.identifier {
      if identifier == "start" {
        self.startDate = didSelectDate
      }
      if identifier == "end" {
        self.endDate = didSelectDate
      }
    }

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

// MARK: - UITextField delegate
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

// MARK: - LocationSearch delegate
extension MessagesViewController: LocationSearchDelegate {
    func selectLocation(_ searchVC: LocationSearchVC, selectedLocation location: (MKMapItem, MKPlacemark)) {
        selectedLocation = location
    }
}

// MARK: - CLLocationManager delegate
extension MessagesViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.view.endEditing(true)
    }
}
