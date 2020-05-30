//
//  PhoneLoginModels.swift
//  Rooted
//
//  Created by Michael Westbrooks on 5/16/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

enum PhoneLogin {

  enum LoginViaPhoneNumber {
    struct Request {
      var phoneNumber: String?
    }

    struct Response {
      var verificationCode: String?
    }

    struct ViewModel {
      var verificationCode: String?
    }
  }

  enum LoginViaEmailAndPassword {
    struct Request {
      var email: String?
      var password: String?
    }

    struct Response {
      var success: Bool?
      var userId: String?
      var userData: UserProfileData?
    }

    struct ViewModel {
      var success: Bool?
      var userId: String?
      var userData: UserProfileData?
    }
  }

  enum SetSession {
    struct Request {
      var userId: String?
      var userData: UserProfileData?
    }

    struct Response {
      var userId: String!
      var userData: UserProfileData?
    }

    struct ViewModel {
      var userId: String!
      var userData: UserProfileData?
    }
  }

  enum HandleError {
    struct Request { }

    struct Response {
      var error: Error?
      var errorTitle: String?
      var errorMessage: String?
    }

    struct ViewModel {
      var error: Error?
      var errorTitle: String?
      var errorMessage: String?
    }
  }
}
