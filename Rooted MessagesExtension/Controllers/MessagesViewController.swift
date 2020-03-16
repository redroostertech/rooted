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
import SwiftDate

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

class MessagesViewController: FormMessagesAppViewController {

  @IBOutlet private weak var sendToFriendsButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  private var isStartCalendarShowing: Bool = false
  private var isEndCalendarShowing: Bool = false

  private var contentManager = RootedContentManager(managerType: .send)
  private var conversationManager = ConversationManager.shared

  private var eventKitManager = EventKitManager()
  private var coreDataManager = CoreDataManager()
  private var invitesManager = MeetingsManager()
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

  // Computed Properties
  private var meetingTime: [MeetingTimeLength] {
    var meetingTimeArray = [MeetingTimeLength]()
    for meeting in meetingTimeLength {
      if let meetingtimelength = MeetingTimeLength(JSON: meeting) {
        meetingTimeArray.append(meetingtimelength)
      }
    }
    return meetingTimeArray
  }

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    setupSendToFriendsButton()

    startDatePicker.delegate = self
    startDatePicker.optionIdentifier = "start_date"
    startDatePicker.optionCurrentDate = Date()
    startDatePicker.optionShowTopPanel = false
    startDatePicker.optionTimeStep = .fifteenMinutes

    form
      +++ Section("Create Invite")

      +++ Section("What?")
      <<< TextRow() {
        $0.tag = "meeting_name"
        $0.title = "Event Name"
        let ruleRequiredViaClosure = RuleClosure<String> { rowValue in
          return (rowValue == nil || rowValue!.isEmpty) ? ValidationError(msg: "Field required!") : nil
        }
        $0.add(rule: ruleRequiredViaClosure)
        $0.validationOptions = .validatesOnChange
        }.cellUpdate { cell, row in
          if !row.isValid {
            cell.titleLabel?.textColor = .red
          } else {
            // TODO: - When working on drafting feature, use this to update draft
            guard let value = row.value else { return }
            // Set the name of the meeting
            self.meetingBuilder = self.meetingBuilder.add(key: "meeting_name", value: value)
          }
        }

      +++ Section(header: "Where?", footer: "Use this optional field to provide a location for your in-person event.")
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
        $0.title = "Set Address for In-Person Meeting"
        }.onChange { row in
          if let rLocation = row.value?.rLocation {
            guard let value = rLocation.toJSONString() else { return }

            // Set the location
            self.meetingBuilder = self.meetingBuilder.add(key: "meeting_location", value: value)
          }
      }

      +++ Section("Participants can join by")
      <<< PhoneRow() {
        $0.tag = "type_of_meeting_phone"
        $0.title = "Phone Call"
    }
      <<< URLRow() {
        $0.tag = "type_of_meeting_video"
        $0.title = "Web Conference (URL)"
      }

      +++ Section("When?")
      <<< ButtonRow() {
        $0.tag = "start_date"
        $0.title = "Start Date/Time"
        }.cellUpdate { cell, row in
          cell.textLabel?.textAlignment = .left
          cell.textLabel?.textColor = .darkText
        }.onCellSelection { [weak self] (cell, row) in
          if self != nil {
            self!.present(self!.startDatePicker, animated: true, completion: nil)
          }
      }
