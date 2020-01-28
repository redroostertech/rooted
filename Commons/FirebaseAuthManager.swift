//
//  FirebaseAuthManager.swift
//  FirebaseStarterApp
//
//  Created by Florian Marcu on 2/23/19.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import FirebaseAuth
import UIKit

public typealias FirebaseAuthCompletion = (_ result: AuthDataResult?, _ error: Error?) -> ()
public typealias FirebasePhoneAuthCompletion = (_ verificationId: String?, _ error: Error?) -> ()

public class FirebaseAuthManager {

  static let shared = FirebaseAuthManager()

  private var auth = Auth.auth()
  private var phoneAuth = PhoneAuthProvider.provider()

  public func login(credential: AuthCredential, completion: @escaping FirebaseAuthCompletion) {
    auth.signIn(with: credential, completion: { (result, error) in
      completion(result, error)
    })
  }

  public func login(email: String, pass: String, completion: @escaping FirebaseAuthCompletion) {
    auth.signIn(withEmail: email, password: pass) { (result, error) in
      completion(result, error)
    }
  }

  public func login(phone: String, completion: @escaping FirebasePhoneAuthCompletion) {
    phoneAuth.verifyPhoneNumber(phone, uiDelegate: nil) { (verificationId, error) in
      completion(verificationId, error)
    }
  }

  public func verifyToken(token: String, code: String, completion: @escaping FirebaseAuthCompletion) {
    let credential = phoneAuth.credential(
      withVerificationID: token,
      verificationCode: code)
    auth.signIn(with: credential) { (result, error) in
      completion(result, error)
    }
  }

  public func createUser(email: String, password: String, completion: @escaping FirebaseAuthCompletion) {
    auth.createUser(withEmail: email, password: password) { (result, error) in
      completion(result, error)
    }
  }

  public func signOut(success: @escaping () -> Void, failure: ((NSError) -> Void)? = nil) {
    do {
      try auth.signOut()
      success()
    } catch let signOutError as NSError {
      failure?(signOutError)
    }
  }

  public func resetPassword(email: String, completion: @escaping (_ error: Error?) -> Void) {
    auth.sendPasswordReset(withEmail: email, completion: { (error) in
      completion(error)
    })
  }

  public func checkIfUserIsLoggedIn(success: @escaping () -> Void, failure: (() -> Void)? = nil) {
    auth.addStateDidChangeListener { auth, user in
      if let _ = user {
        // User is signed in
        success()
      } else {
        failure?()
      }
    }
  }
}
