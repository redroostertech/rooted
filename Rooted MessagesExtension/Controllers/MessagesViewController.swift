import UIKit
import Messages
import EventKit
import iMessageDataKit
import MapKit
import SSSpinnerButton
import CoreLocation
import CoreData
import ObjectMapper

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
private let interval = DateTimePicker.MinuteInterval.fifteen

class BaseAppViewController: MSMessagesAppViewController {
  var appInitializer = AppInitializer.main
}

private var meetingTimeLength = [
  [
    "id": 0,
    "length": 30,
    "name": "30 minutes",
    "type": "min"
  ],
  [
    "id": 1,
    "length": 60,
    "name": "1 hour",
    "type": "min"
  ],
  [
    "id": 2,
    "length": 90,
    "name": "1.5 hours",
    "type": "min"
  ],
  [
    "id": 3,
    "length": 120,
    "name": "2 hours",
    "type": "min"
  ],
  [
    "id": 4,
    "length": 0,
    "name": "Custom",
    "type": "min"
  ]
]

class MeetingTimeLength: Mappable {
  var id: Int?
  var length: Int?
  var name: String?
  var type: String?

  required init?(map: Map) { }

  func mapping(map: Map) {
    id <- map["id"]
    length <- map["length"]
    name <- map["name"]
    type <- map["type"]
  }
}

class MessagesViewController: BaseAppViewController {

  @IBOutlet private weak var titleField: UITextField!
  @IBOutlet private weak var locationSelectionLabel: UILabel!
  @IBOutlet private weak var locationSelectionButton: UIButton!
  @IBOutlet private weak var startDateAndTimeButton: UIButton!
  @IBOutlet private weak var endDateAndTimeTextField: UITextField!
  @IBOutlet private weak var premiumFeaturesLabel: UILabel!
  @IBOutlet private weak var setAsReOcurringButton: SSSpinnerButton!
  @IBOutlet private weak var setAsReocurringLabel: UILabel!
  @IBOutlet private weak var sendToFriendsButton: SSSpinnerButton!
  @IBOutlet private weak var resetButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

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

  var eventTitle: String?

