//
//  RootedCellDelegate.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public enum ActionType {
  case delete
  case share
  case view
  case none
}

public protocol RootedCellDelegate: class {
  func performActions(_ cell: UICollectionViewCell, ofType: ActionType, on model: Any?, andManagedObject managedObject: [NSManagedObject]?)
}
