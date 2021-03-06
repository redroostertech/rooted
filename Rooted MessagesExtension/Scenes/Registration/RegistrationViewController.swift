//
//  RegistrationViewController.swift
//  Rooted
//
//  Created by Michael Westbrooks on 5/18/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import FormTextField

protocol RegistrationDisplayLogic: class {
  func onSuccessfulRegistration(viewModel: Registration.RegisterViaEmailAndPassword.ViewModel)

  func onSuccessfulSessionSet(viewModel: Registration.SetSession.ViewModel)

  /// Handle any and all scenarios when something goes wrong
  func handleError(viewModel: Registration.HandleError.ViewModel)
}

class RegistrationViewController: FormMessagesAppViewController, RegistrationDisplayLogic {
 
  @IBOutlet var createAccountButton: UIButton!

  var interactor: RegistrationBusinessLogic?
  var router: (NSObjectProtocol & RegistrationRoutingLogic & RegistrationDataPassing)?

  // MARK: Object lifecycle
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  // MARK: Setup
  private func setup() {
    let viewController = self
    let interactor = RegistrationInteractor()
    let presenter = RegistrationPresenter()
    let router = RegistrationRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.viewController = viewController
    router.dataStore = interactor
  }
  
  // MARK: View lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    createAccountButton.applyCornerRadius()

    self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

    form +++ Section()
      <<< EmailRow(kFormEmailAddress) {
        $0.placeholder = kFormEmailPlaceholder
        $0.add(rule: RuleRequired())
        $0.add(rule: RuleEmail())
        $0.validationOptions = .validatesAlways

        if isDebug {
          $0.value = kDebugEmail
        }
      }.onCellSelection { (cell, row) in
        NavigationCoordinator.performExpandedNavigation(from: self) {
          // Animate view
        }
      }.cellUpdate { cell, row in
        NavigationCoordinator.performExpandedNavigation(from: self) {
          // Adjust view
          if !row.isValid {
            cell.textField.textColor = .systemRed
            self.createAccountButton.isEnabled = false
            self.createAccountButton.isUserInteractionEnabled = false
          } else {
            cell.textField.textColor = .black
            self.createAccountButton.isEnabled = true
            self.createAccountButton.isUserInteractionEnabled = true
          }
        }
      }

      <<< PasswordRow(kFormPassword) {
        $0.placeholder = kFormPasswordPlaceholder
        $0.add(rule: RuleRequired())
        $0.validationOptions = .validatesAlways

        if isDebug {
          $0.value = kDebugPassword
        }
      }.onCellSelection { (cell, row) in
        NavigationCoordinator.performExpandedNavigation(from: self) {
          // Animate view
        }
      }.cellUpdate { cell, row in
        NavigationCoordinator.performExpandedNavigation(from: self) {
          // Adjust view
          if !row.isValid {
            cell.textField.textColor = .systemRed
            self.createAccountButton.isEnabled = false
            self.createAccountButton.isUserInteractionEnabled = false
          } else {
            cell.textField.textColor = .black
            self.createAccountButton.isEnabled = true
            self.createAccountButton.isUserInteractionEnabled = true
          }
        }
      }

    <<< NameRow(kFormFullname) {
      $0.placeholder = kFormFullnamePlaceholder
      $0.add(rule: RuleRequired())
      $0.validationOptions = .validatesAlways

      if isDebug {
        $0.value = kDebugFullName
      }
    }.onCellSelection { (cell, row) in
      NavigationCoordinator.performExpandedNavigation(from: self) {
        // Animate view
      }
    }.cellUpdate { cell, row in
      NavigationCoordinator.performExpandedNavigation(from: self) {
        // Adjust view
        if !row.isValid {
          cell.textField.textColor = .systemRed
          self.createAccountButton.isEnabled = false
          self.createAccountButton.isUserInteractionEnabled = false
        } else {
          cell.textField.textColor = .black
          self.createAccountButton.isEnabled = true
          self.createAccountButton.isUserInteractionEnabled = true
        }
      }
    }

