//
//  PhoneVerificationVC.swift
//  RootedCore
//
//  Created by Michael Westbrooks on 11/6/19.
//  Copyright © 2019 RedRooster Technologies Inc. All rights reserved.
//

import UIKit
import SwiftyCodeView

class PhoneVerificationVC: UIViewController {

  @IBOutlet weak var codeVerificationView: SwiftyCodeView!
  @IBOutlet weak var verifyButton: UIButton!
  @IBOutlet weak var resendCodeButton: UIButton!

  var verificationId: String?
  var phoneNumber: String?
  var code: String?

  override func viewDidLoad() {
    super.viewDidLoad()
    codeVerificationView.delegate = self
    let _ = codeVerificationView.becomeFirstResponder()
  }

  @IBAction func verifyButtonAction(_ sender: UIButton) {
    guard let id = verificationId, let code = self.code else { return }
    FirebaseAuthManager.shared.verifyToken(token: id, code: code) { (result, error) in
      if let err = error {
        print("Error is \(err.localizedDescription)")
      } else {
        if let res = result {
          print("User ID is \(res.user.uid)")
          FirebaseAuthManager.shared.signOut(success: {
            self.dismiss(animated: true, completion: nil)
          }, failure: { error in
            print("There was an error signing out \(error.localizedDescription)")
          })
        } else {
          print("There was an error verifying token")
        }
      }
    }
  }
  
  @IBAction func resendCodeButtonAction(_ sender: UIButton) {
    guard let phone = phoneNumber else { return }
    FirebaseAuthManager.shared.login(phone: phone, completion: { (verificationid, error) in
      if let err = error {
        print("Erorr is \(err.localizedDescription)")
      } else {
        if let id = verificationid {
          print("Verification \(id)")
          self.verificationId = id
        } else {
          print("Error registering with phone number.")
        }
      }
    })
  }
}

extension PhoneVerificationVC: SwiftyCodeViewDelegate {
  func codeView(sender: SwiftyCodeView, didFinishInput code: String) {
    print("Entered code: ", code)
    self.code = code
  }
}
