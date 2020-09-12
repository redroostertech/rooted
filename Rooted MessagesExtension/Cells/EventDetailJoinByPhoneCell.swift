//
//  EventDetailJoinByPhoneCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/31/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class EventDetailJoinByPhoneCell: UITableViewCell {

  @IBOutlet weak var joinByPhoneButton: UIButton!
  @IBOutlet weak var phoneNumberLabel: UILabel!

  weak var delegate: EventDetailDelegate?

  var phoneNumber: String! {
    didSet {
      phoneNumberLabel.text = phoneNumber
    }
  }
  func configure(delegate: EventDetailDelegate?,
                 phoneNumber: String) {
    self.phoneNumber = phoneNumber
  }
    
  @IBAction func joinByPhoneAction(_ sender: UIButton) {
    delegate?.joinByPhone(self, phoneNumber: phoneNumber)
  }
}
