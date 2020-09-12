//
//  EventDetailJoinVideoMeetingCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/31/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class EventDetailJoinVideoMeetingCell: UITableViewCell {

  @IBOutlet weak var joinByConferenceButton: UIButton!
  @IBOutlet weak var urlLabel: UILabel!

  weak var delegate: EventDetailDelegate?

  var url: String! {
    didSet {
      urlLabel.text = url
    }
  }

  func configure(delegate: EventDetailDelegate?,
                 url: String) {
    self.url = url
  }

  @IBAction func joinByConferenceAction(_ sender: UIButton) {
    delegate?.joinByConference(self, url: url)
  }
}
