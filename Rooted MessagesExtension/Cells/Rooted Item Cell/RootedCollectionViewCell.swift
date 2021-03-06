//
//  RootedCollectionViewCell.swift
//  RootedCore
//
//  Created by Michael Westbrooks on 1/21/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

class RootedCollectionViewCell: UICollectionViewCell {

  @IBOutlet weak var mainContentView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var actionsButton: UIButton!
  @IBOutlet weak var ownershipLabel: UILabel!

  private weak var delegate: RootedCellDelegate?
  private var participants = [UserProfileShortData]()

  private var viewModel: RootedCellViewModel? {
    didSet {
      guard let viewmodel = self.viewModel else { return }
      meeting = viewmodel.data
      delegate = viewmodel.delegate
    }
  }

  private var meeting: Meeting? {
    didSet {
      guard let meeting = self.meeting else { return }

      if let meetingName = meeting.meetingName {
        self.titleLabel.text = meetingName
      }

      dateLabel.text = ""

      if let meetingTime = meeting.meetingDate {
        self.dateLabel.text! += meetingTime.startTimeOnly
      }

      if let meetingLocation = meeting.meetingLocation {
        self.dateLabel.text! += " | \(meetingLocation.readableWhereString)"
      }

      if let meetingDescription = meeting.meetingDescription {
        self.dateLabel.text! += "\n\n\(meetingDescription)"
      }

      if let meetingOwner = meeting.ownerId, let currentUserId = SessionManager.shared.currentUser?.uid, meetingOwner != currentUserId {
        self.isOwnedByCurrentUser = false
      } else {
        self.isOwnedByCurrentUser = true
      }
    }
  }

  private var isOwnedByCurrentUser: Bool = true {
    didSet {
      if !self.isOwnedByCurrentUser {
        self.ownershipLabel.backgroundColor = .lightGray
        self.ownershipLabel.textColor = .darkGray
        self.ownershipLabel.text = "Not owned by you"
      } else {
        self.ownershipLabel.backgroundColor = .systemGreen
        self.ownershipLabel.textColor = .white
        self.ownershipLabel.text = "Owned by you"
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    titleLabel.adjustsFontSizeToFitWidth = true
    mainContentView.applyCornerRadius(0.10)
    mainContentView.backgroundColor = .groupTableViewBackground
    ownershipLabel.applyCornerRadius()
    ownershipLabel.textAlignment = .center
  }

  func configure(viewModel: RootedCellViewModel, layout: LayoutOption) {
    self.viewModel = viewModel

    if layout == .horizontalList {
      actionsButton.isHidden = true
    } else {
      actionsButton.isHidden = false
    }
  }

  @IBAction func performAction(_ sender: UIButton) {
    self.delegate?.performActions(self, ofType: .delete, on: viewModel)
  }

}
