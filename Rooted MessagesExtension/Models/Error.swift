//
//  File.swift
//  PopViewers
//
//  Created by Michael Westbrooks II on 5/13/18.
//  Copyright © 2018 MVPGurus. All rights reserved.
//

import Foundation

public enum RErrorDescription: String {
  case generalError = "There was an error"
  case invalidCredentials = "Invalid Credentials"
  case jsonResponseError = "There was an error converting the JSON response"
  case emptyAPIResponse = "No data was returned from the request."
  case signUpCredentialsError = "1 or more of your credentials is incorrect. Please check whether your passwords match, your email is a valid email address, or your username is greater than 3 characters."
  case signInCredentialsError = "1 or more of your credentials is incorrect. Please check if your email is a valid email address and both fields are not empty."
  case maximumSwipesReached = "You have reached the maximum numbebr of swipes today. Either upgrade for unlimited swipes or come back tomorrow."
  case noMoreUsersAvailable = "No more users in your area."
  case locationAccessDisabled = "Please provide access to your location to find users in your area. You can do this by going to your settings."
  case notificationAccessDisabled = "Please provide access to your notifications to receive immediate community updates."
}

public enum RError: Error {
  case generalError
  case customError(String)

  //  Add additional custom errors as needed
  //  ...

  public var localizedDescription: String {
    switch self {
    case .generalError:
      return NSLocalizedString(RErrorDescription.generalError.rawValue, comment: "General Error")
    case .customError(let value):
      return NSLocalizedString(value, comment: "Error")
    }
  }
}