//      <<< SuggestionAccessoryRow<String> {
//        $0.tag = "time_zone"
//        $0.cell.customizeCollectionViewCell = {(cell) in
//          cell.label.backgroundColor = UIColor.gradientColor2
//          cell.label.numberOfLines = 2
//          cell.label.minimumScaleFactor = 0.8
//          cell.label.textColor = UIColor.white
//        }
//        $0.filterFunction = { [unowned self] text in
//          Zones.array.map( { $0.readableString } ).filter({ $0.lowercased().contains(text.lowercased()) })
//        }
//        $0.placeholder = "Event Time Zone"
//        }.onChange { row in
//          if let value = row.value {
//            guard let selection = Zones.array.first(where: { zones -> Bool in
//              return zones.readableString == value
//            }) else { return }
//
//            // Set the location
//            self.meetingBuilder = self.meetingBuilder.add(key: "time_zone", value: selection.rawValue)
//          }
//        }

      <<< PushRow<String>() {
        $0.tag = "end_date"
        $0.title = "Event Duration"
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
            guard let meetingtime = self.meetingTime.first(where: { (meetingTime) -> Bool in
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

      +++ Section(header:"Description", footer: "Use this optional field to provide a description of your event. The circled text in the screen shot below is the event description.")
      <<< TextAreaRow("meeting_description") {
        $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
    }

    animateScroll = true
    rowKeyboardSpacing = 20

    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillShowNotification), object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillHideNotification), object: nil)

  }

  override func keyboardWillShow(_ notification:Notification) {
    super.keyboardWillShow(notification)
  }
  override func keyboardWillHide(_ notification:Notification) {
    super.keyboardWillHide(notification)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.setNavigationBarHidden(true, animated: animated)

    view.bringSubviewToFront(actionsContainerView)

    contentManager.checkCalendarPermissions { (success) in
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

  private func sendResponse(meeting: Meeting, completion: @escaping (Bool, Error?) -> Void) {
    guard let message = MessageFactory.Meetings.meetingToMessage(meeting) else { return completion(false, RError.customError("Something went wrong while sending message. Please try again.").error) }
    self.conversationManager.send(message: message, of: .insert, completion)
  }

  private func sendToFriendsAction() {
    startAnimating(sendToFriendsButton) {

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

      // Check timeZone
      if self.meetingBuilder.retrieve(forKey: "time_zone") == nil {
        self.meetingBuilder = self.meetingBuilder.add(key: "time_zone", value: Zones.current.toTimezone().identifier)
      }

      // Check meeting type by phone
      var meetingTypeDict: [[String: Any]] = []
      if let meetingTypePhone = self.form.rowBy(tag: "type_of_meeting_phone") as? PhoneRow, let value = meetingTypePhone.value {
        let meetingType: [String: Any] = [
          "type_of_meeting": "type_of_meeting_phone",
          "meeting_meta": value
        ]
        meetingTypeDict.append(meetingType)
      }

      if let meetingTypeVideo = self.form.rowBy(tag: "type_of_meeting_video") as? URLRow, let value = meetingTypeVideo.value {
        let meetingType: [String: Any] = [
          "type_of_meeting": "type_of_meeting_video",
          "meeting_meta": value.absoluteString
        ]
        meetingTypeDict.append(meetingType)
      }

      self.meetingBuilder = self.meetingBuilder.add(key: "meeting_type", value: meetingTypeDict)

      if let meetingDescription = self.form.rowBy(tag: "meeting_description") as? TextAreaRow, let value = meetingDescription.value {
        self.meetingBuilder = self.meetingBuilder.add(key: "meeting_description", value: value)
      }

      guard let _ = self.meetingBuilder.retrieve(forKey: "meeting_name") as? String,
        let _ = self.meetingBuilder.retrieve(forKey: "start_date") as? Date,
        let _ = self.meetingBuilder.retrieve(forKey: "end_date") as? Date,
        let meeting = self.meetingBuilder.generateMeeting().meeting else {

          self.displayFailure(with: "Oops!", and: "Please fill out the entire form to create an invite.", afterAnimating: self.sendToFriendsButton)

        return
      }

      self.contentManager.insert(meeting, completion: { (success, error) in
        if let err = error {
          self.displayFailure(with: "Oops!", and: err.localizedDescription, afterAnimating: self.sendToFriendsButton)
        } else {
          if success {
            self.sendResponse(meeting: meeting, completion: { (success, e) in
              if let e = e {
                self.displayFailure(with: "Oops!", and: e.localizedDescription, afterAnimating: self.sendToFriendsButton)
              } else {
                self.displaySuccess(afterAnimating: self.sendToFriendsButton, completion: {
                  self.postNotification(withName: kNotificationMyInvitesReload, completion: {
                    self.dismiss(animated: true, completion: nil)
                  })
                })
              }
            })
          } else {
            self.displayFailure(with: "Oops!", and: "Something went wrong. Please try again.", afterAnimating: self.sendToFriendsButton)
          }
        }
      })
    }
  }

  // MARK: - IBActions
  @IBAction func sendToFriends(_ sender: UIButton) {
    BranchEvent.customEvent(withName: "user_started_save")
    sendToFriendsAction()
  }

  @IBAction func cancelAction(_ sender: UIButton) {
    postNotification(withName: kNotificationMyInvitesReload) {
      self.dismiss(animated: true, completion: nil)
    }
  }
}

// MARK: - WWCalendarTimeSelectorProtocol
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
      } else {
        self.showError(title: "Oops!", message: "At this time, creating meetings outside 7 days from today is not available.")
      }
    }

    if selector.optionIdentifier ?? "" == "end_date" {

      guard let startdate = (self.meetingBuilder.retrieve(forKey: "start_date") as? String)?.toDate()?.date else { return true }

      if date.timeIntervalSince(startdate).isLess(than: 0) {
        return false
      }

      if date.timeIntervalSince(startdate.addingTimeInterval(60 * 60 * 24 * 7)).isLess(than: 0) {
        return true
      }
    }
    return false
  }
}

