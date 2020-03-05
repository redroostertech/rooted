import UIKit
import Messages
import MapKit
import EventKit
import iMessageDataKit
import SSSpinnerButton
import CoreLocation
import Branch

class InviteDetailsVC: FormMessagesAppViewController {

  @IBOutlet private weak var acceptInviteButton: SSSpinnerButton!
  @IBOutlet private weak var declineInviteButton: UIButton!
  @IBOutlet private weak var backButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  private var eventKitManager = EventKitManager()
  private var coreDataManager = CoreDataManager()
  private var invitesManager = MyInvitesManager()
  private let eventStore = EKEventStore()

  private var shouldSendRespone = false
  fileprivate var meeting: Meeting?

  // MARK: - Lifecycle methods
  static func setupViewController(meeting: Meeting) -> InviteDetailsVC {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "InviteDetailsVC") as! InviteDetailsVC
    viewController.meeting = meeting
    return viewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    backButton.applyCornerRadius()
    acceptInviteButton.applyCornerRadius()

    // Set up form
    form
      +++ Section("Event details")

      +++ Section("Title of Event")
      <<< LabelRow() {
        $0.tag = "meeting_name"
        if let meetingName = self.meeting?.meetingName {
          $0.title = meetingName
        }
      }

      +++ Section("Location of Event")
      <<< LabelRow() {
        $0.tag = "meeting_location"
        if let meetingLocation = meeting?.meetingLocation {
          $0.title = meetingLocation.readableWhereString
        } else {
          $0.title = "No location provided"
        }
      }

      +++ Section("Time of Event")
      <<< LabelRow() {
        $0.tag = "meeting_date"
        if let meetingTime = meeting?.meetingDate {
          $0.title  = meetingTime.readableTime
        }
    }

    if let currentUser = SessionManager.shared.currentUser, let meetingOwner = meeting?.owner, let meetingOwnerId = meetingOwner.id, meetingOwnerId == currentUser.id  {
      view.sendSubviewToBack(actionsContainerView)
    } else {
      view.bringSubviewToFront(actionsContainerView)
      self.form
        +++ Section()
          <<< SwitchRow() {
            $0.tag = "sending_a_response"
            $0.title = "Send a response?"
            }.onChange { [weak self] row in
              guard let responseValue = row.value else { return }
              self?.shouldSendRespone = responseValue
        }
    }

    animateScroll = true
    rowKeyboardSpacing = 20
  }

  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)
    DispatchQueue.main.async {
      if self.presentationStyle != .expanded {
        self.requestPresentationStyle(.expanded)
      }
    }
    activeConvo = conversation
  }

  override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
    super.didStartSending(message, conversation: conversation)
    activeConvo = conversation
  }

  // MARK: - Private member methods
  func displayError(with title: String, and message: String) {
    HUDFactory.showError(with: title, and: message, on: self)
  }

  private func stopAnimatingButtonAndDisplayError(with title: String, and message: String) {
    self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
      self.displayError(with: title, and: message)
    })
  }

  private func stopAnimatingButtonAndDisplaySuccess() {
    self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
      self.dismiss(animated: true, completion: nil)
    })
  }

  private func acceptInvite() {
    acceptInviteButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {


      guard let meeting = self.meeting else {
        return self.stopAnimatingButtonAndDisplayError(with: "Error", and: "There was an error adding event to your calendar. Please try again.")
      }

      // Insert invite into calendar
      self.insert(meeting: meeting)
    })
  }

  private func declineInvite() {
    let sendResponseAction = UIAlertAction(title: "Yes", style: .default, handler: { action in

      if self.shouldSendRespone {

        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
          let message = MessageFactory.generateMessage(title: "I'm sorry but I will have to decline this invite.")
          MessageFactory.send(message: message, to: self.activeConvo, of: .insert) { success in
            NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User declined the event.")
          }
        })
        HUDFactory.displayAlert(with: "Send Response", message: "Use the close button to dismiss view and send invite response", and: [okAction], on: self)

      } else {
        self.dismiss(animated: true, completion: nil)
      }
    })

    let noAction = UIAlertAction(title: "No", style: .default, handler: { action in
      NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User did not decline the event.")
    })

    HUDFactory.displayAlert(with: "Decline Event", message: "Are you sure you want to decline this event?", and: [sendResponseAction, noAction], on: self)
  }

  private func stopAnimatingButtonDisplayGenericError() {
    self.stopAnimatingButtonAndDisplayError(with: "Error", and: "Something went wrong. Please try again.")
  }

  private func insert(meeting: Meeting) {
    // Send meeting object to event kit manager to save as event into calendar
    eventKitManager.insertMeeting(meeting: meeting) { (success, error) in
      if let _ = error {

        // TODO: - Handle error
        self.stopAnimatingButtonDisplayGenericError()

      } else {
        if success {

          if self.shouldSendRespone {

            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
              let message = MessageFactory.generateMessage(title: "I am confirmed. See you soon!")

              MessageFactory.send(message: message,
                                  to: ConversationManager.shared.conversation,
                                  of: .insert, { success in
                if success {

                  self.stopAnimatingButtonAndDisplaySuccess()

                } else {

                  self.stopAnimatingButtonDisplayGenericError()

                }
              })
            })

            HUDFactory.displayAlert(with: "Send Response", message: "Use the close button to dismiss view and send invite response", and: [okAction], on: self)

          } else {
            self.stopAnimatingButtonAndDisplaySuccess()
          }
        }
      }
    }
  }

  // MARK: - IBActions
  @IBAction func acceptInvite(_ sender: UIButton) {

    BranchEvent.customEvent(withName: "event_invite_accepted")

    acceptInvite()
  }

  @IBAction func declineInvite(_ sender: UIButton) {

    BranchEvent.customEvent(withName: "event_invite_declined")

    declineInvite()
  }

  @IBAction func back(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func proposeNewTimeAction(_ sender: UIButton) {
    let sendResponseAction = UIAlertAction(title: "Yes", style: .default, handler: { action in

      /*
      let message = MessageFactory.generateMessage(title: " \(self.startDate!.toString(.rooted)) does not work for me. Please select a new time.")

      MessageFactory.send(message: message, to: self.activeConvo, of: .insert, { success in
        NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User is proposing a new time.")
      })
 */

    })

    let noAction = UIAlertAction(title: "No", style: .default, handler: { action in
      NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User opted out of sending a response")
    })
    HUDFactory.displayAlert(with: "Propose a New Time", message: "Would you like to propose a new time for the meeting?", and: [sendResponseAction, noAction], on: self)
  }
}
