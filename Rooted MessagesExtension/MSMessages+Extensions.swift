import Messages

extension MSMessagesAppViewController {
    func showError(title: String, message: String, style: UIAlertController.Style = .alert, defaultButtonText defaultText: String = "OK") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let defaultAction = UIAlertAction(title: defaultText, style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }
}
