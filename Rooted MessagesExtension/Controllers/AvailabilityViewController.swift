//
//  AvailabilityViewController.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/8/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit
import Branch
import SSSpinnerButton
import CoreData

class AvailabilityModelBuilder {
  var dictionary: [String: Any]?
  var meeting: Meeting?

  func start() -> AvailabilityModelBuilder {
    self.dictionary = [String: Any]()
    return self
  }

  func retrieve(forKey key: String) -> Any? {
    if dictionary != nil {
      if dictionary![key] != nil {
        return dictionary![key]
      } else {
        return nil
      }
    } else {
      return nil
    }
  }

  func has(key: String) -> Bool {
    if dictionary != nil {
      return dictionary!.keys.contains(key)
    } else {
      return false
    }
  }

  func add(key: String, value: Any) -> AvailabilityModelBuilder {
    if dictionary != nil {
      dictionary![key] = value
      return self
    } else {
      return start().add(key: key, value: value)
    }
  }
  func remove(key: String, value: Any) -> AvailabilityModelBuilder {
    if dictionary != nil, dictionary![key] != nil {
      dictionary!.removeValue(forKey: key)
      return self
    } else {
      return self
    }
  }
  func generateMeeting() -> AvailabilityModelBuilder {
    if dictionary != nil {
      var meetingDict: [String: Any] = [
        "meeting_name": retrieve(forKey: "meeting_name") as? String ?? ""
      ]

      if let meetinglocation = retrieve(forKey: "meeting_location") as? String, let rlocation = RLocation(JSONString: meetinglocation) {
        meetingDict["meeting_location"] = rlocation.toJSON()
      }

      if let startdate = retrieve(forKey: "start_date") as? Date, let enddate = retrieve(forKey: "end_date") as? Date {

        var dateDict = [
          "start_date": startdate.toString(),
          "end_date": enddate.toString()
        ]

        if let timezone = retrieve(forKey: "time_zone") as? String {
          dateDict["time_zone"] = timezone
        }

        if let dateclass = MeetingDateClass(JSON: dateDict) {
          meetingDict["meeting_date"] = dateclass.toJSON()
        }
      }

      if let meetingTypes = retrieve(forKey: "meeting_type") as? [[String: Any]] {

        var meetingtypes = [MeetingType]()

        for meetingType in meetingTypes {
          if let meetingtype = MeetingType(JSON: meetingType) {
            meetingtypes.append(meetingtype)
          }
        }

        meetingDict["meeting_type"] = meetingtypes.toJSON()

      }
      meeting = Meeting(JSON: meetingDict)
      return self
    } else {
      return self
    }
  }
}

class AvailabilityViewController: FormMessagesAppViewController {

  @IBOutlet private weak var shareAvailabilityButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  private var isCalendarShowing: Bool = false
  private var datePicker = WWCalendarTimeSelector.instantiate()

  // Managers
  private var coreDataManager = CoreDataManager()
  private var eventKitManager = EventKitManager()

  var datesOfAvailability: [NSManagedObject] = []

  // Model
  private var modelBuilder = AvailabilityModelBuilder().start()
  private var currentDate = Date()
  private var startDate: Date?
  private var endDate: Date?
  private var eventLength: MeetingTimeLength?

  override func viewDidLoad() {
    super.viewDidLoad()
    setupSpinnerButton()
    setupDatePicker()
    setupObservers()

    form
      +++ Section(header: "Availability", footer: "Set your available hours when people can schedule meetings with you.")
      <<< LabelRow(tag: "current_date")
  }

  override func keyboardWillShow(_ notification:Notification) {
    super.keyboardWillShow(notification)
  }

  override func keyboardWillHide(_ notification:Notification) {
    super.keyboardWillHide(notification)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
    view.bringSubviewToFront(actionsContainerView)

    eventKitManager.getCalendarPermissions { (success) in
      if success {
        self.shareAvailabilityButton.isEnabled = true
      } else {
        self.shareAvailabilityButton.isEnabled = false
        self.showError(title: kCalendarPermissions, message: kCalendarAccess)
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  // MARK: - Private methods
  private func setupSpinnerButton() {
    shareAvailabilityButton.applyCornerRadius()
    shareAvailabilityButton.spinnerColor = UIColor.gradientColor2
  }

  private func setupDatePicker() {
    datePicker.delegate = self
    datePicker.optionIdentifier = "start_date"
    datePicker.optionCurrentDate = currentDate
    datePicker.optionShowTopPanel = false
    datePicker.optionTimeStep = .fifteenMinutes
  }

  private func setupObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.init(rawValue: "keyboardWillShowNotification"), object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.init(rawValue: "keyboardWillHideNotification"), object: nil)
  }
  // MARK: - IBActions
  @IBAction func sendToFriends(_ sender: UIButton) {
    BranchEvent.customEvent(withName: "user_started_sharing_availability")
  }

  @IBAction func cancelAction(_ sender: UIButton) {
    NotificationCenter.default.post(name: Notification.Name(rawValue: "MyInvitesVC.reload"), object: nil, userInfo: [:])
    dismiss(animated: true, completion: nil)
  }
}

// MARK: - WWCalendarTimeSelectorProtocol
extension AvailabilityViewController: WWCalendarTimeSelectorProtocol {
  func WWCalendarTimeSelectorDone(_ selector: WWCalendarTimeSelector, date: Date) {
//    if selector.optionIdentifier ?? "" == "start_date" {
//
//      let _ = self.meetingBuilder.add(key: "start_date", value: date)
//
//      if let cell = form.rowBy(tag: "start_date") as? ButtonRow {
//        cell.title = date.toString(.proper)
//        cell.value = date.toString(.proper)
//        cell.updateCell()
//      }
//    }
//
//    if selector.optionIdentifier ?? "" == "end_date" {
//
//      let _ = self.meetingBuilder.add(key: "end_date", value: date)
//
//      if let cell = form.rowBy(tag: "end_date") as? PushRow<String> {
//        cell.title = "Event ends on"
//        cell.value = date.toString(.proper)
//      }
//    }
//    self.navigationController?.popViewController(animated: true)
  }

  func WWCalendarTimeSelectorShouldSelectDate(_ selector: WWCalendarTimeSelector, date: Date) -> Bool {
//    if selector.optionIdentifier ?? "" == "start_date" {
//      if date.timeIntervalSinceNow.isLess(than: 0) {
//        return false
//      }
//
//      if date.timeIntervalSince(Date().addingTimeInterval(60 * 60 * 24 * 7)).isLess(than: 0) {
//        return true
//      }
//    }
//
//    if selector.optionIdentifier ?? "" == "end_date" {
//
//      guard let startdate = self.meetingBuilder.retrieve(forKey: "start_date") as? String else { return true }
//
//      if date.timeIntervalSince(startdate.convertToDate(.proper)).isLess(than: 0) {
//        return false
//      }
//
//      if date.timeIntervalSince(startdate.convertToDate(.proper).addingTimeInterval(60 * 60 * 24 * 7)).isLess(than: 0) {
//        return true
//      }
//    }
    return false
  }
}
