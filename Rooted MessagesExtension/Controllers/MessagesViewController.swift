import UIKit
import Messages
import EventKit
import iMessageDataKit
import MapKit
import SSSpinnerButton
import CoreLocation
import CoreData
import ObjectMapper
import Branch

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

// The url which will be used to encode the current state of the app that can be reconstructed when the recipient receives the message.
func prepareUrl() -> URL {
//  var urlComponents = URLComponents()
//  urlComponents.scheme = "https";
//  urlComponents.host = "www.ebookfrenzy.com";
//  let playerQuery = URLQueryItem(name: "currentPlayer",
//                                 value: currentPlayer)
//
//  urlComponents.queryItems = [playerQuery]
//
//  for (index, setting) in gameStatus.enumerated() {
//    let queryItem = URLQueryItem(name: "position\(index)",
//      value: setting)
//    urlComponents.queryItems?.append(queryItem)
//  }
//  return urlComponents.url!
  return URL(fileURLWithPath: "/")
}

// Decode the incoming url and update
func decodeURL(_ url: URL) {

//  let components = URLComponents(url: url,
//                                 resolvingAgainstBaseURL: false)
//
//  for (index, queryItem) in (components?.queryItems?.enumerated())! {
//
//    if queryItem.name == "currentPlayer" {
//      currentPlayer = queryItem.value == "X" ? "O" : "X"
//    } else if queryItem.value != "-" {
//      gameStatus[index-1] = queryItem.value!
//      Buttons[index-1].setTitle(queryItem.value!, for: .normal)
//    }
//  }
}

class MeetingModelBuilder {
  var dictionary: [String: Any]?
  var meeting: Meeting?

  func start() -> MeetingModelBuilder {
    self.dictionary = [String: Any]()
    return self
  }

  func retrieve(forKey key: String) -> Any? {
    if dictionary != nil {
      if dictionary![key] != nil {
        return dictionary![key]
      } else {
        return nil
      }
    } else {
      return nil
    }
  }

  func has(key: String) -> Bool {
    if dictionary != nil {
      return dictionary!.keys.contains(key)
    } else {
      return false
    }
  }

  func add(key: String, value: Any) -> MeetingModelBuilder {
    if dictionary != nil {
      dictionary![key] = value
      return self
    } else {
      return start().add(key: key, value: value)
    }
  }
  func remove(key: String, value: Any) -> MeetingModelBuilder {
    if dictionary != nil, dictionary![key] != nil {
      dictionary!.removeValue(forKey: key)
      return self
    } else {
      return self
    }
  }
  func generateMeeting() -> MeetingModelBuilder {
    if dictionary != nil {
      var meetingDict: [String: Any] = [
        "meeting_name": retrieve(forKey: "meeting_name") as? String ?? ""
      ]

      if let meetinglocation = retrieve(forKey: "meeting_location") as? String, let rlocation = RLocation(JSONString: meetinglocation) {
        meetingDict["meeting_location"] = rlocation.toJSON()
      }

      if let startdate = retrieve(forKey: "start_date") as? Date, let enddate = retrieve(forKey: "end_date") as? Date, let dateclass = MeetingDateClass(JSON: [
          "start_date": startdate.toString(),
          "end_date": enddate.toString()
        ]) {
        meetingDict["meeting_date"] = dateclass.toJSON()
      }
      meeting = Meeting(JSON: meetingDict)
      return self
    } else {
      return self
    }
  }
}

private var meetingTime = [MeetingTimeLength]()

class MessagesViewController: FormMessagesAppViewController {

  @IBOutlet private weak var sendToFriendsButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  private var isStartCalendarShowing: Bool = false
  private var isEndCalendarShowing: Bool = false

  private var eventKitManager = EventKitManager()
  private var coreDataManager = CoreDataManager()
  private var invitesManager = MyInvitesManager()
  private let eventStore = EKEventStore()

