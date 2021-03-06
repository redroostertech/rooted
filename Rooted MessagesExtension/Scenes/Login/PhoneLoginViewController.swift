//
//  PhoneLoginViewController.swift
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
import OnboardKit

protocol AuthenticationLogic: class {
  func onSucessfulLogin(_ sender: PhoneLoginViewController, uid: String?)
  func handleFailedLogin(_ sender: PhoneLoginViewController, reason: String)
  func onSucessfulRegistration(_ sender: RegistrationViewController, uid: String?)
  func handleFailedRegistration(_ sender: RegistrationViewController, reason: String)
}

extension AuthenticationLogic {
  func onSucessfulLogin(_ sender: PhoneLoginViewController, uid: String?) { }
  func handleFailedLogin(_ sender: PhoneLoginViewController, reason: String) { }
  func onSucessfulRegistration(_ sender: RegistrationViewController, uid: String?) { }
  func handleFailedRegistration(_ sender: RegistrationViewController, reason: String) { }
}

protocol PhoneLoginDisplayLogic: class {
  func onSuccessfulEmailAndPasswordLogin(viewModel: PhoneLogin.LoginViaEmailAndPassword.ViewModel)
  func onSuccessfulForgotPassword(viewModel: PhoneLogin.ForgotPassword.ViewModel)
  func onSuccessfulSessionSet(viewModel: PhoneLogin.SetSession.ViewModel)

  /// Handle any and all scenarios when something goes wrong
  func handleError(viewModel: PhoneLogin.HandleError.ViewModel)
}

let kSubtitleSignInYourAccount = "Sign-in to your account"
let kSubtitleForgotYourPassword = "Forgot your password?"
let kButtonLogin = "Login"
let kButtonCancel = "Go back to Login"
let kButtonCreateNewPassword = "Create New Password"
let kButtonForgotPassword = kSubtitleForgotYourPassword

class PhoneLoginViewController: FormMessagesAppViewController, PhoneLoginDisplayLogic, UITextFieldDelegate {

  @IBOutlet var loginButton: UIButton!
  @IBOutlet weak var forgotPasswordButton: UIButton!
  @IBOutlet weak var subTitleLabel: UILabel!

  var interactor: PhoneLoginBusinessLogic?
  var router: (NSObjectProtocol & PhoneLoginRoutingLogic & PhoneLoginDataPassing)?

