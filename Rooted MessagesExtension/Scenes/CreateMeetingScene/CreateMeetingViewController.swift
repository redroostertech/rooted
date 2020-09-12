import UIKit
import Messages
import MessageUI
import EventKit
import iMessageDataKit
import MapKit
import SSSpinnerButton
import CoreLocation
import CoreData
import ObjectMapper
import Branch
import SwiftDate
import Contacts

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

class CreateMeetingViewController: FormMessagesAppViewController, RootedContentDisplayLogic, MeetingsManagerDelegate {

  // MARK: - IBOutlets
  @IBOutlet private weak var sendToFriendsButton: SSSpinnerButton!
  @IBOutlet private weak var createMeetingButton: UIButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  // MARK: - Private Properties
  private var interactor: RootedContentBusinessLogic?
  private var conversationManager = ConversationManager.shared
  private var contactsManager = ContactKitManager()
  private var isStartCalendarShowing: Bool = false
  private var isEndCalendarShowing: Bool = false

  // MARK: - Model
  private var meetingBuilder = MeetingModelBuilder().start()
  private var startDate: Date?
  private var eventLength: MeetingTimeLength?
  private var endDate: Date?
  private var selectedLocation: String?
  private var draftTimer: Timer?

  private var startDatePicker = WWCalendarTimeSelector.instantiate()
  private var endDatePicker = WWCalendarTimeSelector.instantiate()

  private var searchCompleter = MKLocalSearchCompleter()
  private var searchResults = [MKLocalSearchCompletionWrapper]()

  public var draftMeeting: RootedCellViewModel?
  private var invites: [NSManagedObject] = []

  private var isDeletingDraft = false

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

  private var contactsForInvite = [EPContact]() {
     didSet {
       if self.contactsForInvite.count > 0 {
         self.start()
       } else {
         if let invitePhoneRow = form.rowBy(tag: "meeting_invite_phone_numbers") as? TokenTableRow<EPContact> {
           invitePhoneRow.value = Set<EPContact>()
           invitePhoneRow.reload()
         }
       }
     }
   }

