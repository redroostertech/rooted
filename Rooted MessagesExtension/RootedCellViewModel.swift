//
//  RootedCellViewModel.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class RootedCellViewModel {
  public var data: Meeting?
  public var delegate: RootedCellDelegate?
  public var section: ListViewSection = .none
  public var configurableCellType: ConfigurableCell = .defaultCell
  public var internalCellConfiguration: ListableCellType = .meeting

  public var managedObject: NSManagedObject?

  init(data: Meeting?, delegate: RootedCellDelegate?, section: ListViewSection = .none, cellType: ConfigurableCell = .defaultCell, configuration: ListableCellType = .meeting) {
    self.data = data
    self.delegate = delegate
    self.section = section
    configurableCellType = cellType
    internalCellConfiguration = configuration
  }
}
