import UIKit
import Messages
import EventKit
import iMessageDataKit
import MapKit
import SSSpinnerButton
import CoreLocation
import CoreData

public let kCalendarPermissions = "Calendar Permissions"
public let kCalendarAccess = "To use Rooted, please go to your settings and enable access to your calendar."

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

let kButtonRadius: CGFloat = 15.0
let kTextFieldIndent: CGFloat = 16.0

private var dateFormatString = "M/dd/yyyy h:mm aa"

class BaseAppViewController: MSMessagesAppViewController {
  var appInitializer = AppInitializer.main
}

class MessagesViewController: BaseAppViewController {

  @IBOutlet private weak var titleField: UITextField!
  @IBOutlet private weak var locationSelectionLabel: UILabel!
  @IBOutlet private weak var locationSelectionButton: UIButton!
  @IBOutlet private weak var startDateAndTimeButton: UIButton!
  @IBOutlet private weak var endDateAndTimeButton: UIButton!
  @IBOutlet private weak var premiumFeaturesLabel: UILabel!
  @IBOutlet private weak var setAsReOcurringButton: SSSpinnerButton!
  @IBOutlet private weak var setAsReocurringLabel: UILabel!
  @IBOutlet private weak var sendToFriendsButton: SSSpinnerButton!
  @IBOutlet private weak var resetButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!

  private var isStartCalendarShowing: Bool = false
  private var isEndCalendarShowing: Bool = false

  private var eventKitManager = EventKitManager()
  private var coreDataManager = CoreDataManager()
  private var invitesManager = MyInvitesManager()

  var isReOcurring: Bool = false
  var isPremium: Bool = false
  let eventStore = EKEventStore()