  // Model
  private var meetingBuilder = MeetingModelBuilder().start()
  private var startDate: Date?
  private var eventLength: MeetingTimeLength?
  private var endDate: Date?

  var invites: [NSManagedObject] = []

  private var startDatePicker = WWCalendarTimeSelector.instantiate()
  private var endDatePicker = WWCalendarTimeSelector.instantiate()

  private var searchCompleter = MKLocalSearchCompleter()
  private var searchResults = [MKLocalSearchCompletionWrapper]()

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    setupSendToFriendsButton()

    startDatePicker.delegate = self
    startDatePicker.optionIdentifier = "start_date"
    startDatePicker.optionCurrentDate = Date()
    startDatePicker.optionShowTopPanel = false
    startDatePicker.optionTimeStep = .fifteenMinutes

    // Load meeting times in array
    for meeting in meetingTimeLength {
      guard let meetingtimelength = MeetingTimeLength(JSON: meeting) else { return }
      meetingTime.append(meetingtimelength)
    }

    form
      +++ Section("Create Invite")

      +++ Section("What?")
      <<< TextRow() {
        $0.tag = "meeting_name"
        $0.title = "Title of Event"
        let ruleRequiredViaClosure = RuleClosure<String> { rowValue in
          return (rowValue == nil || rowValue!.isEmpty) ? ValidationError(msg: "Field required!") : nil
        }
        $0.add(rule: ruleRequiredViaClosure)
        $0.validationOptions = .validatesOnChange
        }.cellUpdate { cell, row in
          if !row.isValid {
            cell.titleLabel?.textColor = .red
          } else {
            guard let value = row.value else { return }
            // Set the name of the meeting
            self.meetingBuilder = self.meetingBuilder.add(key: "meeting_name", value: value)
          }
        }

      +++ Section("Where?")
      <<< LabelRow() {
        $0.tag = "event_label"
        $0.hidden = .function(["meeting_location"], { form -> Bool in
          if let row = form.rowBy(tag: "meeting_location") as? LocationSearchRow {
            if let labelRow = form.rowBy(tag: "event_label") as? LabelRow {
              labelRow.title = row.value?.suggestionString ?? ""
              labelRow.updateCell()
            }
//            row.title = "Choose a new location for event"
//            row.updateCell()
            return row.value == nil
          } else {
            return true
          }
        })
      }
      <<< LocationSearchRow() {
        $0.tag = "meeting_location"
        $0.title = "Choose location for event"
        }.onChange { row in
          if let rLocation = row.value?.rLocation {
            guard let value = rLocation.toJSONString() else { return }

            // Set the location
            self.meetingBuilder = self.meetingBuilder.add(key: "meeting_location", value: value)
          }
      }

      +++ Section("When?")
      <<< ButtonRow() {
        $0.tag = "start_date"
        $0.title = "Start Time"
        }.cellUpdate { cell, row in
          cell.textLabel?.textAlignment = .left
          cell.textLabel?.textColor = .darkText
        }.onCellSelection { [weak self] (cell, row) in
          if self != nil {
            self!.present(self!.startDatePicker, animated: true, completion: nil)
          }
      }

