//
//  AvailabilitySelectionViewController.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/17/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit
import SSSpinnerButton

class AvailableTimeCell: UITableViewCell {

  @IBOutlet private weak var tagListView: TagListView!

  private var timeSlots: [MeetingDateClass]? {
    didSet {
      guard let timeslots = self.timeSlots else {
        tagListView.addTag("No availability")
        return
      }
      let timeslotTitles: [String] = timeslots.map { slot -> String in
        return "\(slot.startDate ?? "") - \(slot.endDate ?? "")"
      }
      tagListView.addTags(timeslotTitles)
    }
  }

  weak var delegate: AvailabilitySelectionDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    tagListView.tagBackgroundColor = .gradientColor2
    tagListView.textColor = .white
  }

  func configure(delegate: AvailabilitySelectionDelegate, timeSlots: [MeetingDateClass]) {
    self.delegate = delegate
    tagListView.delegate = self
    self.timeSlots = timeSlots
  }
}

// MARK: - TagListViewDelegate
extension AvailableTimeCell: TagListViewDelegate {
  func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
    guard let timeslots = self.timeSlots else { return }
    self.delegate?.didSelect(self, time: timeslots[tagView.tag])
  }
}

protocol AvailabilitySelectionDelegate: class {
  func didSelect(_ cell: UITableViewCell, time: MeetingDateClass)
}

class AvailabilitySelectionViewController: BaseAppViewController {
  @IBOutlet private weak var mainTable: UITableView!
  @IBOutlet private weak var selectTimeSlotButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  private var contentManager = RootedContentInteractor()
  private var conversationManager = ConversationManager.shared
  private var availability: Availability?
  private var timeSlots = [String: [MeetingDateClass]]()

  // MARK: - Lifecycle methods
  static func setupViewController(availability: Availability) -> AvailabilitySelectionViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "AvailabilitySelectionViewController") as! AvailabilitySelectionViewController
    viewController.availability = availability
    return viewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    design(button: selectTimeSlotButton)

    if let available = self.availability, let timeslots = available.availabilityDates {
      for timeslot in timeslots {
        if let key = timeslot.startDate?.toDate()?.date.toString(.normal) {
          if var slots = self.timeSlots[key] {
            slots.append(timeslot)
            self.timeSlots[key] = slots
          } else {
            self.timeSlots[key] = [timeslot]
          }
        }
        self.mainTable.reloadData()
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
        self?.mainTable.beginUpdates()
        self?.mainTable.endUpdates()
      }
    }

    mainTable.register(AvailableTimeCell.self, forCellReuseIdentifier: "AvailableTimeCell")
    mainTable.estimatedRowHeight = UITableView.automaticDimension
    mainTable.reloadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    navigationController?.setNavigationBarHidden(true, animated: animated)

    view.bringSubviewToFront(actionsContainerView)

//    contentManager.checkCalendarPermissions { success in
//      if success {
//        self.selectTimeSlotButton.isEnabled = true
//      } else {
//        self.selectTimeSlotButton.isEnabled = false
//        self.showError(title: kCalendarPermissions, message: kCalendarAccess)
//      }
//    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  // MARK: - Private methods
  private func design(button: SSSpinnerButton) {
    button.applyCornerRadius()
    button.spinnerColor = UIColor.gradientColor2
  }

  private func sendToFriendsAction() {
    startAnimating(selectTimeSlotButton) {
      self.displaySuccess(afterAnimating: self.selectTimeSlotButton, completion: {
        print("OK")
      })
    }
  }

  // MARK: - IBActions
  @IBAction func sendToFriends(_ sender: UIButton) {
    sendToFriendsAction()
  }

  @IBAction func cancelAction(_ sender: UIButton) {
    postNotification(withName: kNotificationMyInvitesReload, andUserInfo: [:]) {
      self.dismiss(animated: true, completion: nil)
    }
  }
}

extension AvailabilitySelectionViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return timeSlots.keys.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "AvailableTimeCell") as? AvailableTimeCell else { return UITableViewCell() }
    let key = timeSlots.map { (key, value) -> String in
      return key
    }[indexPath.row]
    guard let items = timeSlots[key] else { return UITableViewCell() }
    cell.configure(delegate: self, timeSlots: items)
    return cell
  }

}

// MARK: - AvailabilitySelectionDelegate
extension AvailabilitySelectionViewController: AvailabilitySelectionDelegate {
  func didSelect(_ cell: UITableViewCell, time: MeetingDateClass) {
    let vc = CreateMeetingViewController.setupViewController(meetingDate: time)
    present(vc, animated: true) {
      self.dismiss(animated: true, completion: nil)
    }
  }
}
