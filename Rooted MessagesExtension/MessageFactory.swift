//
//  MessageFactory.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/4/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages

enum ConversationSendType {
  case send
  case insert
}

class MessageFactory {
  private init() { }
  static func generateMessage(title: String) -> MSMessage {
    let message = MSMessage()
    let layout = MSMessageTemplateLayout()
    layout.caption = title
    message.layout = layout
    return message
  }

  static func send(message: MSMessage, to conversation: MSConversation?, of type: ConversationSendType, _ completion: @escaping (Bool) -> Void) {
    guard let convo = conversation else {
      NSLog("[ROOTED-IMESSAGE] MessageFactory: Active conversation unavailable")
      return completion(false)
    }
    switch type {
    case .insert:
      convo.insert(message) { error in
        if let _ = error {
          completion(false)
        } else {
          completion(true)
        }
      }
    case .send:
      convo.send(message) { error in
        if let _ = error {
          completion(false)
        } else {
          completion(true)
        }
      }
    }
  }
}
