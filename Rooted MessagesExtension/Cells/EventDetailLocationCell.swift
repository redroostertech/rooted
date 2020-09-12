//
//  EventDetailLocationCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/31/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class EventDetailLocationCell: UITableViewCell {
  @IBOutlet weak var nameOfLocationLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var navigationButton: UIButton!

  var nameOfLocation: String! {
    didSet {
      nameOfLocationLabel.text = nameOfLocation
    }
  }

  var address: String! {
    didSet {
      addressLabel.text = address
    }
  }

  weak var delegate: EventDetailDelegate?

  func configure(delegate: EventDetailDelegate?,
                 nameOfLocation: String,
                 address: String) {
    self.delegate = delegate
    self.nameOfLocation = nameOfLocation
    self.address = address
  }

  @IBAction func navigateAction(_ sender: UIButton) {
    delegate?.navigateToMeeting(self)
  }

}
