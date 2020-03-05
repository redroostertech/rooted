//
//  ConfigurableCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

public enum ConfigurableCell {

  case defaultCell
  case custom(String)

  var reuseIdentifier: String {
    switch self {
    case .defaultCell: return "RootedCollectionViewCell"
    case .custom(let customIdentifier):
      return customIdentifier
    }
  }
}
