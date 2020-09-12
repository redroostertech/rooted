//
//  EventDetailTimeCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/31/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class EventDetailTimeCell: UITableViewCell {

  @IBOutlet weak var whenLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!

  var when: String! {
    didSet {
      whenLabel.text = when
    }
  }

  var time: String! {
    didSet {
      timeLabel.text = time
    }
  }

  func configure(when: String, time: String) {
    self.when = when
    self.time = time
  }
}
