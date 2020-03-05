//
//  RootedCollectionViewModel.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation

public class RootedCollectionViewModel {
  var section: ListViewSection = .none
  var cells: [RootedCellViewModel] = [RootedCellViewModel]()

  init(section: ListViewSection = .none, cells: [RootedCellViewModel] = [RootedCellViewModel]()) {

  }
}
