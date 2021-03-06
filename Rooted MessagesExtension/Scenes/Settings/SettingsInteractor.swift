//
//  SettingsInteractor.swift
//  Rooted
//
//  Created by Michael Westbrooks on 5/23/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol SettingsBusinessLogic {
  func logoutUser(request: Settings.LogoutUser.Request)
}

protocol SettingsDataStore {
}

class SettingsInteractor: SettingsBusinessLogic, SettingsDataStore {
  var presenter: SettingsPresentationLogic?
  var worker: SettingsWorker?

  func logoutUser(request: Settings.LogoutUser.Request) {
    SessionManager.clearSession()
    let response = Settings.LogoutUser.Response()
    self.presenter?.onSuccessfullLogout(response: response)
  }
}
