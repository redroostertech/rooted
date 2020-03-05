//
//  ConversationManager.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages

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
