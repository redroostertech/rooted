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
import FSCalendar
import SwiftDate
import Messages

class AvailabilityModelBuilder {
  var dictionary: [String: Any]?
  var availability: Availability?

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
  func generateModel() -> AvailabilityModelBuilder {
    if dictionary != nil {
      var meetingDict: [String: Any] = [:]

      if let availabledates = retrieve(forKey: "available_dates") as? [MeetingDateClass] {
        meetingDict["availability_dates"] = availabledates.toJSON()
      }

      availability = Availability(JSON: meetingDict)
      return self
    } else {
      return self
    }
  }
}

class AvailabilityViewController: FormMessagesAppViewController {

  @IBOutlet private weak var calendar: FSCalendar!
  @IBOutlet private weak var shareAvailabilityButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!
  @IBOutlet private weak var calendarHeightConstraint: NSLayoutConstraint!

  // Calendars
  private var isCalendarShowing: Bool = false
  private var datePicker = WWCalendarTimeSelector.instantiate()
  fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
    [unowned self] in
    let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
    panGesture.delegate = self
    panGesture.minimumNumberOfTouches = 1
    panGesture.maximumNumberOfTouches = 2
    return panGesture
    }()

  var sections = [String: [DateRangeCompletionWrapper]]()

  // Managers
  private var coreDataManager = CoreDataManager()
  private var eventKitManager = EventKitManager()
  private var dataManager = AvailabilityManager()

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
    setupObservers()

    calendar.delegate = self
    calendar.dataSource = self
    calendar.scope = .week
    calendar.select(currentDate)

    self.view.addGestureRecognizer(self.scopeGesture)
    self.tableView.panGestureRecognizer.require(toFail: self.scopeGesture)
    
    form
      +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                             header: "Edit Availability",
                             footer: "") {
                              $0.tag = "textfields"
                              $0.addButtonProvider = { section in
                                return ButtonRow(){
                                  $0.title = "Add New Interval"
                                  }.cellUpdate { cell, row in
                                    cell.textLabel?.textAlignment = .left
                                }
                              }

                              $0.multivaluedRowToInsertAt = { index in
                                return DateRangePickerInlineRow( "availability_date_\(index)_\(self.calendar.selectedDate!.toString(.normal))") {
                                  $0.title = "Select Availability Time Range"
                                  $0.cell.detailTextLabel?.textColor = .clear
                                  }.onChange { row in
                                    guard let value = row.value else { return }
                                    row.title = value.readableString ?? "Select Availability Time Range"
                                    row.updateCell()
                                    if var ranges =  self.sections[self.calendar.selectedDate!.toString(.normal)] {
                                      ranges.append(value)
                                      self.sections[self.calendar.selectedDate!.toString(.normal)] = ranges
                                    } else {
                                      self.sections[self.calendar.selectedDate!.toString(.normal)] = [value]
                                    }
                                }
                              }
                              


    }
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

  private func setupObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillShowNotification), object: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillHideNotification), object: nil)
  }

  private func displayError() {
    self.showError(title: "Oops!", message: "Please create availability times")
  }

  private func insert(_ availability: Availability) {
    // Try to convert object into MSMessage object
    guard let message = DataConverter.Availabilities.objectToMessage(availability) else {
      self.shareAvailabilityButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

        self.displayError()
      })
      return
    }

    BranchEvent.customEvent(withName: kBranchAvailabilityAddedCoreData)

    // Save availability to Core Data
    self.saveToCoreData(availability, message: message)
  }

  private func saveToCoreData(_ object: Availability, message: MSMessage) {
    dataManager.save(object) { (success, error) in
      if let err = error {
        // TODO: - Handle error if meeting was not saved into core data
        self.shareAvailabilityButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
          self.showError(title: "Oops!", message: "Something went wrong. Please try again.\n\nError message: \(err.localizedDescription)")
        })
      } else {
        if success {
          let alert = UIAlertController(title: "Share Availability", message: "Would you like to share your availability in the current conversation?", preferredStyle: .alert)
          let share = UIAlertAction(title: "Yes", style: .default, handler: { action in

            // After saving invite into core data, send the message
            self.send(message: message, toConversation: ConversationManager.shared.conversation, { success in
              if success {

                BranchEvent.customEvent(withName: kBranchEventSharedConversation)

                // If message was sent into the conversation dismiss the view
                self.dismiss(animated: true, completion: nil)
              } else {

                BranchEvent.customEvent(withName: kBranchEventSharedConversationFailed)

                // TODO: - Handle error if message couldn't be sent
                self.shareAvailabilityButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {

                  self.showError(title: "Oops!", message: "Something went wrong. Please try again.")
                })
              }
            })

          })
          let delete = UIAlertAction(title: "No", style: .destructive, handler: { action in
            self.dismiss(animated: true, completion: nil)
          })
          alert.addAction(share)
          alert.addAction(delete)
          self.present(alert, animated: true, completion: nil)

        } else {
          // If inserting meeting into calendar was unsuccessful we want to save invite into core data
          // TODO: - Handle success of false
          self.shareAvailabilityButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
            self.showError(title: "Oops!", message: "Something went wrong. Please try again.")
          })
        }
      }
    }
  }

  private func send(message: MSMessage, toConversation conversation: MSConversation?, _ completion: @escaping (Bool) -> Void) {
    conversation?.send(message) { (error) in
      if let err = error {
        self.shareAvailabilityButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail,backToDefaults: true, complete: {
          print("There was an error \(err.localizedDescription)")
          completion(false)
        })
      } else {

        NotificationCenter.default.post(name: Notification.Name(rawValue: kNotificationMyInvitesReload), object: nil, userInfo: [:])

        self.shareAvailabilityButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
          completion(true)
        })
      }
    }
  }


  // MARK: - IBActions
  @IBAction func sendToFriends(_ sender: UIButton) {
    BranchEvent.customEvent(withName: kBranchUserStartedSharingAvailability)

    shareAvailabilityButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {

      // Create empty array of dates
      var availabilityDates = [MeetingDateClass]()

      // Check if availability times exist
      for key in self.sections.keys {
        guard let availabilityDict = self.sections[key] else { return }

        // For each wrapper we want to create a meeting date class object and insert it into an array
        availabilityDates = availabilityDict.map({ wrapper -> MeetingDateClass in
          let dateDict = [
            "start_date": wrapper.fromDate?.toString() ?? "",
            "end_date": wrapper.toDate?.toString() ?? "",
            "time_zone": Zones.current.toTimezone().identifier
          ]
          return MeetingDateClass(JSON: dateDict)!
        })

        // Add availabile_dates to model builder
        self.modelBuilder = self.modelBuilder.add(key: "available_dates", value: availabilityDates)
      }

      guard let _ = self.modelBuilder.retrieve(forKey: "available_dates") as? [MeetingDateClass], let availability = self.modelBuilder.generateModel().availability else {

        self.shareAvailabilityButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail, backToDefaults: true, complete: {
          self.displayError()
        })
        return
      }

      self.insert(availability)
    })
  }

  @IBAction func cancelAction(_ sender: UIButton) {
    NotificationCenter.default.post(name: Notification.Name(rawValue: kNotificationMyInvitesReload), object: nil, userInfo: [:])
    dismiss(animated: true, completion: nil)
  }
}

