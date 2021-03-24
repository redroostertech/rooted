//
//  UpdateValueViewController.swift
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
import Eureka

protocol UpdateValueDisplayLogic: class {
  func onUpdateProfile(viewModel: UpdateValue.Something.ViewModel)
  /// Handle any and all scenarios when something goes wrong
  func handleError(viewModel: UpdateValue.HandleError.ViewModel)
}

class UpdateValueViewController: BaseFormMessagesViewController, UpdateValueDisplayLogic {

  var interactor: UpdateValueBusinessLogic?
  var router: (NSObjectProtocol & UpdateValueRoutingLogic & UpdateValueDataPassing)?

  var tagForTextField: String!
  var titleForTextField: String!

  // MARK: - Lifecycle methods
  static func setupViewController(tag: String, title: String) -> UpdateValueViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "UpdateValueViewController") as! UpdateValueViewController
    viewController.tagForTextField = tag
    viewController.titleForTextField = title
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
    let interactor = UpdateValueInteractor()
    let presenter = UpdateValuePresenter()
    let router = UpdateValueRouter()
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
    let _ = setupNavigationBarButton(title: "Update Profile", tintColor: .systemBlue, action: #selector(updateProfileAction), target: self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    form
    +++ Section()
      <<< TextRow() {
        $0.tag = tagForTextField
        $0.title = titleForTextField
    }
  }

  @objc func updateProfileAction() {
    updateProfile()
  }

  func updateProfile() {
    showHUD()
    guard let valueForTag = (form.rowBy(tag: tagForTextField) as? TextRow)!.value else {
      let _ = SweetAlert().showAlert(on: self,
                                     title: "Incomplete Form",
                                     subTitle: "Field cannot be empty. Please enter a value and try again.",
                                     style: .error,
                                     buttonTitle: "OK",
                                     buttonColor: .systemOrange)
      return
    }
    var request = UpdateValue.Something.Request()
    request.tag = tagForTextField
    request.value = valueForTag
    interactor?.updateProfile(request: request)
  }

  func onUpdateProfile(viewModel: UpdateValue.Something.ViewModel) {
    dismissHUD()
    if let userData = viewModel.userData {
      SessionManager.refresh(with: userData)
    }
    navigationController?.popViewController(animated: true)
  }

  func handleError(viewModel: UpdateValue.HandleError.ViewModel) {
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
extension UpdateValueViewController {
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