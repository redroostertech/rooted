//
//  RegistrationPresenter.swift
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

protocol RegistrationPresentationLogic
{
  func presentSomething(response: Registration.Something.Response)
}

class RegistrationPresenter: RegistrationPresentationLogic
{
  weak var viewController: RegistrationDisplayLogic?
  
  // MARK: Do something
  
  func presentSomething(response: Registration.Something.Response)
  {
    let viewModel = Registration.Something.ViewModel()
    viewController?.displaySomething(viewModel: viewModel)
  }
}
