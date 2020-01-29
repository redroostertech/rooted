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

  private init() {
    FirebaseApp.configure()
    print("Firebase was configured.")
  }
}
