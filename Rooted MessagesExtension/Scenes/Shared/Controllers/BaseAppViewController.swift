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
  var progressHUD: RProgressHUD?

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

  open override func viewDidLoad() {
    super.viewDidLoad()
    progressHUD = RProgressHUD(on: self.view)
  }

  func displayError(with title: String, and message: String, withCompletion completion: (()->Void)? = nil) {
    HUDFactory.showError(with: title, and: message, on: self, withCompletion: completion)
  }

  func stopAnimating(_ spinnerButton: SSSpinnerButton, for completionType: CompletionType, completion: @escaping () -> Void) {
    spinnerButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: completionType, backToDefaults: true, complete: completion)
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

  // MARK: - Use Case: Log activity from presentation style
  func log(presentationStyle: MSMessagesAppPresentationStyle) {
    switch presentationStyle {
    case .compact:
      RRLogger.log(message: "Presentation is transitioning to compact", owner: self)
    case .expanded:
      RRLogger.log(message: "Presentation is transitioning to expanded", owner: self)
    case .transcript:
      RRLogger.log(message: "Presentation is transitioning to transcript", owner: self)
    }
  }

  // MARK: - Use Case: Dismiss the view
  @objc
  func dismissView() {
    postNotification(withName: kNotificationMyInvitesReload) {
      self.dismiss(animated: true, completion: nil)
    }
  }

  // MARK: - Use Case: Open a url
  func openInMessagingURL(urlString: String) {
    if let url = URL(string:urlString) {
      let context = NSExtensionContext()
      context.open(url, completionHandler: nil)
      var responder = self as UIResponder?

      while (responder != nil) {
        if responder?.responds(to: Selector("openURL:")) == true{
          responder?.perform(Selector("openURL:"), with: url)
        }
        responder = responder!.next
      }
    }
  }
}

