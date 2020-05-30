//
//  SessionManager.swift
//  SpringBreakApp
//
//  Created by Michael Westbrooks on 2/21/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation

// MARK: - Use Case: As a user, I want to be keep track of my activity in a given session
class SessionManager {

  // MARK: - Public properties
  public static var shared = SessionManager()

  // MARK: - Lifecycle methods
  private init() { }

  // MARK: - Use Case: As a user, I want to be keep track of my activity in a given session; app should be able to check if a session already exists.
  var sessionExists: Bool {
    return currentUser != nil
//    return currentUserId != nil
  }

  // MARK: - Use Case: As a user, I want to be able to resume my activity and maintain a single reference to my user information; app needs to a ccess the `currentUser` thats stored in the `SessionManager`
  var currentUser: UserProfileData? {
    guard let userDict = DefaultsManager.shared.retrieveStringDefault(forKey: kSessionUser) else { return nil }
    return UserProfileData(JSONString: userDict)
  }

  var currentUserId: String? {
    guard let userid = DefaultsManager.shared.retrieveStringDefault(forKey: kSessionUserId) else { return nil }
    return userid
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to keep track of my activity
  var sessionStart: Date {
    return DefaultsManager.shared.retrieveStringDefault(forKey: kSessionStart)?.toDate()?.date ?? Date()
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to keep track of my activity; app needs to start a session using profile data
  static func start(with user: UserProfileData) {

    let defaultsManager = DefaultsManager.shared

    // Check if current user is nil
    if SessionManager.shared.currentUser == nil {

      // Start a new session with the provided user object
      if let userJsonString = user.toJSONString() {
        defaultsManager.setDefault(withData: userJsonString, forKey: kSessionUser)
      }

      // Capture the date that a new session was created
      let date = Date().toString()
      defaultsManager.setDefault(withData: date, forKey: kSessionStart)
      defaultsManager.setDefault(withData: date, forKey: kSessionLastLogin)

    } else {

      // Session already exists.
      // Do nothing regarding the session manager
      return

    }
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to keep track of my activity; app needs to start a session using profile data
  static func start(with id: String) {

    let defaultsManager = DefaultsManager.shared

    // Check if current user is nil
    if SessionManager.shared.currentUser == nil {

      // Start a new session with the provided user id
      defaultsManager.setDefault(withData: id, forKey: kSessionUserId)

      // Capture the date that a new session was created
      let date = Date().toString()
      defaultsManager.setDefault(withData: date, forKey: kSessionStart)
      defaultsManager.setDefault(withData: date, forKey: kSessionLastLogin)

    } else {

      // Session already exists.
      // Do nothing regarding the session manager
      return

    }
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to ensure that the time of boot up or "login" is updated to the current time
  static func updateLastLogin() {
    let date = Date().toString()
    DefaultsManager.shared.setDefault(withData: date, forKey: kSessionLastLogin)
  }

  // MARK: - Use Case: As a user, I want to be able to clear a session
  static func clearSession()  {
    let defaultsManager = DefaultsManager.shared
    defaultsManager.setNilDefault(forKey: kSessionUser)
    defaultsManager.setNilDefault(forKey: kSessionStart)
    defaultsManager.setNilDefault(forKey: kSessionLastLogin)
    defaultsManager.setNilDefault(forKey: kSessionCart)
  }
}
