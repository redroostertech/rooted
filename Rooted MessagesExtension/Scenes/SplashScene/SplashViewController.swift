//
//  SplashViewController.swift
//  Rooted
//
//  Created by Michael Westbrooks on 5/17/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol SplashDisplayLogic: class {

  /// IF a user session exists, ideally we want to return a `User` object in the view model to pass to next scene
  func doNavigateToDashboard(viewModel: Splash.CheckIfUserSessionExists.ViewModel)

  /// IF a user session does not exist, navigate to the login scene
  func doNavigateToLogin(viewModel: Splash.CheckIfUserSessionExists.ViewModel)

  /// Handle any and all scenarios when something goes wrong
  func handleError(viewModel: Splash.HandleError.ViewModel)
}

/*
 `SplashViewController` is the entry point into the mobile extension. It manages the initial flow and routing for the user.
*/
class SplashViewController: BaseAppViewController, SplashDisplayLogic {

  var interactor: SplashBusinessLogic?
  var router: (NSObjectProtocol & SplashRoutingLogic & SplashDataPassing)?

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
    let interactor = SplashInteractor()
    let presenter = SplashPresenter()
    let router = SplashRouter()
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
    checkIfUserSessionExists()
  }

  // MARK: - Use Case: When app loads initial view, we want to check to see if a session exists for the user
  func checkIfUserSessionExists() {
    let request = Splash.CheckIfUserSessionExists.Request()
    interactor?.checkIfUserSessionExists(request: request)
  }

  // MARK: - If user session exists due to the ability to derive a `User` object from business logic, go to the dashboard known as the `MyInvitesViewController` scene
  func doNavigateToDashboard(viewModel: Splash.CheckIfUserSessionExists.ViewModel) {
    if let _ = viewModel.userId {
      RRLogger.log(message: "Route to Dashboard", owner: self)
      self.router?.routeToDashboard()
    } else {
      self.doNavigateToLogin(viewModel: viewModel)
    }
  }

  // MARK: - If user session does not exist, go to the start the authentication process
  func doNavigateToLogin(viewModel: Splash.CheckIfUserSessionExists.ViewModel) {
    RRLogger.log(message: "Route to Login", owner: self)
    self.router?.routeToLogin()
  }

  func handleError(viewModel: Splash.HandleError.ViewModel) {
    // Handle an error if necessary
  }
}