//
//  SessionManager.swift
//  SpringBreakApp
//
//  Created by Michael Westbrooks on 2/21/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation

public var kSessionUser = "currentUser"
public var kSessionStart = "sessionStart"
public var kSessionLastLogin = "lastLogin"
public var kSessionCart = "sessionCart" // Not in use yet

class SessionManager {
  static var shared = SessionManager()
  var sessionExists: Bool {
    return currentUser != nil
  }
  var currentUser: UserProfileData? {
    guard let userDict = DefaultsManager.shared.retrieveStringDefault(forKey: kSessionUser) else { return nil }
    return UserProfileData(JSONString: userDict)
  }
  var sessionStart: Date {
    return DefaultsManager.shared.retrieveStringDefault(forKey: kSessionStart)?.toDate()?.date ?? Date()
  }
  private init() { }

  static func start(with user: UserProfileData) {
    if SessionManager.shared.currentUser == nil {
      // If session is nil, start a new session with the provided user object
      if let userJsonString = user.toJSONString() {
        DefaultsManager.shared.setDefault(withData: userJsonString, forKey: kSessionUser)
      }
      let date = Date().toString()
      DefaultsManager.shared.setDefault(withData: date, forKey: kSessionStart)
      DefaultsManager.shared.setDefault(withData: date, forKey: kSessionLastLogin)
    } else {
      // If session is not nil, then session already exists.
      // Do nothing regarding the session manager
      return
    }
  }

  static func updateLastLogin() {
    let date = Date().toString()
    DefaultsManager.shared.setDefault(withData: date, forKey: kSessionLastLogin)
  }

  static func clearSession()  {
    DefaultsManager.shared.setNilDefault(forKey: kSessionUser)
    DefaultsManager.shared.setNilDefault(forKey: kSessionStart)
    DefaultsManager.shared.setNilDefault(forKey: kSessionLastLogin)
    DefaultsManager.shared.setNilDefault(forKey: kSessionCart)
  }
}
