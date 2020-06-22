//
//  ForgotPasswordPresenter.swift
//  Rooted
//
//  Created by Michael Westbrooks on 6/20/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol ForgotPasswordPresentationLogic
{
  func presentSomething(response: ForgotPassword.Something.Response)
}

class ForgotPasswordPresenter: ForgotPasswordPresentationLogic
{
  weak var viewController: ForgotPasswordDisplayLogic?
  
  // MARK: Do something
  
  func presentSomething(response: ForgotPassword.Something.Response)
  {
    let viewModel = ForgotPassword.Something.ViewModel()
    viewController?.displaySomething(viewModel: viewModel)
  }
}
