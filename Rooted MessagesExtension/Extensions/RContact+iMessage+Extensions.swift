//
//  RContact+iMessage+Extensions.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 9/27/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation

extension RContact: TokenSearchable {
  public var displayString: String {
    return "\(self.givenName) \(self.familyName) - \(self.phoneNumber)"
  }

  public func contains(token: String) -> Bool {
    return self.familyName.lowercased().contains(token.lowercased()) || self.givenName.lowercased().contains(token.lowercased()) || self.company.lowercased().contains(token.lowercased())
  }

  public var id_fier: NSObject {
    return self as NSObject
  }
}
