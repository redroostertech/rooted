//
//  AppInitializer.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 1/29/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Firebase

public class AppInitializer {
  static var main = AppInitializer()

  public var defaultsManager = DefaultsManager.shared

  private init() {
    FirebaseApp.configure()
    print("Firebase was configured.")
  }

  func initialAppLoadSegue() -> String? {

    if let identifier = Bundle.main.bundleIdentifier, identifier.contains("MessagesExtension") {

      // Check if user is logged in go to Dashboard
      if let isLoggedIn = defaultsManager.retrieveBoolDefault(forKey: kAuthIsLoggedIn), isLoggedIn {
        return nil
      } else {
        return kGoToDashboardSegue
      }
    } else {
      // Check if user is logged in go to Dashboard
      if let isLoggedIn = defaultsManager.retrieveBoolDefault(forKey: kAuthIsLoggedIn), isLoggedIn {
        return kGoToDashboardSegue
      } else {
        return kGoToLoginSegue
      }
    }
  }
}