    <<< PickerInputRow<String>(kFormCountryCode) {
      $0.options = []
      do {
        if let file = Bundle.main.url(forResource: "CountryData", withExtension: "json") {
            let data = try Data(contentsOf: file)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let objects = json as? [[String: Any]] {
              // json is an array dictionary
              for object in objects {
                if let country = object["name"] as? String, let countryCallingCodes = object["countryCallingCodes"] as? [String], let callingCode = countryCallingCodes.first {
                  $0.options.append("\(country) - \(callingCode)")
                }
              }
            } else if let object = json as? [Any] {
              // json is an array
              print(object)
            } else {
              print("JSON is invalid")
            }
        } else {
          print("no file")
        }
      } catch {
        print(error.localizedDescription)
      }
      $0.value = "United States - +1"
    }

  <<< PhoneRow(kFormPhoneNumber) {
      $0.placeholder = kFormPhoneNumberPlaceholder
      $0.add(rule: RuleRequired())
      $0.validationOptions = .validatesAlways

      if isDebug {
        $0.value = kDebugPhone
      }

    }.onCellHighlightChanged { (cell, row) in
      NavigationCoordinator.performExpandedNavigation(from: self) {
        // Animate view
      }
    }.cellUpdate { cell, row in
      NavigationCoordinator.performExpandedNavigation(from: self) {
        // Adjust view
        if !row.isValid {
          cell.textField.textColor = .systemRed
          self.createAccountButton.isEnabled = false
          self.createAccountButton.isUserInteractionEnabled = false
        } else {
          cell.textField.textColor = .black
          self.createAccountButton.isEnabled = true
          self.createAccountButton.isUserInteractionEnabled = true
        }
      }
    }
  }

  @IBAction func registrationAction(_ sender: UIButton) {
    registerViaEmailAndPassword()
  }

  // MARK: - Use Case: When a user provides their email, full name, phone number and a password, try to create an account them in via Firebase
  func registerViaEmailAndPassword() {
    showHUD()
    var request = Registration.RegisterViaEmailAndPassword.Request()
    request.email = (form.rowBy(tag: kFormEmailAddress) as? EmailRow)?.value ?? ""
    request.password = (form.rowBy(tag: kFormPassword) as? PasswordRow)?.value ?? ""
    request.fullName = (form.rowBy(tag: kFormFullname) as? NameRow)?.value ?? ""
    request.phoneNumber = formatPhoneNumber()
    interactor?.registerViaEmailAndPassword(request: request)
  }

  private func formatPhoneNumber() -> String {
    var phoneNumber = ""
    if let countryCode = (form.rowBy(tag: kFormCountryCode) as? PickerInputRow<String>)?.value?.split(separator: "-")[1] {
      phoneNumber += countryCode
    }
    if let phone = (form.rowBy(tag: kFormPhoneNumber) as? PhoneRow)?.value {
      phoneNumber += phone
    }
    return phoneNumber
  }

  func onSuccessfulRegistration(viewModel: Registration.RegisterViaEmailAndPassword.ViewModel) {
    dismissHUD()
    startUserSession(with: viewModel.userId, and: viewModel.userData)
  }

  func startUserSession(with userId: String?, and userData: UserProfileData?) {
    var request = Registration.SetSession.Request()
    request.userId = userId
    request.userData = userData
    interactor?.startUserSession(request: request)
  }

  func onSuccessfulSessionSet(viewModel: Registration.SetSession.ViewModel) {
    let _ = SweetAlert().showAlert(on: self, title: "Thank You!", subTitle: "You are now logged in.", style: .success, buttonTitle: "Proceed", buttonColor: .systemOrange) { success in
      self.dismiss(animated: true, completion: {
//        self.router?.dataStore?.authenticationLogicDelegate?.onSucessfulRegistration(self, uid: viewModel.userId)
      })
    }
  }

  func handleError(viewModel: Registration.HandleError.ViewModel) {
    dismissHUD()
    let _ = SweetAlert().showAlert(on: self, title: viewModel.errorTitle ?? "Oops", subTitle: viewModel.errorMessage ?? "Something went wrong. Please try again.", style: .error, buttonTitle: "OK", buttonColor: .systemOrange)
  }
}

// Reusable components
extension RegistrationViewController {
  // MARK: - Use Case: Show ProgressHUD
  func showHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.show()
    }
  }

  // MARK: - Use Case: Dismiss ProgressHUD
  func dismissHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.dismiss()
    }
  }
}