  var startDate: Date? {
      didSet {
        startDateAndTimeButton.setTitle(startDate?.toString(format: dateFormatString), for: .normal)
      }
  }
  var endDate: Date? {
      didSet {
        endDateAndTimeTextField.text = endDate?.toString(format: dateFormatString)
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

  var meetingTime = [MeetingTimeLength]()
  var meetingTimePicker: UIPickerView!
  var meetingTimePickerToolbar: UIToolbar!

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupDatePickers()
    setupUI()
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.desiredAccuracy = kCLLocationAccuracyBest

    // Load meeting times in array
    for meeting in meetingTimeLength {
      guard let meetingtimelength = MeetingTimeLength(JSON: meeting) else { return }
      meetingTime.append(meetingtimelength)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    eventKitManager.getCalendarPermissions { (success) in
      if success {
        self.sendToFriendsButton.isEnabled = true
      } else {
        self.sendToFriendsButton.isEnabled = false
        self.showError(title: kCalendarPermissions, message: kCalendarAccess)
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    setupTimePicker()
  }

  override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    super.willTransition(to: presentationStyle)
    setupTimePicker()
  }

  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)
    DispatchQueue.main.async {
      if self.presentationStyle != .expanded {
        self.requestPresentationStyle(.expanded)
      }
    }
    activeConvo = conversation
    guard let selectedMessage = conversation.selectedMessage else { return }
    self.selectedMessage = selectedMessage
  }

  override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
    super.didStartSending(message, conversation: conversation)
    activeConvo = conversation
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

  // MARK: - Private methods
  @objc private func donePicker() {
    meetingTimePicker.removeFromSuperview()
    meetingTimePickerToolbar.removeFromSuperview()
    self.view.endEditing(true)
  }

  @objc private func cancelPicker() {
    endDate = nil
    meetingTimePicker.removeFromSuperview()
    meetingTimePickerToolbar.removeFromSuperview()
    self.view.endEditing(true)
  }

  private func setupTimePicker() {
    // Load meeting times into picker
    let picker = UIPickerView(frame: CGRect(x: .zero, y: self.actionsContainerView.frame.minY - 200, width: self.view.bounds.width, height: 200))
    picker.backgroundColor = .white
    picker.delegate = self
    picker.dataSource = self
    picker.showsSelectionIndicator = true

    let toolBar = UIToolbar(frame: CGRect(x: .zero, y: picker.frame.minY - 44, width: self.view.bounds.width, height: 44))
    toolBar.barStyle = UIBarStyle.default
    toolBar.isTranslucent = false
    toolBar.tintColor = .darkText
    toolBar.sizeToFit()

    let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(donePicker))
    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
    let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelPicker))

    toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
    toolBar.isUserInteractionEnabled = true

    endDateAndTimeTextField.inputView = picker
    endDateAndTimeTextField.inputAccessoryView = toolBar

    meetingTimePickerToolbar = toolBar
    meetingTimePicker = picker
  }

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
    titleField.placeHolderColor = .white
    endDateAndTimeTextField.delegate = self
    endDateAndTimeTextField.placeHolderColor = .white
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

    let picker = DateTimePicker.create(minimumDate: Date().retrieveNextInterval(interval: interval.rawValue), maximumDate: max)

    picker.identifier = "start"

    // Set the container view as without it, view will not be able to render
    picker.containerView = self.view

    picker.timeInterval = interval
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
      self.isStartCalendarShowing = false
      self.isEndCalendarShowing = false
      self.startDate = date
      self.meetingTimePickerToolbar.removeFromSuperview()
    }
    picker.delegate = self
    picker.dismissHandler = {
      self.isStartCalendarShowing = false
      self.isEndCalendarShowing = false
      picker.removeFromSuperview()
      self.meetingTimePickerToolbar.removeFromSuperview()
    }
    startDatePicker = picker
  }

  private func setupEndDatePicker(withDate date: Date) {
    let max = date.addingTimeInterval(60 * 60 * 24 * 7)
    let picker = DateTimePicker.create(minimumDate: date, maximumDate: max)

    picker.identifier = "end"

    // Set the container view as without it, view will not be able to render
    picker.containerView = self.view

    picker.timeInterval = interval
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
      self.isStartCalendarShowing = false
      self.isEndCalendarShowing = false
      self.endDate = date
    }
    picker.delegate = self
    picker.dismissHandler = {
      self.isStartCalendarShowing = false
      self.isEndCalendarShowing = false
      picker.removeFromSuperview()
    }
    endDatePicker = picker
  }

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
              self.dismiss(animated: true, completion: nil)
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
    conversation?.send(message) { (error) in
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
            title != "",
              let startDate = self.startDate,
              let endDate = self.endDate else {

                  self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
                      self.showError(title: "Incomplete Form", message: "Please fill out the entire form to create an invite.")
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

  private func showEndCalendar() {
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

  // MARK: - UI actions
  @IBAction func showStartCalendar(_ sender: UIButton) {
    // If both are empty
    meetingTimePicker.removeFromSuperview()

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

  // MARK: - IBActions
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

// MARK: - UITextField delegate
extension MessagesViewController: UITextFieldDelegate {

  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == endDateAndTimeTextField {
      isStartCalendarShowing = false
      isEndCalendarShowing = false
      if startDatePicker != nil {
        startDatePicker.removeFromSuperview()
      }
      if endDatePicker != nil {
        endDatePicker.removeFromSuperview()
      }

      textField.resignFirstResponder()
      self.view.addSubview(meetingTimePicker)
      self.view.addSubview(meetingTimePickerToolbar)
    }
  }

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

// MARK: - UIPickerViewDelegate and Datasource
extension MessagesViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return meetingTime.count
  }

  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 36
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    let item = meetingTime[row]
    return item.name ?? ""
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard let startdate = self.startDate else {
      return self.showError(title: "Missing Start Time", message: "Please provide a start date/time.")
    }
    let item = meetingTime[row]

    guard let id = item.id, id != 4 else {
      meetingTimePicker.removeFromSuperview()
      meetingTimePickerToolbar.removeFromSuperview()
      self.view.endEditing(true)
      showEndCalendar()
      return
    }

    guard let length = item.length else {
      endDate = startdate.add(minutes: 60)
      return
    }
    endDate = startdate.add(minutes: length)
  }
}
