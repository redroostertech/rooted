//
//  CustomHeader.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/5/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class CustomHeader: UICollectionReusableView {

  @IBOutlet private weak var mainTitleLabel: UILabel!

  func configure(title: String) {
    mainTitleLabel.text = title
  }
}
