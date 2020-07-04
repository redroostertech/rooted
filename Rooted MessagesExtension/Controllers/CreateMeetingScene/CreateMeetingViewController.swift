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

class CreateMeetingViewController: FormMessagesAppViewController, RootedContentDisplayLogic {

  // MARK: - IBOutlets
  @IBOutlet private weak var sendToFriendsButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  // MARK: - Private Properties
  private var interactor: RootedContentBusinessLogic?
  private var conversationManager = ConversationManager.shared
  private var isStartCalendarShowing: Bool = false
  private var isEndCalendarShowing: Bool = false

  // MARK: - Model
  private var meetingBuilder = MeetingModelBuilder().start()
  private var startDate: Date?
  private var eventLength: MeetingTimeLength?
  private var endDate: Date?
  private var selectedLocation: String?

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

  // MARK: - Lifecycle methods
  static func setupViewController(meetingDate: MeetingDateClass) -> CreateMeetingViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "MessagesViewController") as! CreateMeetingViewController
    viewController.startDate = meetingDate.startDate?.toDate()?.date
    viewController.endDate = meetingDate.endDate?.toDate()?.date
    return viewController
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    let viewController = self
    let interactor = RootedContentInteractor()
    let presenter = RootedContentPresenter()
    viewController.interactor = interactor
    interactor.presenter = presenter
    presenter.viewController = viewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    checkCalendarPermissions()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    DispatchQueue.main.async {
      self.navigationController?.setNavigationBarHidden(true, animated: animated)
      self.view.bringSubviewToFront(self.actionsContainerView)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    DispatchQueue.main.async {
      self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
  }

  override func keyboardWillShow(_ notification:Notification) {
    super.keyboardWillShow(notification)
  }
  override func keyboardWillHide(_ notification:Notification) {
    super.keyboardWillHide(notification)
  }

  // MARK: - Use Case: Setup the UI for the view
  private func setupUI() {
    setupSendToFriendsButton()

    startDatePicker.delegate = self
    startDatePicker.optionIdentifier = "start_date"
    startDatePicker.optionCurrentDate = Date()
    startDatePicker.optionShowTopPanel = false
    startDatePicker.optionTimeStep = .fifteenMinutes
    setupForm()

    animateScroll = true
    rowKeyboardSpacing = 20

    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillShowNotification), object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillHideNotification), object: nil)
   }

  private func setupSendToFriendsButton() {
    sendToFriendsButton.applyCornerRadius()
    sendToFriendsButton.spinnerColor = UIColor.gradientColor2
  }

  private func setupForm() {
    form
          +++ Section("Create Invite")
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
                if let labelRow = form.rowBy(tag: "event_label") as? LabelRow, let rowValue = row.value {
                  self.selectedLocation = rowValue.rLocation?.toJSONString() ?? ""
                  labelRow.title = rowValue.suggestionString 
                  labelRow.updateCell()
                }
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
              if let rLocation = row.value?.rLocation, let rLocationString = rLocation.toJSONString() {
                self.selectedLocation = rLocationString
              }
          }

          +++ Section("Participants can join by")
          <<< PhoneRow() {
            $0.tag = "type_of_meeting_phone"
            $0.title = "Phone Call"
        }
          <<< URLRow() {
            $0.tag = "type_of_meeting_video"
            $0.title = "*Web Conference (URL)"
            $0.disabled = true
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

      <<< PushRow<String>("availability_time_id") {
          $0.title = "*Provide available times for selection"
          $0.disabled = true
      }

          +++ Section(header:"Description", footer: "Use this optional field to provide a description of your event. The circled text in the screen shot below is the event description.")
          <<< TextAreaRow("meeting_description") {
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 75)
        }

      +++ MultivaluedSection(multivaluedOptions: [.Reorder, .Insert, .Delete],
      header: "Create Agenda") {

      $0.multivaluedOptions = [.Reorder, .Insert, .Delete]
      $0.tag = "agenda_items"
      $0.addButtonProvider = { section in
          return ButtonRow(){
              $0.title = "Add Item"
              }.cellUpdate { cell, row in
                  cell.textLabel?.textAlignment = .left
          }
      }
      $0.multivaluedRowToInsertAt = { index in
          return NameRow() {
              $0.placeholder = "Agenda Item"
          }
      }
      $0 <<< NameRow() {
          $0.placeholder = "Agenda Item"
      }
    }

    +++ Section(header:"Add-Ons", footer:"(*) Premium features")
      <<< SwitchRow("is_chat_enabled") {
        $0.title = "*Add chat collaboration to meeting"
        $0.disabled = true
    }

      <<< PushRow<String>("attached_project_id") {
          $0.title = "*Attach a project to meeting"
          $0.disabled = true
      }

      <<< PushRow<String>("onboarding_project_id") {
          $0.title = "*Attach a pre-screening form"
          $0.disabled = true
      }

    +++ Section()
  }

  // MARK: - Use Case: Start animating button
  private func startAnimatingButton(_ completion: (() -> Void)? = nil) {
    startAnimating(sendToFriendsButton) {
      completion?()
    }
  }

  // MARK: - Use Case: Stop animating button
  private func stopAnimatingButton(_ completion: (() -> Void)? = nil) {
    stopAnimating(sendToFriendsButton, for: .none) {
      completion?()
    }
  }

  // MARK: - IBActions
  // MARK: - Use Case: When a user taps on the `sendToFriendsButton` we want to first save the event to local storage, then add it to the calendar, and then send it to the conversation
  @IBAction func sendToFriends(_ sender: UIButton) {
    BranchEvent.customEvent(withName: "user_started_save")
    checkMaximumMeetingsReached()
  }

  private func generateMeetingFromInput() {
    startAnimatingButton()

    // Check if start time exists
    if let eventlength = eventLength?.length, let startdate = meetingBuilder.retrieve(forKey: "start_date") as? Date {
      guard let value = startdate.add(minutes: eventlength) else { return }
      self.meetingBuilder = self.meetingBuilder.add(key: "end_date", value: value)
    }

    if eventLength == nil, let startdate = meetingBuilder.retrieve(forKey: "start_date") as? Date {
      // Default selection to 1 hour
      guard let value = startdate.add(minutes: 60) else { return }
      self.meetingBuilder = self.meetingBuilder.add(key: "end_date", value: value)
    }

    // Check timeZone
    if meetingBuilder.retrieve(forKey: "time_zone") == nil {
      self.meetingBuilder = self.meetingBuilder.add(key: "time_zone", value: Zones.current.toTimezone().identifier)
    }

    // Check location
    if let selectedlocation = selectedLocation {
      self.meetingBuilder = self.meetingBuilder.add(key: "meeting_location", value: selectedlocation)
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

    meetingBuilder = meetingBuilder.add(key: "meeting_type", value: meetingTypeDict)

    if let meetingDescription = form.rowBy(tag: "meeting_description") as? TextAreaRow, let value = meetingDescription.value {
      self.meetingBuilder = self.meetingBuilder.add(key: "meeting_description", value: value)
    }

    // Check Agenda Items
    if let agendaItemsSection = self.form.sectionBy(tag: "agenda_items") as? MultivaluedSection {
      var agendaItems: [[String: Any]] = []
      var order = 0
      for agendaItemRow in agendaItemsSection.allRows {
        if let row = agendaItemRow as? NameRow, let value = row.value {
          let item: [String: Any] = [
            "item_name": value,
            "order": order
          ]
          agendaItems.append(item)
          order += 1
        }
      }

      if agendaItems.count > 0 {
        self.meetingBuilder = self.meetingBuilder.add(key: "agenda_items", value: agendaItems)
      }
    }

    if let meetingOwner = SessionManager.shared.currentUser?.uid {
      self.meetingBuilder = self.meetingBuilder.add(key: "owner_id", value: meetingOwner)
    }

    guard let _ = meetingBuilder.retrieve(forKey: "meeting_name") as? String,
      let _ = meetingBuilder.retrieve(forKey: "start_date") as? Date,
      let _ = meetingBuilder.retrieve(forKey: "end_date") as? Date,
      let meeting = meetingBuilder.generateMeeting().meeting else {

        self.displayFailure(with: "Oops!", and: "Please fill out the entire form to create an invite.", afterAnimating: self.sendToFriendsButton)

      return
    }
    addMeetingToCalendar(meeting: meeting)
  }

  // MARK: - Use Case: Add meeting to calendar
  func addMeetingToCalendar(meeting: Meeting) {
    var request = RootedContent.AddToCalendar.Request()
    request.meeting = meeting
    interactor?.addToCalendar(request: request)
  }

  func onSuccessfulCalendarAdd(viewModel: RootedContent.AddToCalendar.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    saveMeeting(meeting: meeting)
  }

  // MARK: - Use Case: Save meeting to datastore
  func saveMeeting(meeting: Meeting) {
    var request = RootedContent.SaveMeeting.Request()
    request.meeting = meeting
    request.branchEventID = kBranchMeetingStartedSave
    request.saveType = .send
    request.contentDB = .remote
    interactor?.saveMeeting(request: request)
  }

  func onSuccessfulSave(viewModel: RootedContent.SaveMeeting.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    sendResponse(to: meeting)
  }

  func handleError(viewModel: RootedContent.DisplayError.ViewModel) {
    displayFailure(with: viewModel.errorTitle, and: viewModel.errorMessage, afterAnimating: sendToFriendsButton)
  }

  // MARK: - Use Case: Send message containing meeting data to MSMessage
  func sendResponse(to meeting: Meeting) {
    guard let meetingname = meeting.meetingName, let startdate = meeting.meetingDate?.startDate?.toDate()?.date, let _ = meeting.meetingDate?.endDate?.toDate()?.date, let message = EngagementFactory.Meetings.meetingToMessage(meeting) else {
      return self.displayFailure(with: "Oops!", and: "Something went wrong while sending message. Please try again.", afterAnimating: self.sendToFriendsButton)
    }
    conversationManager.send(message: message, of: .insert) { (success, error) in
      if let err = error {
        self.displayFailure(with: "Oops!", and: err.localizedDescription, afterAnimating: self.sendToFriendsButton)
      } else {
        self.displaySuccess(afterAnimating: self.sendToFriendsButton, completion: {
          self.postNotification(withName: kNotificationMyInvitesReload, completion: {
            let pasteboard = UIPasteboard.general
            pasteboard.string = String(format: kCaptionString, arguments: [meetingname, startdate.toString(.rooted)])

            self.displayError(with: "Copied to Clipboard!", and: "Event invitation was copied to your clipboard.", withCompletion: {
              self.dismiss(animated: true, completion: nil)
            })
          })
        })
      }
    }
  }

  // MARK: - Use Case: Notify user that message was copied to clipboard

  @IBAction func cancelAction(_ sender: UIButton) {
    dismissView()
  }
}

