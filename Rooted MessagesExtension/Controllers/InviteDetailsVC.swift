import UIKit
import Messages
import SSSpinnerButton
import Branch
import SwiftDate

enum ResponseType {
  case accept
  case decline
}

class InviteDetailsVC: FormMessagesAppViewController {

  @IBOutlet private weak var acceptInviteButton: SSSpinnerButton!
  @IBOutlet private weak var declineInviteButton: UIButton!
  @IBOutlet private weak var backButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  private var contentManager = RootedContentManager(managerType: .receive)
  private var conversationManager = ConversationManager.shared

  private var shouldSendRespone = false
  private var meeting: Meeting?

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

      +++ Section("Event Name")
      <<< LabelRow() {
        $0.tag = "meeting_name"
        if let meetingName = self.meeting?.meetingName {
          $0.title = meetingName
        }
      }

      +++ Section("Event Location")
      <<< ButtonRow() {
        $0.tag = "meeting_location"
        if let meetingLocation = meeting?.meetingLocation {
          $0.title = meetingLocation.readableWhereString
        } else {
          $0.title = "No location provided"
        }
      }

      +++ Section(header: "Event Start Date/Time", footer: "Time has been converted to your time zone for your convenience.")
      <<< LabelRow() {
        $0.tag = "meeting_date"
        if let meetingTime = meeting?.meetingDate {
          $0.title  = meetingTime.readableTime
        }
      }

    for meetingType in meeting?.meetingType ?? [MeetingType]() {
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
              var responder = self as UIResponder?
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

              let openSel = #selector(UIApplication.open(_:options:completionHandler:))
              while (responder != nil){
                if responder?.responds(to: openSel ) == true{
                  // cannot package up multiple args to openSel so we explicitly call it on the iMessage application instance
                  // found by iterating up the chain
                  (responder as? UIApplication)?.open(url, completionHandler:handler)  // perform(openSel, with: url)
                  return
                }
                responder = responder!.next
              }
            }
          }

          if rowTag == "type_of_meeting_video" {
            if let url = URL(string: "https://\(meetingType.meetingMeta ?? "")") {
              // technique that works rather than self.extensionContext.open
              var responder = self as UIResponder?
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

              let openSel = #selector(UIApplication.open(_:options:completionHandler:))
              while (responder != nil){
                if responder?.responds(to: openSel ) == true{
                  // cannot package up multiple args to openSel so we explicitly call it on the iMessage application instance
                  // found by iterating up the chain
                  (responder as? UIApplication)?.open(url, completionHandler:handler)  // perform(openSel, with: url)
                  return
                }
                responder = responder!.next
              }
            }

          }
        }
      }
    }

    self.form
      +++ Section("Event Description")
      <<< TextAreaRow("meeting_description") {
        $0.value = self.meeting?.meetingDescription ?? "No description provided."
        $0.textAreaMode = .readOnly
        $0.textAreaHeight = .fixed(cellHeight: 125)
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

  // MARK: - Private member methods
  private func sendResponse(_ type: ResponseType, to meeting: Meeting) {
    let sendResponseAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
      if self.shouldSendRespone {
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in

          var message: MSMessage!

          switch type {
          case .decline:
            message = MessageFactory.Meetings.Response.generateResponse(to: meeting, withText: "I'm sorry but I will have to decline this invite.")
          case .accept:
            message = MessageFactory.Meetings.Response.generateResponse(to: meeting, withText: "I am confirmed. See you soon!")
          }

          self.conversationManager.send(message: message, of: .insert, { (success, error) in
            self.displaySuccess(afterAnimating: self.acceptInviteButton, completion: {
              NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User \(type) the event.")
            })
          })
        })

        HUDFactory.displayAlert(with: "Send Response", message: "Use the close button to dismiss view and send invite response", and: [okAction], on: self)

      } else {
        self.dismiss(animated: true, completion: nil)
      }
    })

    let noAction = UIAlertAction(title: "No", style: .default, handler: { action in
      self.displaySuccess(afterAnimating: self.acceptInviteButton, completion: {
        NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User did not \(type) the event.")
      })
    })

    switch type {
    case .accept:
      HUDFactory.displayAlert(with: "Accept Event", message: "Are you sure you want to accept this event?", and: [sendResponseAction, noAction], on: self)
    case .decline:
      HUDFactory.displayAlert(with: "Decline Event", message: "Are you sure you want to decline this event?", and: [sendResponseAction, noAction], on: self)
    }
  }

  private func acceptInvite() {
    startAnimating(acceptInviteButton) {
      guard let mting = self.meeting else {
        return self.displayFailure(with: "Oops!", and: "There was an error adding event to your calendar. Please try again.", afterAnimating: self.acceptInviteButton)
      }
      self.insert(meeting: mting)
    }
  }

  private func declineInvite() {
    guard let mting = meeting else { return }
    sendResponse(.decline, to: mting)
  }

  private func insert(meeting: Meeting) {
    contentManager.insert(meeting) { (success, error) in
      if let err = error {
        self.displayFailure(with: "Oops!", and: err.localizedDescription, afterAnimating: self.acceptInviteButton)
      } else {
        if success {
          self.sendResponse(.accept, to: meeting)
        } else {
          self.displayFailure(with: "Oops!", and: "Something went wrong. Please try again.", afterAnimating: self.acceptInviteButton)
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
