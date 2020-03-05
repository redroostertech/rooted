//
//  BaseAppViewController.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages

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

}

