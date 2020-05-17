//
//  PhoneLoginRouter.swift
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

@objc protocol PhoneLoginRoutingLogic {
  //func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol PhoneLoginDataPassing {
  var dataStore: PhoneLoginDataStore? { get }
}

class PhoneLoginRouter: NSObject, PhoneLoginRoutingLogic, PhoneLoginDataPassing {
  weak var viewController: PhoneLoginViewController?
  var dataStore: PhoneLoginDataStore?
  
  // MARK: Routing
  
  //func routeToSomewhere(segue: UIStoryboardSegue?)
  //{
  //  if let segue = segue {
  //    let destinationVC = segue.destination as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //  } else {
  //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
  //    let destinationVC = storyboard.instantiateViewController(withIdentifier: "SomewhereViewController") as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //    navigateToSomewhere(source: viewController!, destination: destinationVC)
  //  }
  //}

  // MARK: Navigation
  
  //func navigateToSomewhere(source: PhoneLoginViewController, destination: SomewhereViewController)
  //{
  //  source.show(destination, sender: nil)
  //}
  
  // MARK: Passing data
  
  //func passDataToSomewhere(source: PhoneLoginDataStore, destination: inout SomewhereDataStore)
  //{
  //  destination.name = source.name
  //}
}
