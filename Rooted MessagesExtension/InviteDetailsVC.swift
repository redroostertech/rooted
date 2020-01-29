import UIKit
import Messages
import MapKit
import EventKit
import iMessageDataKit
import SSSpinnerButton
import CoreLocation

class InviteDetailsVC: MSMessagesAppViewController {

  @IBOutlet private var timeLabel: UILabel!
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var locationNameLabel: UILabel!
  @IBOutlet private var locationLabel: UILabel!
  @IBOutlet private var acceptInviteButton: SSSpinnerButton!

  private var eventKitManager = EventKitManager()

  var titleText: String?
  var startDate: Date?
  var endDate: Date?
  var rLocation: RLocation?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.applyPrimaryGradient()
    acceptInviteButton.layer.cornerRadius = acceptInviteButton.frame.height / 2
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadVC()
  }

    func loadVC() {
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

    @IBAction func acceptInvite(_ sender: UIButton) {
        accept()
    }

    @IBAction func declineInvite(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    func accept() {
        acceptInviteButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {
          guard let title = self.titleText, let startDate = self.startDate, let endDate = self.endDate else {

              self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
                self.showError(title: "Incomplete Form", message: "Please fill out the form")
              })
              return
          }
          self.insertEvent(title: title, endDate: endDate, startDate: startDate, location: self.rLocation)
      })
    }

  private func insertEvent(title: String, endDate: Date, startDate: Date, location: RLocation?) {
    self.eventKitManager.insertEvent(title: title, startDate: startDate, endDate: endDate, location: location, {
      (success, error) in
      if let _ = error {
        DispatchQueue.main.async {
          if self.presentationStyle == .expanded {
            self.requestPresentationStyle(.compact)
          }
        }

        // TODO: - Handle error
        self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail,backToDefaults: true, complete: {
            let alert = UIAlertController(title: "Error", message: "Something went wrong. Please try again.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        })
      } else {
        if success {
          self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
            self.dismiss(animated: true, completion: nil)
          })
        } else {
          self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail,backToDefaults: true, complete: {
            let alert = UIAlertController(title: "Error", message: "Something went wrong. Please try again.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
              alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
          })
        }
      }
    })
  }
}
