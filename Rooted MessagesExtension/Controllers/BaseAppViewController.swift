//
//  BaseAppViewController.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages
import SSSpinnerButton

open class BaseAppViewController: MSMessagesAppViewController {
  var appInitializer = AppInitializer.main
  var activeConvo: MSConversation? {
    didSet {
      guard
        let activeconversation = self.activeConvo,
        let selectedmessage = activeconversation.selectedMessage else {
          self.activeConvo = activeConversation
          return RRLogger.logError(message: "Active conversation is nil", owner: self, rError: .generalError)
      }

      selectedMessage = selectedmessage
      RRLogger.log(message: "Active conversation has been stored in property", owner: self)
    }
  }

  var selectedMessage: MSMessage? {
    didSet {
      RRLogger.log(message: "Selected message has been stored in property", owner: self)
    }
  }

  func displayError(with title: String, and message: String) {
    HUDFactory.showError(with: title, and: message, on: self)
  }

  func stopAnimating(_ spinnerButton: SSSpinnerButton, for completionType: CompletionType, completion: @escaping () -> Void) {
    spinnerButton.stopAnimatingWithCompletionType(completionType: completionType, complete: completion)
  }

  func startAnimating(_ spinnerButton: SSSpinnerButton, completion: @escaping () -> Void) {
    spinnerButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: completion)
  }

  func displayFailure(with title: String, and message: String, afterAnimating spinnerButton: SSSpinnerButton) {
    stopAnimating(spinnerButton, for: .fail) {
      self.displayError(with: title, and: message)
    }
  }

  func displaySuccess(afterAnimating spinnerButton: SSSpinnerButton, completion: @escaping () -> Void) {
    stopAnimating(spinnerButton, for: .success, completion: completion)
  }

  func postNotification(withName name: String, andUserInfo userInfo: [String: Any]? = [:], completion: @escaping () -> Void) {
    NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: nil, userInfo: userInfo)
    completion()
  }
}