  var isLogin: Bool! {
    didSet {
      self.form.removeAll()
      switch self.isLogin {
      case true:
        self.subTitleLabel.text = kSubtitleSignInYourAccount
        self.forgotPasswordButton.setTitle(kButtonForgotPassword, for: .normal)
        self.loginButton.setTitle(kButtonLogin, for: .normal)
        self.loadForm()
      case false:
        self.subTitleLabel.text = kSubtitleForgotYourPassword
        self.forgotPasswordButton.setTitle(kButtonCancel, for: .normal)
        self.loginButton.setTitle(kButtonCreateNewPassword, for: .normal)
        self.loadForm()
      case .none, .some(_):
        break
      }
    }
  }

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
    let interactor = PhoneLoginInteractor()
    let presenter = PhoneLoginPresenter()
    let router = PhoneLoginRouter()
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
    loginButton.applyCornerRadius()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isLogin = true
  }

  func loadForm() {
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

      if let rememberMeEmail = SessionManager.rememberMeEmail {
        $0.value = rememberMeEmail
      }

    }.cellUpdate { cell, row in
      NavigationCoordinator.performExpandedNavigation(from: self) {
        // Adjust view
        if !row.isValid {
          cell.textField.textColor = .systemRed
          self.loginButton.isEnabled = false
          self.loginButton.isUserInteractionEnabled = false
        } else {
          cell.textField.textColor = .black
          self.loginButton.isEnabled = true
          self.loginButton.isUserInteractionEnabled = true
        }
      }
    }

    if isLogin {
      form.last! <<< PasswordRow(kFormPassword) {
        $0.placeholder = kFormPasswordPlaceholder
        $0.add(rule: RuleRequired())
        $0.validationOptions = .validatesAlways

        if isDebug {
          $0.value = kDebugPassword
        }

      }.cellUpdate { cell, row in
        NavigationCoordinator.performExpandedNavigation(from: self) {
          // Adjust view
          if !row.isValid {
            cell.textField.textColor = .systemRed
            self.loginButton.isEnabled = false
            self.loginButton.isUserInteractionEnabled = false
          } else {
            cell.textField.textColor = .black
            self.loginButton.isEnabled = true
            self.loginButton.isUserInteractionEnabled = true
          }
        }
      }

      let rememberMe = [kFormRememberMe]

      form +++ SelectableSection<ImageCheckRow<String>>("", selectionType: .singleSelection(enableDeselection: true))

      for option in rememberMe {
        if let _ = SessionManager.rememberMeEmail {
          form.last! <<< ImageCheckRow<String>(option){ lrow in
            lrow.cell.selectionStyle = .none
            lrow.cell.falseImage = UIImage(named: "checked-circle")!
            lrow.cell.trueImage = UIImage(named: "un-checked-circle")!
            lrow.cell.accessoryType = .checkmark
            lrow.title = option
            lrow.selectableValue = option
            lrow.value = nil
          }.cellSetup { cell, _ in
            cell.falseImage = UIImage(named: "checked-circle")!
            cell.trueImage = UIImage(named: "un-checked-circle")!
            cell.accessoryType = .checkmark
          }
        } else {
          form.last! <<< ImageCheckRow<String>(option){ lrow in
            lrow.cell.selectionStyle = .none
            lrow.cell.trueImage = UIImage(named: "checked-circle")!
            lrow.cell.falseImage = UIImage(named: "un-checked-circle")!
            lrow.cell.accessoryType = .checkmark
            lrow.title = option
            lrow.selectableValue = option
            lrow.value = nil
          }.cellSetup { cell, _ in
            cell.trueImage = UIImage(named: "checked-circle")!
            cell.falseImage = UIImage(named: "un-checked-circle")!
            cell.accessoryType = .checkmark
          }
        }
      }
    }
  }

  @IBAction func loginAction(_ sender: UIButton) {
    if isLogin {
      self.loginViaEmailAndPassword()
    } else {
      self.forgotPassword()
    }
  }

  // MARK: - Use Case: When a user forgets their password, send a request to retrieve new password
  @IBAction func forgotPasswordAction(_ sender: UIButton) {
    // Update UI
    if isLogin {
      isLogin = false
    } else {
      isLogin = true
    }
  }

  func forgotPassword() {
    showHUD()
    var request = PhoneLogin.ForgotPassword.Request()
    request.email = (form.rowBy(tag: kFormEmailAddress) as? EmailRow)?.value ?? ""
    interactor?.forgotPassword(request: request)
  }

  func onSuccessfulForgotPassword(viewModel: PhoneLogin.ForgotPassword.ViewModel) {
    dismissHUD()
    displayError(with: "Forgot Password", and: "Successfully requested a new password.")
    isLogin = true
  }

  // MARK: - Use Case: When a user provides their email and a password, try to log them in via Firebase
  func loginViaEmailAndPassword() {
    showHUD()
    var request = PhoneLogin.LoginViaEmailAndPassword.Request()
    request.email = (form.rowBy(tag: kFormEmailAddress) as? EmailRow)?.value ?? ""
    request.password = (form.rowBy(tag: kFormPassword) as? PasswordRow)?.value ?? ""
    if let _ = SessionManager.rememberMeEmail {
      if let _ = (form.allSections.last as! SelectableSection<ImageCheckRow<String>>).selectedRow() {
        request.isRememberMeOn = false
      }
    } else {
      if let _ = (form.allSections.last as! SelectableSection<ImageCheckRow<String>>).selectedRow() {
        request.isRememberMeOn = true
      }
    }
    interactor?.loginViaEmailAndPassword(request: request)
  }

  func onSuccessfulEmailAndPasswordLogin(viewModel: PhoneLogin.LoginViaEmailAndPassword.ViewModel) {
    dismissHUD()
    startUserSession(with: viewModel.userId, and: viewModel.userData)
  }

  func startUserSession(with userId: String?, and userData: UserProfileData?) {
    var request = PhoneLogin.SetSession.Request()
    request.userId = userId
    request.userData = userData
    interactor?.startUserSession(request: request)
  }

  func onSuccessfulSessionSet(viewModel: PhoneLogin.SetSession.ViewModel) {
    let _ = SweetAlert().showAlert(on: self, title: "Thank You!", subTitle: "You are now logged in.", style: .success, buttonTitle: "Proceed", buttonColor: .systemOrange) { success in
      self.dismiss(animated: true, completion: {
        self.router?.dataStore?.authenticationLogicDelegate?.onSucessfulLogin(self, uid: viewModel.userId)
      })
    }
  }

  func handleError(viewModel: PhoneLogin.HandleError.ViewModel) {
    dismissHUD()
    let _ = SweetAlert().showAlert(on: self,
                                   title: viewModel.errorTitle ?? "Oops",
                                   subTitle: viewModel.errorMessage ?? "Something went wrong. Please try again.",
                                   style: .error,
                                   buttonTitle: "OK",
                                   buttonColor: .systemOrange)
  }
}

// Reusable components
extension PhoneLoginViewController {
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

public final class ImageCheckRow<T: Equatable>: Row<ImageCheckCell<T>>, SelectableRowType, RowType {
    public var selectableValue: T?
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public class ImageCheckCell<T: Equatable> : Cell<T>, CellType {

    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Image for selected state
    lazy public var trueImage: UIImage = {
        return UIImage(named: "checked-circle")!
    }()

    /// Image for unselected state
    lazy public var falseImage: UIImage = {
        return UIImage(named: "un-checked-circle")!
    }()

    public override func update() {
        super.update()
        checkImageView?.image = row.value != nil ? trueImage : falseImage
        checkImageView?.sizeToFit()
    }

    /// Image view to render images. If `accessoryType` is set to `checkmark`
    /// will create a new `UIImageView` and set it as `accessoryView`.
    /// Otherwise returns `self.imageView`.
    open var checkImageView: UIImageView? {
        guard accessoryType == .checkmark else {
            return self.imageView
        }

        guard let accessoryView = accessoryView else {
            let imageView = UIImageView()
            self.accessoryView = imageView
            return imageView
        }

        return accessoryView as? UIImageView
    }

    public override func setup() {
        super.setup()
        accessoryType = .none
    }

    public override func didSelect() {
        row.reload()
        row.select()
        row.deselect()
    }

}
