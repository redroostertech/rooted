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
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var descriptionLabelHeight: NSLayoutConstraint!
  @IBOutlet weak var locationLabel: UILabel!
  @IBOutlet weak var locationImageView: UIButton!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var dateImageView: UIButton!
  @IBOutlet weak var participantsButton: UIButton!
  @IBOutlet weak var actionsButton: UIButton!
  @IBOutlet weak var separatorView: UILabel!

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

      if let meetingTime = meeting.meetingDate {
        dateLabel.text = meetingTime.readableTime
      }

      if let meetingLocation = meeting.meetingLocation {
        locationLabel.text = meetingLocation.readableWhereString
      } else {
        locationLabel.text = "No location provided"
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    participantsButton.isHidden = true
  }

  func configure(viewModel: RootedCellViewModel, layout: LayoutOption) {
    self.viewModel = viewModel

    if layout == .horizontalList {
      actionsButton.isHidden = true
      separatorView.isHidden = true
    } else {
      actionsButton.isHidden = false
      separatorView.isHidden = false
    }
  }

  @IBAction func viewParticipants(_ sender: UIButton) {
    self.delegate?.performActions(self, ofType: .none, on: nil, andManagedObject: nil)
  }

  @IBAction func performAction(_ sender: UIButton) {
    guard let viewmodel = self.viewModel, let managedobjects = viewmodel.managedObject else { return }
    self.delegate?.performActions(self, ofType: .delete, on: meeting, andManagedObject: [managedobjects])
  }

}
