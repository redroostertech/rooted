//
//  EditProfileViewController.swift
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
import Messages

protocol EditProfileDisplayLogic: class {
  func onSuccessfulForgotPassword(viewModel: EditProfile.ForgotPassword.ViewModel)

  /// Handle any and all scenarios when something goes wrong
  func handleError(viewModel: EditProfile.HandleError.ViewModel)
}

class EditProfileViewController: FormMessagesAppViewController, EditProfileDisplayLogic {

  @IBOutlet private weak var actionsContainerView: UIView!
  var interactor: EditProfileBusinessLogic?
  var router: (NSObjectProtocol & EditProfileRoutingLogic & EditProfileDataPassing)?

  // MARK: - Lifecycle methods
  static func setupViewController(meeting: RootedCellViewModel) -> EditProfileViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "EditProfileViewController") as! EditProfileViewController
    return viewController
  }

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
    let interactor = EditProfileInteractor()
    let presenter = EditProfilePresenter()
    let router = EditProfileRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.viewController = viewController
    router.dataStore = interactor
  }

  // MARK: View lifecycle
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if self.navigationController?.navigationBar != nil {
      self.actionsContainerView.isHidden = true
    }

    let _ = setupNavigationBarButton(title: "Done", tintColor: .systemBlue, action: #selector(doneAction), target: self)

    setupForm()
  }

  func setupForm() {
    // Clear form
    form.removeAll()

    // Check if logged in user exists
    guard let loggedInUser = SessionManager.shared.currentUser else { return }

    // Create form
    form
    +++ Section("Basic Profile")
//      <<< ImageViewerRow() {
//        $0.imageString = "http://www.domain.com/path/to/image.jpg"
//          $0.cellProvider = CellProvider<ImageViewerCell>(nibName: "ImageViewerCell", bundle: Bundle.main)
//      }.cellSetup { (cell, row) in
//          cell.height = { 187 }
//      }
//         <<< ImageRow() {
//             $0.title = "Image Row 2"
//             $0.sourceTypes = .PhotoLibrary
//             $0.clearAction = .no
//         }
//         .cellUpdate { cell, row in
//             cell.accessoryView?.layer.cornerRadius = 17
//             cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
//         }
      <<< LabelRow() {
        $0.tag = "full_name"
        $0.title = "Full Name"
        $0.value = loggedInUser.fullName ?? ""
    }.onCellSelection { cell, row in
      let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
      let destinationVC = sb.instantiateViewController(withIdentifier: kUpdateValueViewController) as! UpdateValueViewController
      destinationVC.tagForTextField = row.tag ?? ""
      destinationVC.titleForTextField = row.title ?? ""
      self.navigationController?.pushViewController(destinationVC, animated: true)
    }

      <<< LabelRow() {
        $0.tag = "phone_number"
        $0.title = "Phone Number"
        $0.value = loggedInUser.phoneNumber ?? ""
      }.onCellSelection { cell, row in
        let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
        let destinationVC = sb.instantiateViewController(withIdentifier: kUpdateValueViewController) as! UpdateValueViewController
        destinationVC.tagForTextField = row.tag ?? ""
        destinationVC.titleForTextField = row.title ?? ""
        self.navigationController?.pushViewController(destinationVC, animated: true)
      }

    +++ Section("Professional Information")
    <<< LabelRow() {
        $0.tag = "company_name"
        $0.title = "Company Name"
        $0.value = loggedInUser.companyName ?? ""
    }.onCellSelection { cell, row in
      let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
      let destinationVC = sb.instantiateViewController(withIdentifier: kUpdateValueViewController) as! UpdateValueViewController
      destinationVC.tagForTextField = row.tag ?? ""
      destinationVC.titleForTextField = row.title ?? ""
      self.navigationController?.pushViewController(destinationVC, animated: true)
    }

    <<< LabelRow() {
        $0.tag = "job_title"
        $0.title = "Job Title"
        $0.value = loggedInUser.jobTitle ?? ""
    }.onCellSelection { cell, row in
      let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
      let destinationVC = sb.instantiateViewController(withIdentifier: kUpdateValueViewController) as! UpdateValueViewController
      destinationVC.tagForTextField = row.tag ?? ""
      destinationVC.titleForTextField = row.title ?? ""
      self.navigationController?.pushViewController(destinationVC, animated: true)
    }

    +++ Section("Login Information")
      <<< LabelRow() {
        $0.tag = "email_address"
        $0.title = "Email Address"
        $0.value = loggedInUser.email ?? ""
    }.onCellSelection { cell, row in
//      let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
//      let destinationVC = sb.instantiateViewController(withIdentifier: kUpdateValueViewController) as! UpdateValueViewController
//      destinationVC.tagForTextField = row.tag ?? ""
//      destinationVC.titleForTextField = row.title ?? ""
//      self.navigationController?.pushViewController(destinationVC, animated: true)
    }

      <<< LabelRow () {
          $0.tag = "password"
          $0.title = "Password"
        $0.value = "******"
          }
          .onCellSelection { cell, row in
            self.forgotPassword()
      }

    // TODO: - Save for when main app is created
//    if var section = self.form.allSections.first {
//      if let isPhoneVerified = loggedInUser.isPhoneVerified, isPhoneVerified {
//        let row = NameRow("Phone is Verified", { nameRow in
//          nameRow.title = "Phone is Verified"
//          nameRow.disabled = true
//        })
//        section.insert(row, at: 2)
//        section.reload()
//      } else {
//        let row = ButtonRow("Verify Phone Number", { buttonRow in
//          buttonRow.title = "Verify Phone Number"
//          buttonRow.presentationMode = .show(controllerProvider: .callback(builder: {
//            let sb = UIStoryboard(name: kStoryboardMain, bundle: nil)
//            let destinationVC = sb.instantiateViewController(withIdentifier: kInfoViewController) as! InfoViewController
//            return destinationVC
//          }), onDismiss: nil)
//        })
//        section.insert(row, at: 2)
//        section.reload()
//      }
//    }
  }

  func forgotPassword() {
    showHUD()
    var request = EditProfile.ForgotPassword.Request()
    request.email = (form.rowBy(tag: "email_address") as? TextRow)?.value ?? ""
    interactor?.forgotPassword(request: request)
  }

  func onSuccessfulForgotPassword(viewModel: EditProfile.ForgotPassword.ViewModel) {
    dismissHUD()
    displayError(with: "Forgot Password", and: "Successfully requested a new password.")
  }

  @objc func doneAction() {
    navigationController?.popViewController(animated: true)
  }

  func handleError(viewModel: EditProfile.HandleError.ViewModel) {
    dismissHUD()
    let _ = SweetAlert().showAlert(on: self,
                                   title: viewModel.errorTitle ?? "Oops",
                                   subTitle: viewModel.errorMessage ?? "Something went wrong. Please try again.",
                                   style: .error,
                                   buttonTitle: "OK",
                                   buttonColor: .systemOrange)
  }

  // MARK: - Use Case: Accept the meeting, save it locally, and add it to your calendar
  @IBAction func back(_ sender: UIButton) {
    dismissView()
  }
}

// Reusable components
extension EditProfileViewController {
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
