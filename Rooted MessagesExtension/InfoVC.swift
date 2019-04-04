import UIKit

class InfoVC: UIViewController {
    @IBOutlet var closeButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = closeButton.frame.height / 2
        closeButton.applyPrimaryGradient()
    }
    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