  var currentConversation: MSConversation? {
    return activeConvo ?? self.activeConversation
  }

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
  var selectedLocation: RLocation? {
      didSet {
        guard let selectedlocation = self.selectedLocation else { return }
        locationSelectionLabel.text = selectedlocation.readableWhereString
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
        self.showError(title: kCalendarPermissions, message: kCalendarAccess)
      }
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    if segue.identifier == "goSelectLocation" {
      guard let destination = segue.destination as? LocationSearchVC else { return }
      destination.locSearchDelegate = self
    }

    if segue.identifier == "goToInviteDetails" {

      guard let selectedMessage = self.selectedMessage else { return }

      sendToFriendsButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {

        self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
          guard
            let title = selectedMessage.md.string(forKey: kMessageTitleKey),
            let startDate = selectedMessage.md.string(forKey: kMessageStartDateKey)?.toDate(),
            let endDate = selectedMessage.md.string(forKey: kMessageEndDateKey)?.toDate(), let destination = segue.destination as? InviteDetailsVC  else { return }

          destination.titleText = title
          destination.startDate = startDate
          destination.endDate = endDate

          if let locationString = selectedMessage.md.string(forKey: kMessageLocationStringKey), let rLocation = RLocation(JSONString: locationString) {
            destination.rLocation = rLocation
          }
          destination.viewDidLoad()
        })
      })
    }
  }


  // MARK: - Private UI methods
  private func resetView() {
    titleField.text = ""
    startDate = nil
    endDate = nil
    selectedLocation = nil
  }

  private func setupSendToFriendsButton() {
    sendToFriendsButton.layer.cornerRadius = sendToFriendsButton.frame.height / 2
    sendToFriendsButton.clipsToBounds = true
    sendToFriendsButton.spinnerColor = UIColor.gradientColor1
  }

  private func setupReocurringButton() {
    setAsReOcurringButton.layer.cornerRadius = setAsReOcurringButton.frame.height / 2
    setAsReOcurringButton.clipsToBounds = true
    setAsReOcurringButton.spinnerColor = UIColor.gradientColor1
    setAsReOcurringButton.isHidden = true
  }

  private func setupUI() {
    view.applyPrimaryGradient()
    setUpTextFields()
    setUpButtons()
    setUpLabels()
  }

  private func setUpLabels() {
    premiumFeaturesLabel.isHidden = true
    setAsReocurringLabel.isHidden = true
  }

  private func setUpTextFields() {
    titleField.delegate = self
    titleField.addLeftPadding(withWidth: kTextFieldIndent)
  }

  private func setUpButtons() {
    setupReocurringButton()
    setupSendToFriendsButton()
  }

  private func setupDatePickers() {
    setupStartDatePicker()
  }

  private func setupStartDatePicker() {
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

  private func setupEndDatePicker(withDate date: Date) {
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


  // MARK: - Private business logic methods
  private func generateMessage(title: String, endDate: Date, startDate: Date, location: RLocation?) -> MSMessage {

    let message = MSMessage()
    var subcaption = ""

    let layout = MSMessageTemplateLayout()
    layout.caption = String(format: captionString, arguments: [title, startDate.toString(.rooted)])

    message.md.set(value: title, forKey: kMessageTitleKey)
    message.md.set(value: startDate.toString(), forKey: kMessageStartDateKey)
    message.md.set(value: endDate.toString(), forKey: kMessageEndDateKey)

    if let loc = location, let locationString = loc.toJSONString() {
      subcaption += loc.readableWhereString
      message.md.set(value: loc.readableWhereString, forKey: kMessageSubCaptionKey)
      message.md.set(value: locationString, forKey: kMessageLocationStringKey)
    }

    layout.subcaption = subcaption
    message.layout = layout

    return message
  }

  private func insertEvent(title: String, endDate: Date, startDate: Date, location: RLocation?) {
    self.eventKitManager.insertEvent(title: title, startDate: startDate, endDate: endDate, location: self.selectedLocation, {
      (success, error) in
      if let _ = error {
        DispatchQueue.main.async {
          if self.presentationStyle == .expanded {
            self.requestPresentationStyle(.compact)
          }
        }

        // TODO: - Handle error
      } else {
        if success {

          let message = self.generateMessage(title: title, endDate: endDate, startDate: startDate, location: self.selectedLocation)

          // Save invite to Core Data
          self.saveInviteToCoreData(endDate: endDate, startDate: startDate, title: title, message: message)

          self.send(message: message, toConversation: self.currentConversation, { success in
            if success {
              self.sendToFriendsButton.setTitle("", for: .normal)
              self.sendToFriendsButton.isHidden = true
              self.cancelButton.setTitle("DONE", for: .normal)
            }
          })

        } else {
          // TODO: - Handle success of false
        }
      }

    })
  }

  private func saveInviteToCoreData(endDate: Date, startDate: Date, title: String, message: MSMessage) {
    self.invitesManager.save(title: title, endDate: endDate, startDate: startDate, location: self.selectedLocation) { (success, error) in
      DispatchQueue.main.async {
        if self.presentationStyle == .expanded {
          self.requestPresentationStyle(.compact)
        }
      }
    }
  }

  private func send(message: MSMessage, toConversation conversation: MSConversation?, _ completion: @escaping (Bool) -> Void) {
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

  private func sendToFriendsAction() {
      sendToFriendsButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {
          guard let title = self.titleField.text,
              let startDate = self.startDate,
              let endDate = self.endDate else {

                  self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
                      self.showError(title: "Incomplete Form", message: "Please fill out the form")
                  })
                  return
          }
        self.insertEvent(title: title, endDate: endDate, startDate: startDate, location: self.selectedLocation)
      })
  }

  private func setPremiumAction() {
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

  @IBAction func selectLocation(_ sender: UIButton) {
    if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .notDetermined {
      self.locationManager?.requestWhenInUseAuthorization()
    } else {
      performSegue(withIdentifier: "goSelectLocation", sender: self)
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
        return true
    }
}

// MARK: - LocationSearch delegate
extension MessagesViewController: LocationSearchDelegate {
  func selectLocation(_ searchVC: LocationSearchVC, location: RLocation?) {
    selectedLocation = location
  }
}

// MARK: - CLLocationManager delegate
extension MessagesViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.view.endEditing(true)
    }
}
