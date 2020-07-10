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
    guard let userDict = KeychainManager.shared.retrieveStringDefault(forKey: kSessionUser) else { return nil }
    return UserProfileData(JSONString: userDict)
  }

  var currentUserId: String? {
    guard let userid = KeychainManager.shared.retrieveStringDefault(forKey: kSessionUserId) else { return nil }
    return userid
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to keep track of my activity
  var sessionStart: Date {
    return KeychainManager.shared.retrieveStringDefault(forKey: kSessionStart)?.toDate()?.date ?? Date()
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to keep track of my activity; app needs to start a session using profile data
  static func start(with user: UserProfileData) {

    let defaultsManager = KeychainManager.shared

    // Check if current user is nil
    if SessionManager.shared.currentUser == nil {

      // Start a new session with the provided user object
      if let userJsonString = user.toJSONString() {
        let _ = defaultsManager.setDefault(withData: userJsonString, forKey: kSessionUser)
      }

      // Capture the date that a new session was created
      let date = Date().toString()
      let _ = defaultsManager.setDefault(withData: date, forKey: kSessionStart)
      let _ = defaultsManager.setDefault(withData: date, forKey: kSessionLastLogin)

    } else {

      // Session already exists.
      // Do nothing regarding the session manager
      return

    }
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to keep track of my activity; app needs to start a session using profile data
  static func start(with id: String) {

    let defaultsManager = KeychainManager.shared

    // Check if current user is nil
    if SessionManager.shared.currentUser == nil {

      // Start a new session with the provided user id
      let _ = defaultsManager.setDefault(withData: id, forKey: kSessionUserId)

      // Capture the date that a new session was created
      let date = Date().toString()
      let _ = defaultsManager.setDefault(withData: date, forKey: kSessionStart)
      let _ = defaultsManager.setDefault(withData: date, forKey: kSessionLastLogin)

    } else {

      // Session already exists.
      // Do nothing regarding the session manager
      return

    }
  }

  // MARK: - Use Case: As a user, when I boot up my app, I want to ensure that the time of boot up or "login" is updated to the current time
  static func updateLastLogin() {
    let date = Date().toString()
    let _ = KeychainManager.shared.setDefault(withData: date, forKey: kSessionLastLogin)
  }

  // MARK: - Use Case: As a user, I want to be able to clear a session
  static func clearSession()  {
    let defaultsManager = KeychainManager.shared
    let _ = defaultsManager.deleteDefault(forKey: kSessionUserId)
    let _ = defaultsManager.deleteDefault(forKey: kSessionUser)
    let _ = defaultsManager.deleteDefault(forKey: kSessionStart)
    let _ = defaultsManager.deleteDefault(forKey: kSessionLastLogin)
    let _ = defaultsManager.deleteDefault(forKey: kSessionCart)
  }

  static func refreshSession() {
    guard let currentUser = SessionManager.shared.currentUser, let email = currentUser.email, let token = currentUser.token else {
      SessionManager.clearSession()
      return
    }
    let path = PathBuilder.build(.Test, in: .Auth, with: "leo")
    let params: [String: String] = [
      "action": "session_check",
      "email": email,
      "token": token
    ]
    let apiService = Api()
    apiService.performRequest(path: path,
                              method: .post,
                              parameters: params) { (results, error) in

                                guard error == nil else {
                                  RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                  SessionManager.clearSession()
                                  return
                                }

                                guard let resultsDict = results as? [String: Any] else {
                                  RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                  SessionManager.clearSession()
                                  return
                                }

                                RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                if let success = resultsDict["success"] as? Bool {
                                  if success {
                                    if let data = resultsDict["data"] as? [String: Any], let uid = data["uid"] as? String, let userDataDict = (data["user"] as? [[String: Any]])?.first, let userData = UserProfileData(JSON: userDataDict) {
                                      SessionManager.refresh(with: userData)
                                    } else {
                                      SessionManager.clearSession()
                                    }
                                  } else {
                                    SessionManager.clearSession()
                                  }
                                }
    }
  }

  static func refresh(with user: UserProfileData) {
    let defaultsManager = KeychainManager.shared
    // Start a new session with the provided user object
    if let userJsonString = user.toJSONString() {
      let _ = defaultsManager.setDefault(withData: userJsonString, forKey: kSessionUser)
    }
  }

  static func rememberMe(using email: String) {
    let defaultsManager = KeychainManager.shared
    let _ = defaultsManager.setDefault(withData: email, forKey: kSessionEmailAddress)
  }

  static var rememberMeEmail: String? {
    return KeychainManager.shared.retrieveStringDefault(forKey: kSessionEmailAddress)
  }

  static func doNotRememberMe() {
    let defaultsManager = KeychainManager.shared
    let didDelete = defaultsManager.deleteDefault(forKey: kSessionEmailAddress)
    print(didDelete)
  }

  static func isRememberMeOn() -> Bool {
    return KeychainManager.shared.retrieveStringDefault(forKey: kSessionEmailAddress) != nil
  }

}
