import Messages

extension MSMessagesAppViewController {
    func showError(title: String, message: String, style: UIAlertController.Style = .alert, defaultButtonText defaultText: String = "OK", withCompletion completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let defaultAction = UIAlertAction(title: defaultText, style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: completion)
        })
        alert.addAction(defaultAction)
      DispatchQueue.main.async {
        self.present(alert, animated: true, completion: nil)
      }
    }
}
