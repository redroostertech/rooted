import UIKit
import Messages
import MapKit
import EventKit
import iMessageDataKit
import SSSpinnerButton
import CoreLocation

class InviteDetailsVC: BaseAppViewController {

  @IBOutlet private weak var timeLabel: UILabel!
  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var locationNameLabel: UILabel!
  @IBOutlet private weak var locationLabel: UILabel!
  @IBOutlet private weak var acceptInviteButton: SSSpinnerButton!
  @IBOutlet private weak var autoResponseSwitch: UISwitch!
  @IBOutlet private weak var proposeNewTimeButton: UIButton!
  @IBOutlet private weak var proposeNewTimeLabel: UILabel!
  @IBOutlet private weak var switchContainerView: UIView!

  private var eventKitManager = EventKitManager()
  private var shouldSendRespone = false

  var titleText: String?
  var startDate: Date?
  var endDate: Date?
  var rLocation: RLocation?
  var activeConvo: MSConversation?

  // MARK: - Lifecycle methods
  override func viewDidLoad() {
    super.viewDidLoad()
    // TODO: - There are a few dependencies; make hidden for now.
    proposeNewTimeLabel.isHidden = true
    proposeNewTimeButton.isHidden = true
    switchContainerView.applyPrimaryGradient()
    view.applyPrimaryGradient()
    acceptInviteButton.layer.cornerRadius = acceptInviteButton.frame.height / 2
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadVC()
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
  private func loadVC() {
    if let titleText = self.titleText {
      self.titleLabel.text = titleText
    }

    if let startDate = self.startDate {
      self.timeLabel.text = startDate.toString(CustomDateFormat.rooted)
    }

    if let endDate = self.endDate?.toString(CustomDateFormat.rooted) {
      self.timeLabel.text = timeLabel.text! + " to " +  endDate
    }

    if let selectedLocationName = self.rLocation?.name {
      self.locationNameLabel.text = selectedLocationName
    }

    if let selectedLocation = self.rLocation?.readableAddres {
      self.locationLabel.text = selectedLocation
    }
  }

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

      guard let title = self.titleText, let startDate = self.startDate, let endDate = self.endDate else {
        return self.stopAnimatingButtonAndDisplayError(with: "Incomplete Form", and: "Please fill out the form.")
      }

      // Insert invite into calendar
      self.insertEvent(title: title, endDate: endDate, startDate: startDate, location: self.rLocation)
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

  private func insertEvent(title: String, endDate: Date, startDate: Date, location: RLocation?) {
    self.eventKitManager.insertEvent(title: title, startDate: startDate, endDate: endDate, location: location, {
      (success, error) in
      if let _ = error {

        // TODO: - Handle error
        self.stopAnimatingButtonDisplayGenericError()

      } else {
        if success {

          if self.shouldSendRespone {

            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
              let message = MessageFactory.generateMessage(title: "I am confirmed. See you soon!")

              MessageFactory.send(message: message, to: self.activeConvo, of: .insert, { success in
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
    })
  }


  // MARK: - IBActions
  @IBAction func autoResponseSwitch(_ sender: UISwitch) {
    shouldSendRespone = sender.isOn
  }

  @IBAction func acceptInvite(_ sender: UIButton) {
    acceptInvite()
  }

  @IBAction func declineInvite(_ sender: UIButton) {
    declineInvite()
  }

  @IBAction func back(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func proposeNewTimeAction(_ sender: UIButton) {
    let sendResponseAction = UIAlertAction(title: "Yes", style: .default, handler: { action in

      let message = MessageFactory.generateMessage(title: " \(self.startDate!.toString(.rooted)) does not work for me. Please select a new time.")

      MessageFactory.send(message: message, to: self.activeConvo, of: .insert, { success in
        NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User is proposing a new time.")
      })

    })

    let noAction = UIAlertAction(title: "No", style: .default, handler: { action in
      NSLog("[ROOTED-IMESSAGE] InviteDetailsVC: User opted out of sending a response")
    })
    HUDFactory.displayAlert(with: "Propose a New Time", message: "Would you like to propose a new time for the meeting?", and: [sendResponseAction, noAction], on: self)
  }
}
