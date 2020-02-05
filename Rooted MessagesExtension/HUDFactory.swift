//
//  HUDFactory.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/4/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages

class HUDFactory {
  private init() { }
  static func showError(with title: String, and message: String?, on viewController: UIViewController) {
    guard let vc = viewController as? MSMessagesAppViewController else {
      HUDFactory.displayError(with: title, and: message, on: viewController)
      return
    }
    vc.showError(title: title, message: message ?? "")
  }

  static func displayError(with title: String, and message: String?, on vc: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
      alert.dismiss(animated: true, completion: nil)
    })
    alert.addAction(ok)
    vc.present(alert, animated: true, completion: nil)
  }

  static func displayAlert(with title: String, message: String, and actions: [UIAlertAction], on vc: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    for action in actions {
      alert.addAction(action)
    }
    vc.present(alert, animated: true, completion: nil)

  }
}
