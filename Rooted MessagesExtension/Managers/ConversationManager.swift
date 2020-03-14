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

  var conversation: MSConversation? {
    didSet {
      if let _ = self.conversation {
        RRLogger.log(message: "Active conversation has been stored in property", owner: self)
      } else {
        RRLogger.logError(message: "Active conversation is nil", owner: self, rError: .generalError)
      }
    }
  }

  var selectedMessage: MSMessage? {
    return self.conversation?.selectedMessage
  }

  private init() { }

  static func setup(withConversation conversation: MSConversation) {
    ConversationManager.shared.conversation = conversation
  }

  static func update(conversation: MSConversation) {
    ConversationManager.shared.conversation = conversation
  }

  func send(message: MSMessage, of type: ConversationSendType, _ completion: @escaping (Bool, Error?) -> Void) {
    guard let convo = self.conversation else {
      NSLog("[ROOTED-IMESSAGE] MessageFactory: Active conversation unavailable")
      return completion(false, RError.customError("Oops! Something went wrong. Please try again.").error)
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

final class NavigationCoordinator {
  static func performExpandedNavigation(from: BaseAppViewController, _ completion: @escaping () -> Void) {
    from.requestPresentationStyle(.expanded)
    completion()
  }

  static func performCompactNavigation(from: BaseAppViewController, _ completion: @escaping () -> Void) {
    from.requestPresentationStyle(.compact)
    completion()
  }
}