// MARK: - FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate
extension AvailabilityViewController: FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
    if shouldBegin {
      let velocity = self.scopeGesture.velocity(in: self.view)
      switch self.calendar.scope {
      case .month:
        return velocity.y < 0
      case .week:
        return velocity.y > 0
      }
    }
    return shouldBegin
  }

  func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
    self.calendarHeightConstraint.constant = bounds.height
    self.view.layoutIfNeeded()
  }

  func reset(to date: Date, at monthPosition: FSCalendarMonthPosition, showError: Bool) {
    self.calendar.select(date)
    self.calendar(self.calendar, didSelect: date, at: monthPosition)
    self.calendar.setCurrentPage(date, animated: true)
    if showError {
      self.showError(title: "Oops!", message: "At this time, setting availability beyond 7 days from today is not available.")
    }
  }

  func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
    guard !date.timeIntervalSince(currentDate).isLess(than: 0) else {
      reset(to: currentDate, at: monthPosition, showError: false)
      return
    }

    guard date.timeIntervalSince(currentDate.addingTimeInterval(60 * 60 * 24 * 7)).isLess(than: 0) else {
      reset(to: currentDate, at: monthPosition, showError: true)
      return
    }

    if !sections.keys.contains(date.toString(.normal)) {
      sections[date.toString(.normal)] = []
    }

    /*
     var dateDict = [
     "start_date": startdate.toString(),
     "end_date": enddate.toString()
     ]

     if let timezone = retrieve(forKey: "availabile_time_zone") as? String {
     dateDict["time_zone"] = timezone
     }

     if let dateclass = MeetingDateClass(JSON: dateDict) {
     meetingDict["meeting_date"] = dateclass.toJSON()
     }
     */

    form.removeAll()

    form
      +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                             header: "Edit Availability",
                             footer: "") {
                              $0.tag = "textfields"
                              $0.addButtonProvider = { section in
                                return ButtonRow(){
                                  $0.title = "Add New Interval"
                                  }.cellUpdate { cell, row in
                                    cell.textLabel?.textAlignment = .left
                                }
                              }

                              $0.multivaluedRowToInsertAt = { index in
                                return DateRangePickerInlineRow( "availability_date_\(index)_\(self.calendar.selectedDate!.toString(.normal))") {
                                  $0.title = "Select Availability Time Range"
                                  $0.cell.detailTextLabel?.textColor = .clear
                                  }.onChange { row in
                                    guard let value = row.value else { return }
                                    row.title = value.readableString ?? "Select Availability Time Range"
                                    row.updateCell()
                                    if var ranges =  self.sections[self.calendar.selectedDate!.toString(.normal)] {
                                      ranges.append(value)
                                      self.sections[self.calendar.selectedDate!.toString(.normal)] = ranges
                                    } else {
                                      self.sections[self.calendar.selectedDate!.toString(.normal)] = [value]
                                    }
                                }
                              }

                              // If we select on a day and it already exists, then append the rows
                              guard let dateRanges = sections[date.toString(.normal)] else { return }
                              for dateRange in dateRanges {
                                let dateRangeIndex = dateRanges.index(of: dateRange)
                                $0.append(
                                  DateRangePickerInlineRow( "availability_date_\(String(describing: dateRangeIndex))_\(date.toString(.normal))") {
                                    $0.title = dateRange.readableString ?? "Select Availability Time Range"
                                    $0.cell.detailTextLabel?.textColor = .clear
                                    $0.value = dateRange
                                  }
                                )
                              }



    }

    if monthPosition == .next || monthPosition == .previous {
      calendar.setCurrentPage(date, animated: true)
    }
  }

  func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
//    print("\(self.dateFormatter.string(from: calendar.currentPage))")
  }
}
