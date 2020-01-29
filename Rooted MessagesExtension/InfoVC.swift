import UIKit
import Messages

class InfoVC: BaseAppViewController {
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var grantAccessButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.applyCornerRadius()
        closeButton.applyPrimaryGradient()
        grantAccessButton.applyCornerRadius()
        EventKitManager().getCalendarPermissions { (success) in
            if success {
                self.grantAccessButton.setTitle("ACCESS GRANTED", for: .normal)
                self.grantAccessButton.applyPrimaryGradient()
            } else {
                self.grantAccessButton.setTitleColor(.gradientColor1, for: .normal)
                self.grantAccessButton.setTitle("GRANT ACCESS NOW", for: .normal)
                self.grantAccessButton.backgroundColor = .white
            }
        }
    }
    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func grantAccessAction(_ sender: UIButton) {
        self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
    }
}
