//
//  ConversationManager.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages

enum ConversationSendType {
  case send
  case insert
}

final class ConversationManager {
  static var shared = ConversationManager()

  // MARK: - Lifecycle methods
  private init() { }

  // MARK: - Use Case: App should keep track of the current conversation that is opened in the SMS app to extend the ability to insert a message throuhgout the app
  var conversation: MSConversation? {
    didSet {
      if let _ = self.conversation {
        RRLogger.log(message: "Active conversation has been stored in property", owner: self)
      } else {
        RRLogger.logError(message: "Active conversation is nil", owner: self, rError: .generalError)
      }
    }
  }

  // MARK: - Use Case: App should track the selection of a Rooted capable message to handle route functionality throuhgout the app
  var selectedMessage: MSMessage? {
    return self.conversation?.selectedMessage
  }

  // MARK: - Use Case: Setup the shared instance of the Conversation manager using the opened conversation
  static func setup(withConversation conversation: MSConversation) {
    ConversationManager.shared.conversation = conversation
  }

  // MARK: - Use Case: Update the conversation stored within the Conversation manager
  static func update(conversation: MSConversation) {
    ConversationManager.shared.conversation = conversation
  }

  // MARK: - Use Case: I want to be able to insert or send a message to the current conversation
  func send(message: MSMessage, of type: ConversationSendType, _ completion: @escaping (Bool, Error?) -> Void) {
    guard let convo = self.conversation else {
      NSLog("[ROOTED-IMESSAGE] EngagementFactory: Active conversation unavailable")
      return completion(false, RError.customError("Oops! Something went wrong. Please try again."))
    }
    switch type {
    case .insert:
      convo.insert(message) { error in
        if let err = error {
          completion(false, err)
        } else {
          completion(true, nil)
        }
      }
    case .send:
      convo.send(message) { error in
        if let err = error {
          completion(false, err)
        } else {
          completion(true, nil)
        }
      }
    }
  }
}
