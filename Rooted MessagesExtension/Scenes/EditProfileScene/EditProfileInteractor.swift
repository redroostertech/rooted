//
//  EditProfileInteractor.swift
//  Rooted
//
//  Created by Michael Westbrooks on 7/31/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol EditProfileBusinessLogic {
  func forgotPassword(request: EditProfile.ForgotPassword.Request)
}

protocol EditProfileDataStore {
  //var name: String { get set }
}

class EditProfileInteractor: EditProfileBusinessLogic, EditProfileDataStore {

  var presenter: EditProfilePresentationLogic?
  var worker: EditProfileWorker?

  func forgotPassword(request: EditProfile.ForgotPassword.Request) {
    guard let email = request.email else {
      var error = EditProfile.HandleError.Response()
      error.errorMessage = "Please provide account credential"
      error.errorTitle = "Oops!"
      self.presenter?.handleError(response: error)
      return
    }
    let path = PathBuilder.build(.Test, in: .Auth, with: "leo")
    let params: [String: String] = [
      "action": "forgot_password",
      "email": email,
    ]
    let apiService = Api()
    apiService.performRequest(path: path,
                              method: .post,
                              parameters: params) { (results, error) in

                                guard error == nil else {
                                  RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                  var error = EditProfile.HandleError.Response()
                                  error.errorMessage = "Something went wrong. Please try again."
                                  error.errorTitle = "Oops!"
                                  self.presenter?.handleError(response: error)
                                  return
                                }

                                guard let resultsDict = results as? [String: Any] else {
                                  RRLogger.logError(message: "There was an error with the JSON.", owner: self, rError: .generalError)
                                  var error = EditProfile.HandleError.Response()
                                  error.errorMessage = "Something went wrong. Please try again."
                                  error.errorTitle = "Oops!"
                                  self.presenter?.handleError(response: error)
                                  return
                                }

                                RRLogger.log(message: "Data was returned\n\nResults Dict: \(resultsDict)", owner: self)

                                if let success = resultsDict["success"] as? Bool {
                                  if success {
                                    if let data = resultsDict["data"] as? [String: Any] {
                                      var response = EditProfile.ForgotPassword.Response()
                                      response.emailSent = data["email_sent"] as? Bool ?? false
                                      self.presenter?.onSuccessfulForgotPassword(response: response)
                                    } else {
                                      var error = EditProfile.HandleError.Response()
                                      error.errorMessage = "Something went wrong. Please try again."
                                      error.errorTitle = "Oops!"
                                      self.presenter?.handleError(response: error)
                                    }
                                  } else {
                                    var error = EditProfile.HandleError.Response()
                                    error.errorMessage = resultsDict["error_message"] as? String ?? "Something went wrong. Please try again."
                                    error.errorTitle = "Oops!"
                                    self.presenter?.handleError(response: error)
                                  }
                                }
    }
  }
}
