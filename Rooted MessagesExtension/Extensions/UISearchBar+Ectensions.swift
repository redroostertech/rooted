//
//  UISearchBar+Ectensions.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 1/28/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

// SearchBar String Constants
public let kSearchBarTextFieldKey = "searchField"
public let kSearchBarTextFieldPlaceholderLabel = "placeholderLabel"

extension UISearchBar {
  func setPlaceholderTextColorTo(color: UIColor) {
    guard let textFieldInsideSearchBar = self.value(forKey: kSearchBarTextFieldKey) as? UITextField, let textFieldInsideSearchBarLabel = textFieldInsideSearchBar.value(forKey: kSearchBarTextFieldPlaceholderLabel) as? UILabel else  { return }

    textFieldInsideSearchBar.textColor = color
    textFieldInsideSearchBarLabel.textColor = color
  }

  func setMagnifyingGlassColorTo(color: UIColor) {
    guard let textFieldInsideSearchBar = self.value(forKey: kSearchBarTextFieldKey) as? UITextField, let glassIconView = textFieldInsideSearchBar.leftView as? UIImageView, let glassIconViewImage = glassIconView.image else { return }

    glassIconView.image = glassIconViewImage.withRenderingMode(.alwaysTemplate)
    glassIconView.tintColor = color
  }
}
