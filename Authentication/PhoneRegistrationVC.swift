//
//  PhoneRegistrationVC.swift
//  RootedCore
//
//  Created by Michael Westbrooks on 11/6/19.
//  Copyright © 2019 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class PhoneRegistrationVC: UIViewController {

  @IBOutlet weak var phoneNumberViewContainer: UIView!
  @IBOutlet weak var continueButton: UIButton!

  // TODO: - Uncomment this code when ready to implement PhoneNumber registration
//  var phoneView: PhoneNumberView!

  override func viewDidLoad() {
    super.viewDidLoad()
//    phoneView = PhoneNumberView(vc: self, button: continueButton)
//    phoneView.frame = phoneNumberViewContainer.bounds
//    phoneView.translatesAutoresizingMaskIntoConstraints = true
//    phoneNumberViewContainer.addSubview(phoneView)
  }

  @IBAction func continueAction(_ sender: UIButton) {
//    phoneView.validate { (completed, phoneNumber) in
//      if completed {
//        print("PhoneNumber is Valid")
//        let finalPhoneNumber = "+1"+phoneNumber
//        FirebaseAuthManager.shared.login(phone: finalPhoneNumber, completion: { (verificationId, error) in
//          if let err = error {
//            print("Erorr is \(err.localizedDescription)")
//          } else {
//            if let id = verificationId {
//              print("Verification \(id)")
//              let sb = UIStoryboard(name: "Main", bundle: nil)
//              guard let vc = sb.instantiateViewController(withIdentifier: "PhoneVerificationVC") as? PhoneVerificationVC else { return print("View does not exist") }
//              vc.verificationId = id
//              vc.phoneNumber = finalPhoneNumber
//              self.present(vc, animated: true, completion: nil)
//            } else {
//              print("Error registering with phone number.")
//            }
//          }
//        })
//      } else {
//        print("The phone number is not valid.")
//      }
//    }
  }

}