      <<< PushRow<String>() {
        $0.tag = "end_date"
        $0.title = "Event Length"
        $0.disabled = .function(["start_date"], { form -> Bool in
          if let row = form.rowBy(tag: "start_date") as? ButtonRow {
            return row.value == nil
          } else {
            return true
          }
        })
        $0.options = meetingTime.map({ (meetingtime) -> String in
          return meetingtime.name ?? ""
        })
        $0.value = meetingTime[1].name ?? ""
        }.onPresent { from, to in
          to.dismissOnSelection = true
          to.dismissOnChange = true
          to.sectionKeyForValue = { option in
            switch option {
            default: return ""
            }
          }
        }.onChange { row in

          row.updateCell()

          guard let startdate = self.meetingBuilder.retrieve(forKey: "start_date") as? Date, let pushRowValue = row.value else {
            return
          }
          switch pushRowValue.lowercased() {
          case "custom":
            self.endDatePicker.delegate = self
            self.endDatePicker.optionIdentifier = "end_date"
            self.endDatePicker.optionCurrentDate = startdate
            self.endDatePicker.optionShowTopPanel = false
            self.endDatePicker.optionTimeStep = .fifteenMinutes
            self.present(self.endDatePicker, animated: true, completion: nil)
          default:
            guard let meetingtime = meetingTime.first(where: { (meetingTime) -> Bool in
              return meetingTime.name ?? "" == pushRowValue
            }) else {
              guard let value = startdate.add(minutes: 60) else {
                return
              }
              self.meetingBuilder = self.meetingBuilder.add(key: "end_date", value: value)
              return
            }
            self.eventLength = meetingtime
            return
          }
        }
    animateScroll = true
    rowKeyboardSpacing = 20

  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.setNavigationBarHidden(true, animated: animated)

    view.bringSubviewToFront(actionsContainerView)
    
    eventKitManager.getCalendarPermissions { (success) in
      if success {
        self.sendToFriendsButton.isEnabled = true
      } else {
        self.sendToFriendsButton.isEnabled = false
        self.showError(title: kCalendarPermissions, message: kCalendarAccess)
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  // MARK: - Private methods
  private func setupSendToFriendsButton() {
    sendToFriendsButton.applyCornerRadius()
    sendToFriendsButton.spinnerColor = UIColor.gradientColor2
  }

  private func sendToFriendsAction() {
    sendToFriendsButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {

      // Check if start time exists
      if let eventlength = self.eventLength?.length, let startdate = self.meetingBuilder.retrieve(forKey: "start_date") as? Date {
        guard let value = startdate.add(minutes: eventlength) else { return }
        self.meetingBuilder = self.meetingBuilder.add(key: "end_date", value: value)
      }

      if self.eventLength == nil, let startdate = self.meetingBuilder.retrieve(forKey: "start_date") as? Date {
        // Default selection to 1 hour
        guard let value = startdate.add(minutes: 60) else { return }
        self.meetingBuilder = self.meetingBuilder.add(key: "end_date", value: value)
      }

      guard let _ = self.meetingBuilder.retrieve(forKey: "meeting_name") as? String,
        let _ = self.meetingBuilder.retrieve(forKey: "start_date") as? Date,
        let _ = self.meetingBuilder.retrieve(forKey: "end_date") as? Date,
        let meeting = self.meetingBuilder.generateMeeting().meeting else {

        self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

          self.showError(title: "Incomplete Form", message: "Please fill out the entire form to create an invite.")
        })

        return
      }

      self.insert(meeting: meeting)
    })
  }

  private func insert(meeting: Meeting) {
    // Try to convert meeting object into MSMessage object
    guard let message = DataConverter.Meetings.meetingToMessage(meeting) else {
      self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

        self.showError(title: "Incomplete Form", message: "Please fill out the entire form to create an invite.")
      })
      return
    }
    // TODO: - Track the name, location, and length of an event

    // Send meeting object to event kit manager to save as event into calendar
    eventKitManager.insertMeeting(meeting: meeting) { (success, error) in
      if let err = error {
        // TODO: - Handle error
        self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

          self.showError(title: "Something went wrong", message: "Something went wrong. Please try again.\n\nError message: \(err.localizedDescription)")
        })
      } else {
        if success {

          BranchEvent.customEvent(withName: "event_added_apple_calendar")

          // If inserting meeting into calendar was successful we want to save invite into core data
          // Save invite to Core Data
          self.saveInviteToCoreData(meeting: meeting, message: message)

        } else {
          // If inserting meeting into calendar was unsuccessful we want to save invite into core data
          // TODO: - Handle success of false
          self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

            self.showError(title: "Something went wrong", message: "Something went wrong. Please try again.")
          })
        }
      }
    }
  }

  private func saveInviteToCoreData(meeting: Meeting, message: MSMessage) {
    invitesManager.save(meeting: meeting) { (success, error) in
      if let err = error {
        // TODO: - Handle error if meeting was not saved into core data
        self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

          self.showError(title: "Something went wrong", message: "Something went wrong. Please try again.\n\nError message: \(err.localizedDescription)")
        })
      } else {
        if success {

          let alert = UIAlertController(title: "Share Event", message: "Would you like to share event in current chat conversation?", preferredStyle: .alert)
          let share = UIAlertAction(title: "Yes", style: .default, handler: { action in

            // After saving invite into core data, send the message
            self.send(message: message, toConversation: ConversationManager.shared.conversation, { success in
              if success {

                BranchEvent.customEvent(withName: "event_shared_conversation")

                // If message was sent into the conversation dismiss the view
                self.dismiss(animated: true, completion: nil)
              } else {

                BranchEvent.customEvent(withName: "event_shared_conversation_failed")

                // TODO: - Handle error if message couldn't be sent
                self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

                  self.showError(title: "Something went wrong", message: "Something went wrong. Please try again.")
                })
              }
            })

          })
          let delete = UIAlertAction(title: "No", style: .destructive, handler: { action in
            self.dismiss(animated: true, completion: nil)
          })
          alert.addAction(share)
          alert.addAction(delete)
          self.present(alert, animated: true, completion: nil)

        } else {
          // If inserting meeting into calendar was unsuccessful we want to save invite into core data
          // TODO: - Handle success of false
          self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

            self.showError(title: "Something went wrong", message: "Something went wrong. Please try again.")
          })
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

        NotificationCenter.default.post(name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil, userInfo: [:])

        self.sendToFriendsButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
          completion(true)
        })
      }
    }
  }

  // MARK: - IBActions
  @IBAction func sendToFriends(_ sender: UIButton) {
    
    BranchEvent.customEvent(withName: "user_started_save")

    sendToFriendsAction()
  }

  @IBAction func cancelAction(_ sender: UIButton) {
    NotificationCenter.default.post(name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil, userInfo: [:])
    dismiss(animated: true, completion: nil)
  }
}

