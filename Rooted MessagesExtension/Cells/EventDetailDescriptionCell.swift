//
//  EventDetailDescriptionCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/31/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class EventDetailDescriptionCell: UITableViewCell {

  @IBOutlet weak var descriptionLabel: ReadMoreTextView!

  var descriptionString: String? {
    didSet {
      descriptionLabel.text = descriptionString
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    descriptionLabel.shouldTrim = true
    descriptionLabel.maximumNumberOfLines = 4
    descriptionLabel.attributedReadMoreText = NSAttributedString(string: "\nRead more")
    descriptionLabel.attributedReadLessText = NSAttributedString(string: "\nRead less")
  }

  func configure(description: String) {
    descriptionString = description
  }
}