// MARK: - WWCalendarTimeSelectorProtocol
extension CreateMeetingViewController: WWCalendarTimeSelectorProtocol {

  // MARK: - Use Case: User selects a date
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

  // MARK: - Use Case: User finishes selecting a date form the date picker
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
}

// Reusable components
extension CreateMeetingViewController {
  // MARK: - Use Case: Show ProgressHUD
  func showHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.show()
    }
  }

  // MARK: - Use Case: Dismiss ProgressHUD
  func dismissHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.dismiss()
    }
  }

  // MARK: - Use Case: Check if app has access to calendar permissions
  func checkCalendarPermissions() {
    let request = RootedContent.CheckCalendarPermissions.Request()
    interactor?.checkCalendarPermissions(request: request)
  }

  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) {
    RRLogger.log(message: "Calendar Permissions: \(viewModel.isGranted)", owner: self)
    if viewModel.isGranted {
      displayFailure(with: "Oops!", and: "Please try again.", afterAnimating: self.sendToFriendsButton)
    } else {
      self.showCalendarError()
    }
  }

  private func showCalendarError() {
    self.showError(title: kCalendarPermissions, message: kCalendarAccess)
    self.dismissView()
  }

  // MARK: - Use Case: As a business, we want to limit access to creating more than (n) meetings based on account type
  func checkMaximumMeetingsReached() {
    let request = RootedContent.CheckMaximumMeetingsReached.Request()
    interactor?.checkMaximumMeetingsReached(request: request)
  }

  func handleMaximumLimitReached(viewModel: RootedContent.CheckMaximumMeetingsReached.ViewModel) {
    if viewModel.isMaximumumReached {
      self.showError(title: viewModel.errorTitle, message: viewModel.errorMessage)
    } else {
      self.generateMeetingFromInput()
    }
  }
}