  // MARK: - Lifecycle methods
  static func setupViewController(meetingDate: MeetingDateClass) -> CreateMeetingViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "MessagesViewController") as! CreateMeetingViewController
    viewController.startDate = meetingDate.startDate?.toDate()?.date
    viewController.endDate = meetingDate.endDate?.toDate()?.date
    return viewController
  }

  static func setupViewController(draftMeeting: RootedCellViewModel?) -> CreateMeetingViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "MessagesViewController") as! CreateMeetingViewController
    viewController.draftMeeting = draftMeeting
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
      self.saveDraft()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    postNotification(withName: kNotificationMyInvitesReload, completion: {
      // Perform some work here
    })
  }

  override func keyboardWillShow(_ notification:Notification) {
    super.keyboardWillShow(notification)
  }
  override func keyboardWillHide(_ notification:Notification) {
    super.keyboardWillHide(notification)
  }

  // MARK: - Use Case: Setup the UI for the view
  private func setupUI() {
    setupCreateMeetingButton()
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

  private func setupCreateMeetingButton() {
    actionsContainerView.sendSubviewToBack(createMeetingButton)
    createMeetingButton.applyCornerRadius()
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
          }.cellSetup{ [weak self] (cell, row) in
            if let meetingName = self?.draftMeeting?.data?.meetingName {
              row.value = meetingName
            }
          }.cellUpdate { [weak self] cell, row in
              if !row.isValid {
                cell.titleLabel?.textColor = .red
              } else {
                // TODO: - When working on drafting feature, use this to update draft
                guard let value = row.value else { return }
                // Set the name of the meeting
                guard let meetingbuilder = self?.meetingBuilder.add(key: "meeting_name", value: value) else { return }
                self?.meetingBuilder = meetingbuilder
              }
            }

          +++ Section(header: "Where?", footer: "Use this optional field to provide a location for your in-person event.")
          <<< LabelRow() {
            $0.tag = "event_label"
            $0.title = "Location for Meeting"
            $0.titleColor = .lightGray
          }.cellSetup { [weak self] (cell, row) in
            if let meetingLocation = self?.draftMeeting?.data?.meetingLocation {
              row.title = meetingLocation.readableWhereString
            }
          }
          <<< LocationSearchRow() {
            $0.tag = "meeting_location"
            $0.title = "Search"
          }.cellSetup { [weak self] (cell, row) in
            if let meetingLocation = self?.draftMeeting?.data?.meetingLocation, let meetingLocationString = meetingLocation.toJSONString() {
              self?.selectedLocation = meetingLocationString
            }
          }.onChange { [weak self] row in
              if let rLocation = row.value?.rLocation, let rLocationString = rLocation.toJSONString() {
                self?.selectedLocation = rLocationString

                if let labelRow = self?.form.rowBy(tag: "event_label") as? LabelRow {
                  labelRow.title = rLocation.readableWhereString
                  labelRow.updateCell()
                }

                row.value = nil
                row.updateCell()
              }
          }
          <<< ButtonRow() {
            $0.tag = "remove_location_button"
            $0.title = "Remove Location"
            $0.disabled = .function(["meeting_location"], { form -> Bool in
              return self.selectedLocation == nil
            })
            }.cellSetup { [weak self] (cell, row) in
              if let meetingLocation = self?.draftMeeting?.data?.meetingLocation, let _ = meetingLocation.toJSONString() {
                row.disabled = false
              }
            }.cellUpdate { cell, row in
              cell.textLabel?.textAlignment = .center
              cell.textLabel?.textColor = .red
            }.onCellSelection { [weak self] (cell, row) in
              self?.selectedLocation = nil
              if let labelRow = self?.form.rowBy(tag: "event_label") as? LabelRow {
                labelRow.title = "Location for Meeting"
                labelRow.updateCell()
              }
              if let locationSearchRow = self?.form.rowBy(tag: "meeting_location") as? LocationSearchRow {
                locationSearchRow.value = nil
                locationSearchRow.updateCell()
              }
          }

          +++ Section("Participants can join by")
          <<< PhoneRow() {
            $0.tag = "type_of_meeting_phone"
            $0.title = "Phone Call"
          }.cellSetup { [weak self] (cell, row) in
            if
              let meetingType = self?.draftMeeting?.data?.meetingType?.first,
              let typeOfMeeting = meetingType.typeOfMeeting,
              typeOfMeeting == "type_of_meeting_phone",
              let meetingMeta = meetingType.meetingMeta {
              row.value = meetingMeta
            }
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
            }.cellSetup { [weak self] (cell, row) in
              if let meetingDateString = self?.draftMeeting?.data?.meetingDate?.dateString {
                row.value = meetingDateString
                row.title = meetingDateString
              }
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

      +++ Section(header:"Invite Attendees", footer:"Select any contact from your contacts")
      <<< ButtonRow() {
        $0.tag = "meeting_invite_phone_numbers_new"
        $0.title = "Select contacts from your contacts"
        }.cellUpdate { cell, row in
          cell.textLabel?.textAlignment = .left
          cell.textLabel?.textColor = .darkText
        }.onCellSelection { [weak self] (cell, row) in
          if self != nil {
            let contactPickerScene = EPContactsPicker(delegate: self, multiSelection: true, subtitleCellType: .phoneNumber)
            contactPickerScene.selectedContacts = self!.contactsForInvite
            let navigationController = UINavigationController(rootViewController: contactPickerScene)
            self!.present(navigationController, animated: true, completion: nil)
          }
      }
      <<< TokenTableRow<EPContact>() {
        $0.tag = "meeting_invite_phone_numbers"
        $0.placeholder = "selected contacts will show here"
        $0.cellSetup { (cell, row) in
          cell.disableTextField()
//          ContactKitManager().fetchContactsOnBackgroundThread(completionHandler: { result in
//
//            switch result {
//              case .Success(response: let contacts):
//                let rContacts = contacts.map { (contact) -> [RContact] in
//                  var multiPhoneContact = [RContact]()
//                  for phoneNumber in contact.phoneNumbers {
//                    if let phone = (phoneNumber.value).value(forKey: "digits") as? String {
//                      let contact = RContact(contact: contact, phoneNumber: phone)
//                      multiPhoneContact.append(contact)
//                    }
//                  }
//                  return multiPhoneContact
//                }.flatMap { $0 }
//                print(rContacts[0].familyName)
//                row.options.append(contentsOf: rContacts)
//              break
//              case .Error(error: let error):
//                print(error)
//              break
//            }
//          })
        }
      }

          +++ Section(header:"Description", footer: "Use this optional field to provide a description of your event. The circled text in the screen shot below is the event description.")
          <<< TextAreaRow("meeting_description") {
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 75)
        }.cellSetup { [weak self] (cell, row) in
          if let meetingDescription = self?.draftMeeting?.data?.meetingDescription {
            row.value = meetingDescription
          }
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
      <<< SwitchRow("is_meeting_public") {
        $0.tag = "is_meeting_public"
        $0.title = "Can anyone attend this meeting?"
        $0.value = true
      }

      <<< SwitchRow("is_invite_enabled_for_invitees"){
          $0.title = "Can invitees invite other people?"
          $0.hidden = .function(["is_meeting_public"], { form -> Bool in
              let row: RowOf<Bool>! = form.rowBy(tag: "is_meeting_public")
              return row.value ?? true == true
          })
      }

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

    if let meetingAgendaItems = draftMeeting?.data?.agendaItems, var section = form.sectionBy(tag: "agenda_items") as? MultivaluedSection {
      var count = 0
      for agendaItem in meetingAgendaItems {
        if let agendaItemName = agendaItem.itemName {
          let row = NameRow(agendaItemName, { labelRow in
            labelRow.value = agendaItemName
          })
          section.insert(row, at: count)
          count += 1
        }
      }
    }
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
    startAnimatingButton()
    BranchEvent.customEvent(withName: "user_started_save")
    checkMaximumMeetingsReached()
  }

  private func generateMeetingFromForm() -> Meeting? {
    // Check if start time exists
    if let eventlength = eventLength?.length {
      if let startdate = meetingBuilder.retrieve(forKey: "start_date") as? Date, let value = startdate.add(minutes: eventlength) {
        self.meetingBuilder = self.meetingBuilder.add(key: "end_date", value: value)
      }
    } else {
      if let startdate = meetingBuilder.retrieve(forKey: "start_date") as? Date, let value = startdate.add(minutes: 60) {
        self.meetingBuilder = self.meetingBuilder.add(key: "end_date", value: value)
      }
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

    // Check if invites exists
    if let meetingInvitePhoneNumbersRow = form.rowBy(tag: "meeting_invite_phone_numbers") as? TokenTableRow<EPContact>, let meetingInvitePhoneNumbers = meetingInvitePhoneNumbersRow.value {
      var meetingInvitePhoneNumbersArray = [[String: Any]]()
      for invitePhoneNumbers in meetingInvitePhoneNumbers {
        meetingInvitePhoneNumbersArray.append(invitePhoneNumbers.dictionaryRep)
      }
      self.meetingBuilder = self.meetingBuilder.add(key: "meeting_invite_phone_numbers", value: meetingInvitePhoneNumbersArray)
    }

    // Check if meeting is public
    if let isMeetingPublicRow = form.rowBy(tag: "is_meeting_public") as? SwitchRow, let isMeetingPublic = isMeetingPublicRow.value {
      self.meetingBuilder = self.meetingBuilder.add(key: "is_meeting_public", value: isMeetingPublic)
    }

    if let isMeetingPublicRow = form.rowBy(tag: "is_invite_enabled_for_invitees") as? SwitchRow, let isMeetingPublic = isMeetingPublicRow.value {
      self.meetingBuilder = self.meetingBuilder.add(key: "is_invite_enabled_for_invitees", value: isMeetingPublic)
    }

    guard let meeting = meetingBuilder.generateMeeting().meeting, let meetingName = meeting.meetingName, meetingName != "" else {
      return nil
    }
    return meeting
  }

  private func generateMeetingFromInput() {
    guard let meeting = generateMeetingFromForm(), let _ = meeting.meetingDate?.startDate, let _ = meeting.meetingDate?.endDate else {
      return self.displayFailure(with: "Oops!", and: "Please fill out the entire form to create an invite.", afterAnimating: self.sendToFriendsButton)
    }

    if let draftMeetingId = draftMeeting?.data?.id {
      meeting.id = draftMeetingId
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
    isDeletingDraft = true

    var request = RootedContent.SaveMeeting.Request()
    request.meeting = meeting
    request.branchEventID = kBranchMeetingStartedSave
    request.saveType = .send
    request.contentDB = .remote
    interactor?.saveMeeting(request: request)
  }

  func onSuccessfulSave(viewModel: RootedContent.SaveMeeting.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    switch viewModel.contentDB {
    case .remote:
      self.sendResponse(to: meeting)
    case .local:
      print("Saved to draft. Wait for delegate to pass back core data object")
    }
  }

  func handleError(viewModel: RootedContent.DisplayError.ViewModel) {
    displayFailure(with: viewModel.errorTitle, and: viewModel.errorMessage, afterAnimating: sendToFriendsButton)
    if let meeting = viewModel.meeting {
      removeFromCalendar(meeting)
    }
  }

  // MARK: - Use Case: Save event drafts
  func saveDraft() {
    guard let meeting = generateMeetingFromForm() else {
      RRLogger.log(message: "Couldn't create meeting to start a draft", owner: self)
      return
    }

    if let draftMeetingId = draftMeeting?.data?.id {
      meeting.id = draftMeetingId
    }

    guard isDeletingDraft == false else { return }
    var request = RootedContent.SaveMeetingDraft.Request()
    request.contentDB = .remote
    request.meeting = meeting
    request.saveType = .send
    request.meetingManagerDelegate = self
    interactor?.saveMeetingDraft(request: request)
  }

  func onSuccessfulDraftSave(viewModel: RootedContent.SaveMeetingDraft.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    switch viewModel.contentDB {
    case .remote:
      self.draftMeeting?.data = meeting
    case .local:
      print("Saved to draft. Wait for delegate to pass back core data object")
    }
  }

  // MARK: - Use Case: Remove meeting from users calendar
  private func removeFromCalendar(_ meeting: Meeting) {
    var request = RootedContent.RemoveFromCalendar.Request()
    request.meeting = meeting
    interactor?.removeMeetingFromCalendar(request: request)
  }

  // MARK: - Use Case: Send message containing meeting data to MSMessage
  func sendResponse(to meeting: Meeting) {
    guard let meetingid = meeting.id, let meetingname = meeting.meetingName, let startdate = meeting.meetingDate?.startDate?.toDate()?.date, let _ = meeting.meetingDate?.endDate?.toDate()?.date, let message = EngagementFactory.Meetings.meetingToMessage(meeting) else {
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

            let yesAction = UIAlertAction(title: "Share with Invitees via Group Chat", style: .default) { action in
              let messageComposeController = MFMessageComposeViewController()
              messageComposeController.messageComposeDelegate = self

              var recipients = [String]()
              for phone in meeting.meetingInvitePhoneNumbers! {
                recipients.append(phone.phone ?? "")
              }

              messageComposeController.recipients = recipients

              // tell messages to use the default message template layout
              let layout = MSMessageTemplateLayout()
              layout.caption = String(format: kCaptionStringWithUrl, arguments: [meetingname, startdate.toString(.rooted), PathBuilder.build(.Test, in: .Main, with: "/public/events/\(meetingid)")])

              // create a message and tell it the content and layout
              let message = MSMessage()
              message.layout = layout

              messageComposeController.message = message
              messageComposeController.body = String(format: kCaptionStringWithUrl, arguments: [meetingname, startdate.toString(.rooted), PathBuilder.build(.Custom(testBaseURL), in: .Main, with: "/public/events/\(meetingid)")])
              self.present(messageComposeController, animated: true, completion: nil)

            }

            let noAction = UIAlertAction(title: "Done", style: .default) {
              action in
              self.dismiss(animated: true, completion: nil)
            }

            HUDFactory.displayAlert(with: "Copied to Clipboard!", message: "Event invitation was copied to your clipboard. Want to share with invitees via Group Chat?", and: [yesAction, noAction], on: self)
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

// MARK: - MFMessageComposeViewControllerDelegate
extension CreateMeetingViewController: MFMessageComposeViewControllerDelegate {
  //  Primary delegate functions
  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
   switch result {
   case .cancelled:
     controller.dismiss(animated: true, completion: nil)
     self.dismissView()
   case .failed, .sent:
     controller.dismiss(animated: true, completion: nil)
     self.dismissView()
   }
  }
}

// MARK: - EPPickerDelegate
extension CreateMeetingViewController: EPPickerDelegate {
  func epContactPicker(_: EPContactsPicker, didContactFetchFailed error : NSError) { }

  func epContactPicker(_: EPContactsPicker, didCancel error : NSError) { }

  func epContactPicker(_: EPContactsPicker, didSelectContact contact : EPContact) {
    contactsForInvite.removeAll()
    contactsForInvite.append(contact)
  }

  func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts : [EPContact]) {
    contactsForInvite.removeAll()
    contactsForInvite = contacts
  }

  func start(at: Int = 0) {
    var atIndex = at
    guard atIndex < contactsForInvite.count else {
      return
    }
    let selectedContact = contactsForInvite[at]
    switch selectedContact.phoneNumbers.count {
    case let x where x == 1:
      selectedContact.selectedPhoneNumber = selectedContact.phoneNumbers[0]
      atIndex += 1
      if let invitePhoneRow = form.rowBy(tag: "meeting_invite_phone_numbers") as? TokenTableRow<EPContact> {
        invitePhoneRow.value = Set(contactsForInvite)
        invitePhoneRow.reload()
      }
      self.start(at: atIndex)
    case let x where x > 1:
      let alert = UIAlertController(title: "Select Phone Number for \(selectedContact.displayName())", message: "\(selectedContact.displayName()) has more than 1 phone number. Select the one you would like to send an invite to", preferredStyle: .actionSheet)
      for phoneNumber in selectedContact.phoneNumbers {
        let phoneAction = UIAlertAction(title: "Choose \(phoneNumber.phoneNumber)", style: .default) { action in
          selectedContact.selectedPhoneNumber = phoneNumber
          atIndex += 1

          if let invitePhoneRow = self.form.rowBy(tag: "meeting_invite_phone_numbers") as? TokenTableRow<EPContact> {
            invitePhoneRow.value = Set(self.contactsForInvite)
            invitePhoneRow.reload()
          }

          self.start(at: atIndex)
        }
        alert.addAction(phoneAction)
      }
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
        atIndex += 1
        self.start(at: atIndex)
        alert.dismiss(animated: true, completion: nil)
      }
      alert.addAction(cancelAction)
      self.present(alert, animated: true, completion: nil)
    default:
      break
    }
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

// MARK: - Reusable components
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
