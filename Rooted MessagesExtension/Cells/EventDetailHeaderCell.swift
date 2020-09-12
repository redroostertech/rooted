//
//  EventDetailHeaderCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/31/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class EventDetailHeaderCell: UITableViewCell {

  @IBOutlet private weak var eventNameLabel: UILabel!
  @IBOutlet private weak var numOfPeopleAttendingButton: UIButton!

  private var eventName: String! {
    didSet {
      eventNameLabel.text = eventName
    }
  }

  private var numOfPeopleAttending: Int! {
    didSet {
      numOfPeopleAttendingButton.setTitle("\(String(describing: numOfPeopleAttending)) of people attending", for: .normal)
    }
  }

  weak var delegate: EventDetailDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func configure(delegate: EventDetailDelegate?,
                 eventName: String,
                 numOfPeopleAttending: Int) {
    self.delegate = delegate
    self.eventName = eventName
    self.numOfPeopleAttending = numOfPeopleAttending
  }

  @IBAction func viewAttendeesAction(_ sender: UIButton) {
    delegate?.viewAttendees(self)
  }
}
