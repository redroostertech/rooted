import UIKit
import Messages
import SSSpinnerButton
import Branch
import SwiftDate
import OnboardKit

enum ResponseType {
  case accept
  case decline
}

class InviteDetailsViewController: FormMessagesAppViewController, RootedContentDisplayLogic, MeetingsManagerDelegate, AuthenticationLogic {

  // MARK: - IBOutlets
  @IBOutlet private weak var acceptInviteButton: SSSpinnerButton!
  @IBOutlet private weak var declineInviteButton: UIButton!
  @IBOutlet private weak var backButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  // MARK: - Private Properties
  private var interactor: RootedContentBusinessLogic?
  private var conversationManager = ConversationManager.shared
  private var shouldSendRespone = false
  private var meeting: RootedCellViewModel?

  // MARK: - Lifecycle methods
  static func setupViewController(meeting: RootedCellViewModel) -> InviteDetailsViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "InviteDetailsVC") as! InviteDetailsViewController
    viewController.meeting = meeting
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
    retrieveMeetingById()
  }

  // MARK: - Use Case: Setup the UI for the view
  private func setupUI() {
    backButton.applyCornerRadius()
    acceptInviteButton.applyCornerRadius()
    view.bringSubviewToFront(actionsContainerView)
  }

  private func loadFormWith(meeting: Meeting) {
    // Set up form
        form
          +++ Section("Event details")

          +++ Section("Event Name")
          <<< LabelRow() {
            $0.tag = "meeting_name"
            if let meetingName = meeting.meetingName {
              $0.title = meetingName
            }
          }

          +++ Section("Organized by")
          <<< LabelRow() {
            $0.tag = "meeting_owner"
            if let meetingOwner = meeting.owner?.first {
              $0.title = meetingOwner.fullName ?? ""
            }
          }

          +++ Section("Event Location")
          <<< ButtonRow() {
            $0.tag = "meeting_location"
            if let meetingLocation = meeting.meetingLocation {
              $0.title = meetingLocation.readableWhereString
            } else {
              $0.title = "No location provided"
            }
          }

          +++ Section(header: "Event Start Date/Time", footer: "Time has been converted to your time zone for your convenience.")
          <<< LabelRow() {
            $0.tag = "meeting_date"
            if let meetingTime = meeting.meetingDate {
              $0.title  = meetingTime.readableTime
            }
          }

        for meetingType in meeting.meetingType ?? [MeetingType]() {
          self.form
          +++ Section("Type of Event")
          <<< ButtonRow() {
            $0.tag = meetingType.typeOfMeeting ?? ""
            if meetingType.typeOfMeeting ?? "" == "type_of_meeting_phone" {
              $0.title = "Join by phone: \(meetingType.meetingMeta ?? "")"
            }

            if meetingType.typeOfMeeting ?? "" == "type_of_meeting_video" {
              $0.title = "Join by web conference: \(meetingType.meetingMeta ?? "")"
            }
          }.onCellSelection { cell, row in
            if let rowTag = row.tag {
              if rowTag == "type_of_meeting_phone" {
                if let url = URL(string: "tel://\(meetingType.meetingMeta ?? "")"){
                  // technique that works rather than self.extensionContext.open
//                  var responder = self as UIResponder?
                  /* old approach using openURL which has now been deprecated
                   if responder?.responds(to: #selector(UIApplication.openURL(_:))) == true{
                   responder?.perform(#selector(UIApplication.openURL(_:)), with: url)
                   */
                  let handler = { (success:Bool) -> () in
                    if success {
                      print("Finished opening URL")
                    } else {
                      print("Failed to open URL")
                    }
                  }

                  self.extensionContext?.open(url, completionHandler: handler)

    //              let openSel = #selector(UIApplication.open(_:options:completionHandler:))
    //              while (responder != nil){
    //                if responder?.responds(to: openSel ) == true{
    //                  // cannot package up multiple args to openSel so we explicitly call it on the iMessage application instance
    //                  // found by iterating up the chain
    //                  (responder as? UIApplication)?.open(url, completionHandler:handler)  // perform(openSel, with: url)
    //                  return
    //                }
    //                responder = responder!.next
    //              }
                }
              }

              if rowTag == "type_of_meeting_video" {
                if let url = URL(string: "zoomus://\(meetingType.meetingMeta ?? "")") {
                  // technique that works rather than self.extensionContext.open
//                  var responder = self as UIResponder?
                  /* old approach using openURL which has now been deprecated
                   if responder?.responds(to: #selector(UIApplication.openURL(_:))) == true{
                   responder?.perform(#selector(UIApplication.openURL(_:)), with: url)
                   */
                  let handler = { (success:Bool) -> () in
                    if success {
                      print("Finished opening URL")
                    } else {
                      print("Failed to open URL")
                    }
                  }

                  self.extensionContext?.open(url, completionHandler: handler)
    //              let openSel = #selector(UIApplication.open(_:options:completionHandler:))
    //              while (responder != nil){
    //                if responder?.responds(to: openSel ) == true{
    //                  // cannot package up multiple args to openSel so we explicitly call it on the iMessage application instance
    //                  // found by iterating up the chain
    //                  (responder as? UIApplication)?.open(url, completionHandler:handler)  // perform(openSel, with: url)
    //                  return
    //                }
    //                responder = responder!.next
    //              }
                }

              }
            }
          }
        }

        self.form
          +++ Section("Event Description")
          <<< TextAreaRow("meeting_description") {
            $0.value = meeting.meetingDescription ?? "No description provided."
            $0.textAreaMode = .readOnly
            $0.textAreaHeight = .fixed(cellHeight: 125)
        }

    if let meetingAgendaItems = meeting.agendaItems {
      var section = Section("Agenda Items")
      for agendaItem in meetingAgendaItems {
        if let agendaItemName = agendaItem.itemName {
          let row = LabelRow(agendaItemName, { labelRow in
            labelRow.title = agendaItemName
          })
          section += [row]
        }
      }

      // Append Rows into a Section
      self.form += [section]

    }

    if let currentUser = SessionManager.shared.currentUser, let meetingOwnerId = meeting.ownerId, meetingOwnerId == currentUser.uid  {
      // Handle functionality here
    } else {
      self.form
        +++ Section { section in
            section.header = {
              var header = HeaderFooterView<UIView>(.callback({
                  let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 32))
                  return view
              }))
              header.height = { 32 }
              return header
            }()

          section.footer = {
            var header = HeaderFooterView<UIView>(.callback({
                let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 75))
                return view
            }))
            header.height = { 75 }
            return header
          }()
        }
          <<< SwitchRow() {
            $0.tag = "sending_a_response"
            $0.title = "Send a response?"
            }.onChange { [weak self] row in
              guard let responseValue = row.value else { return }
              self?.shouldSendRespone = responseValue
      }
    }

    self.form
      +++ Section()

    animateScroll = true
    rowKeyboardSpacing = 20
  }

  // MARK: - Use Case: Retrieve meeting by ID from server
  func retrieveMeetingById() {
    showHUD()
    var request = RootedContent.RetrieveMeetingById.Request()
    request.meetingId = self.meeting?.data?.id
    request.meetingManagerDelegate = self
    request.contentDB = .remote
    interactor?.retrieveMeetingById(request: request)
  }

  func didFailToLoad(_ manager: Any?, error: Error) {
    dismissHUD()
    self.displayError(with: "Something went wrong!", and: "Event was either canceled or deleted. Please contact event organizer", withCompletion: {
      self.dismiss(animated: true, completion: nil)
    })
  }

  func didFinishLoading(_ manager: Any?, invites: [MeetingContextWrapper]) {
    // Do something here
  }

  func onDidFinishLoading(viewModel: RootedContent.RetrieveMeetings.ViewModel) {
    dismissHUD()
    guard let meeting = viewModel.meetings?.first?.meeting else {
      self.displayError(with: "Something went wrong!", and: "Event was either canceled or deleted. Please contact event organizer", withCompletion: {
        self.dismiss(animated: true, completion: nil)
      })
      return
    }
    loadFormWith(meeting: meeting)
  }

  // MARK: - Use Case: Check if app has access to calendar permissions
  func checkCalendarPermissions() {
    let request = RootedContent.CheckCalendarPermissions.Request()
    interactor?.checkCalendarPermissions(request: request)
  }

  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) {
    if viewModel.isGranted {
      // Show something here to show that access is granted
    } else {
      self.showCalendarError()
    }
  }

  private func showCalendarError() {
    self.showError(title: kCalendarPermissions, message: kCalendarAccess)
  }

  // MARK: - Use Case: Show success in animated button
  func animateButtonToSuccessForType(_ type: ResponseType) {
    animateButtonToSuccess {
      NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User \(type) the event.")
    }
  }

  func animateButtonToSuccess(_ completion: @escaping () -> Void) {
    displaySuccess(afterAnimating: acceptInviteButton, completion: completion)
  }

  // MARK: - IBActions
  // MARK: - Use Case: Accept the meeting, save it locally, and add it to your calendar
  @IBAction func acceptInvite(_ sender: UIButton) {
    acceptInvite()
  }

  private func acceptInvite() {
    startAnimating(acceptInviteButton) {
      guard let mting = self.meeting?.data else {
        return self.displayFailure(with: "Oops!", and: "There was an error adding event to your calendar. Please try again.", afterAnimating: self.acceptInviteButton)
      }
      self.addMeetingToCalendar(meeting: mting)
    }
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

  // MARK: - Use Case: Accept meeting and add user as a participant
  func acceptMeeting(meeting: Meeting) {
    var request = RootedContent.AcceptMeeting.Request()
    request.meeting = meeting
    request.branchEventID = kBranchInviteAccepted
    request.saveType = .receive
    request.contentDB = .remote
    interactor?.acceptMeeting(request: request)
  }

  func onSuccessfulAcceptance(viewModel: RootedContent.AcceptMeeting.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    sendResponse(.accept, to: meeting)
  }

  // MARK: - Use Case: Save meeting to datastore
  func saveMeeting(meeting: Meeting) {
    var request = RootedContent.SaveMeeting.Request()
    request.meeting = meeting
    request.branchEventID = kBranchInviteAccepted
    request.saveType = .receive
    request.contentDB = .remote
    interactor?.saveMeeting(request: request)
  }

  func onSuccessfulSave(viewModel: RootedContent.SaveMeeting.ViewModel) {
    guard let meeting = viewModel.meeting else { return }
    sendResponse(.accept, to: meeting)
  }

  func handleError(viewModel: RootedContent.DisplayError.ViewModel) {
    displayFailure(with: viewModel.errorTitle, and: viewModel.errorMessage, afterAnimating: acceptInviteButton)
  }

  // MARK: - Use Case: Send message containing meeting data to MSMessage
  func sendResponse(_ type: ResponseType, to meeting: Meeting) {
    let sendResponseAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
      if self.shouldSendRespone {
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in

          var message: MSMessage!

          switch type {
          case .decline:
            message = EngagementFactory.Meetings.Response.generateResponse(to: meeting, withText: "I'm sorry but I will have to decline this invite.")
          case .accept:
            message = EngagementFactory.Meetings.Response.generateResponse(to: meeting, withText: "I am confirmed. See you soon!")
          }

          self.conversationManager.send(message: message, of: .insert, { (success, error) in
            if let err = error {
              self.displayFailure(with: "Oops!", and: err.localizedDescription, afterAnimating: self.acceptInviteButton)
            } else {
              self.animateButtonToSuccessForType(type)
            }
          })
        })

        HUDFactory.displayAlert(with: "Send Response", message: "Use the close button to dismiss view and send invite response", and: [okAction], on: self)

      } else {
        self.dismissView()
      }
    })

    let noAction = UIAlertAction(title: "No", style: .default, handler: { action in
      self.animateButtonToSuccessForType(type)
    })

    switch type {
    case .accept:
      HUDFactory.displayAlert(with: "Accept Event", message: "Are you sure you want to accept this event?", and: [sendResponseAction, noAction], on: self)
    case .decline:
      HUDFactory.displayAlert(with: "Decline Event", message: "Are you sure you want to decline this event?", and: [sendResponseAction, noAction], on: self)
    }
  }

  // MARK: - Use Case: Decline the meeting
  @IBAction func declineInvite(_ sender: UIButton) {
    BranchEvent.customEvent(withName: "event_invite_declined")
    removeFromCalendar(meeting)
  }

  func removeFromCalendar(_ meeting: RootedCellViewModel?) {
    var request = RootedContent.RemoveFromCalendar.Request()
    request.meeting = meeting
    interactor?.removeMeetingFromCalendar(request: request)
  }

  func onSuccessfulCalendarRemoval(viewModel: RootedContent.RemoveFromCalendar.ViewModel) {
    print("Removed from calendar")
    declineMeeting(viewModel.meeting)
  }

  func deleteFromLocalStorage(meeting: RootedCellViewModel?) {
    var request = RootedContent.DeleteMeeting.Request()
    request.meetingManagerDelegate = self
    request.meeting = meeting
    self.interactor?.deleteMeeting(request: request)
  }

  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper) {
    print("Did delete invite")
    showError(title: "Meeting Deleted", message: "Meeting was successfully deleted.", style: .alert, defaultButtonText: "OK")
  }

  private func declineMeeting(_ meeting: RootedCellViewModel?) {
    guard let mting = meeting?.data else { return }
    sendResponse(.decline, to: mting)
  }

  // MARK: - Use Case: Accept the meeting, save it locally, and add it to your calendar
  @IBAction func back(_ sender: UIButton) {
    dismissView()
  }

  // MARK: - Not in use at the moment
  @IBAction func proposeNewTimeAction(_ sender: UIButton) {
    let sendResponseAction = UIAlertAction(title: "Yes", style: .default, handler: { action in

      /*
      let message = EngagementFactory.generateMessage(title: " \(self.startDate!.toString(.rooted)) does not work for me. Please select a new time.")

      EngagementFactory.send(message: message, to: self.activeConvo, of: .insert, { success in
        NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User is proposing a new time.")
      })
 */

    })

    let noAction = UIAlertAction(title: "No", style: .default, handler: { action in
      NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User opted out of sending a response")
    })
    HUDFactory.displayAlert(with: "Propose a New Time", message: "Would you like to propose a new time for the meeting?", and: [sendResponseAction, noAction], on: self)
  }

  // MARK: - Use Case: Check if user is logged in and if not, show login screen
  func presentPhoneLoginViewController() {
    dismissHUD()
    showError(title: "Login In", message: "You are not logged in. Please do so and try again.", style: .alert, defaultButtonText: "OK")
  }

  // MARK: - Use Case: On Successful login resume setting up the view controller
  func onSucessfulLogin(_ sender: PhoneLoginViewController, uid: String?) {
    sender.dismiss()
    retrieveMeetingById()
  }

  // MARK: - Use Case: On failed login attempt, resume setting up the view controller
  func handleFailedLogin(_ sender: PhoneLoginViewController, reason: String) {
    // Don't do anything yet
  }
}

// Reusable components
extension InviteDetailsViewController {
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
}
