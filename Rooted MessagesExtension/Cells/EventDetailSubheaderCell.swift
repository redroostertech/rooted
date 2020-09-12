//
//  EventDetailSubheaderCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/31/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

protocol EventDetailDelegate: class {
  func isUserAttendingMeeting(_ sender: UITableViewCell, isAttending: Bool)
  func joinByPhone(_ sender: UITableViewCell, phoneNumber: String)
  func joinByConference(_ sender: UITableViewCell, url: String)
  func navigateToMeeting(_ sender: UITableViewCell)
  func viewAttendees(_ sender: UITableViewCell)
}

extension EventDetailDelegate {
  func isUserAttendingMeeting(_ sender: UITableViewCell, isAttending: Bool) { }
  func joinByPhone(_ sender: UITableViewCell, phoneNumber: String) { }
  func joinByConference(_ sender: UITableViewCell, url: String) { }
  func navigateToMeeting(_ sender: UITableViewCell) { }
  func viewAttendees(_ sender: UITableViewCell) { }
}

class EventDetailSubheaderCell: UITableViewCell {

  @IBOutlet weak var organizerNameLabel: UILabel!
  @IBOutlet weak var organizerImageView: AvatarViewController!
  @IBOutlet weak var areYouGoinContainerView: UIView!
  @IBOutlet weak var noButton: UIButton!
  @IBOutlet weak var yesButton: UIButton!

  var organizerName: String! {
    didSet {
      organizerNameLabel.text = organizerName
    }
  }

  var organizerImage: UIImage? {
    didSet {
      AvatarHelper.setDefaultAvatar(displayName: organizerName, avatarString: nil, avatarImage: organizerImage, isRound: true, borderWidth: 1.0, borderColor: .systemOrange, avatarView: organizerImageView)
    }
  }

  var areYouGoingState: Bool? {
    didSet {
      guard let areyougoingstate = areYouGoingState else {
        self.yesButton.isHidden = false
        self.noButton.isHidden = false
        return
      }
      if areyougoingstate {
        self.yesButton.isHidden = true
        self.noButton.isHidden = false
      } else {
        self.yesButton.isHidden = false
        self.noButton.isHidden = true
      }
    }
  }

  weak var delegate: EventDetailDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    organizerImageView.applyCornerRadius()
    areYouGoinContainerView.applyCornerRadius()
    yesButton.applyCornerRadius()
    noButton.applyCornerRadius()
  }

  func configure(delegate: EventDetailDelegate?,
                 organizerName: String,
                 organizerImage: UIImage?,
                 areYouGoingState: Bool? = nil) {
    self.delegate = delegate
    self.organizerName = organizerName
    self.organizerImage = organizerImage
    self.areYouGoingState = areYouGoingState
  }

  @IBAction func noAction(_ sender: UIButton) {
    delegate?.isUserAttendingMeeting(self, isAttending: false)
  }

  @IBAction func yesAction(_ sender: UIButton) {
    delegate?.isUserAttendingMeeting(self, isAttending: true)
  }
}
