import UIKit
import Messages

enum TimeSelectorType {
    case start
    case end
}

protocol TimeSelectorDelegate {
    func selectDate(_ selectorVC: TimeSelectorVC, selectedDate date: Date, selectorType type: TimeSelectorType)
}

class TimeSelectorVC: MSMessagesAppViewController {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateTimePicker: UIDatePicker!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var selectButton: UIButton!
    @IBOutlet var customSelectorView: UIView!

    var timeSelectorType: TimeSelectorType?
    var delegate: TimeSelectorDelegate?
    var proxyDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.applyPrimaryGradient()
        customSelectorView.layer.cornerRadius = customSelectorView.frame.height / 2
        selectButton.layer.cornerRadius = selectButton.frame.height / 2
        dateTimePicker.setValue(UIColor.white, forKey: "textColor")
        dateTimePicker.minimumDate = Date()
        dateTimePicker.setDate(Date(), animated: true)
        dateTimePicker.subviews.forEach { view in
            view.backgroundColor = UIColor.clear
            view.tintColor = UIColor.clear
            view.layer.borderColor = UIColor.clear.cgColor
            view.layer.borderWidth = 0.0
        }

        guard let type = timeSelectorType else {
            titleLabel.text = "Select Start Date"
            return
        }
        if type == .start {
            titleLabel.text = "Select Start Date"
        } else {
            titleLabel.text = "Select End Date"
            if let proxyDate = self.proxyDate {
                dateTimePicker.setDate(proxyDate, animated: true)
            }
        }
    }

    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func selectAction(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.delegate?.selectDate(self,
                                      selectedDate: self.dateTimePicker.date,
                                      selectorType: self.timeSelectorType ?? .start)
        }
    }
}