// MARK: -
extension MessagesViewController: WWCalendarTimeSelectorProtocol {
  func WWCalendarTimeSelectorDone(_ selector: WWCalendarTimeSelector, date: Date) {

    if selector.optionIdentifier ?? "" == "start_date" {

      let _ = self.meetingBuilder.add(key: "start_date", value: date)

      if let cell = form.rowBy(tag: "start_date") as? ButtonRow {
        cell.title = date.toString(.proper)
        cell.value = date.toString(.proper)
        cell.updateCell()
      }
    }

    if selector.optionIdentifier ?? "" == "end_date" {

      let _ = self.meetingBuilder.add(key: "end_date", value: date)

      if let cell = form.rowBy(tag: "end_date") as? PushRow<String> {
        cell.title = "Event ends on"
        cell.value = date.toString(.proper)
      }
    }
    self.navigationController?.popViewController(animated: true)
  }

  func WWCalendarTimeSelectorShouldSelectDate(_ selector: WWCalendarTimeSelector, date: Date) -> Bool {
    if selector.optionIdentifier ?? "" == "start_date" {
      if date.timeIntervalSinceNow.isLess(than: 0) {
        return false
      }

      if date.timeIntervalSince(Date().addingTimeInterval(60 * 60 * 24 * 7)).isLess(than: 0) {
        return true
      }
    }

    if selector.optionIdentifier ?? "" == "end_date" {

      guard let startdate = self.meetingBuilder.retrieve(forKey: "start_date") as? String else { return true }

      if date.timeIntervalSince(startdate.toDate(.proper)).isLess(than: 0) {
        return false
      }

      if date.timeIntervalSince(startdate.toDate(.proper).addingTimeInterval(60 * 60 * 24 * 7)).isLess(than: 0) {
        return true
      }
    }
    return false
  }
}
