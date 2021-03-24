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
import Eureka

class AvailabilityViewController: BaseFormMessagesViewController, RootedContentDisplayLogic, AvailabilityManagerDelegate {

  // MARK: - IBOutlets
  @IBOutlet private weak var calendar: FSCalendar!
  @IBOutlet private weak var shareAvailabilityButton: SSSpinnerButton!
  @IBOutlet private weak var cancelButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!
  @IBOutlet private weak var calendarHeightConstraint: NSLayoutConstraint!

  // Calendars
  fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
    [unowned self] in
    let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
    panGesture.delegate = self
    panGesture.minimumNumberOfTouches = 1
    panGesture.maximumNumberOfTouches = 2
    return panGesture
  }()

  var sections = [DateRangeCompletionWrapper]() {
    didSet {
      self.calendar.reloadData()
    }
  }

  // MARK: - Private Properties
  private var interactor: RootedContentBusinessLogic?
  private var conversationManager = ConversationManager.shared
  private var tempAvailability = [String: Any]()

  // Model
  private var currentDate = Date()

  // MARK: - Lifecycle methods
  static func setupViewController(meetingDate: MeetingDateClass) -> AvailabilityViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "AvailabilityViewController") as! AvailabilityViewController
    return viewController
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    let viewController = self
    let interactor = RootedContentInteractor()
    let presenter = RootedContentPresenter()
    viewController.interactor = interactor
    interactor.presenter = presenter
    presenter.viewController = viewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  override func keyboardWillShow(_ notification:Notification) {
    super.keyboardWillShow(notification)
  }

  override func keyboardWillHide(_ notification:Notification) {
    super.keyboardWillHide(notification)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    DispatchQueue.main.async {
      self.navigationController?.setNavigationBarHidden(true, animated: animated)
      self.view.bringSubviewToFront(self.actionsContainerView)
    }
    loadTable(for: currentDate)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    DispatchQueue.main.async {
      self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
  }

  // MARK: - Use Case: Setup the UI for the view
  private func setupUI() {
    setupSpinnerButton()
    setupObservers()

    calendar.delegate = self
    calendar.dataSource = self
    calendar.scope = .week
    calendar.select(currentDate)

    view.addGestureRecognizer(scopeGesture)
    tableView.panGestureRecognizer.require(toFail: scopeGesture)
  }

  private func setupSpinnerButton() {
    shareAvailabilityButton.applyCornerRadius()
    shareAvailabilityButton.spinnerColor = UIColor.gradientColor2
  }

  private func setupObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillShowNotification), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.init(rawValue: kNotificationKeyboardWillHideNotification), object: nil)
  }

  // MARK: - Use Case: Check if app has access to calendar permissions
  func checkCalendarPermissions() {
    let request = RootedContent.CheckCalendarPermissions.Request()
    interactor?.checkCalendarPermissions(request: request)
  }

  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) {
    if viewModel.isGranted {
      // Show something here to show that access is granted
    } else {
      self.showCalendarError()
    }
  }

  private func showCalendarError() {
    self.showError(title: kCalendarPermissions, message: kCalendarAccess)
  }

  // MARK: - Use Case: Retrieve availability for user
  func retrieveAvailability() {
    showHUD()
    var request = RootedContent.RetrieveAvailability.Request()
    request.availabilityManagerDelegate = self
    interactor?.retrieveAvailability(request: request)
  }

  func didFinishLoading(_ manager: Any?, objects: [AvailabilityContextWrapper]) {
    loadTable(for: currentDate)
  }

  func didFailToLoad(_ manager: Any?, error: Error) {
      showError(title: "Error", message: error.localizedDescription)
    }

  // MARK: - Use Case: Show a table where a user could view current availability as well as create availability
  private func loadTable(for date: Date, objects: [AvailabilityContextWrapper] = [AvailabilityContextWrapper]()) {
    form.removeAll()
    form
      +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                             header: "Edit Availability",
                             footer: "") {
                              $0.tag = "textfields"
                              $0.addButtonProvider = { section in
                                return ButtonRow(){
                                  $0.title = "Add Availability"
                                  }.cellUpdate { cell, row in
                                    cell.textLabel?.textAlignment = .left
                                }
                              }

                              $0.multivaluedRowToInsertAt = { index in
                                return SplitRow<TimeRow,TimeRow>() {
                                  $0.rowLeftPercentage = 0.5
                                  $0.rowLeft = TimeRow(){
                                      $0.title = "Start Time"
                                  }

                                  $0.rowRight = TimeRow(){
                                      $0.title = "End Time"
                                  }
                                }.onChange({ (splitRow) in

                                  // MARK: - Use Case: Save availability for user
                                  print("Index of row inserted is \(String(describing: splitRow.indexPath?.row))")
                                  let tagForAvailability = "availability_date_\(String(describing: splitRow.indexPath!.row))_\(date.toString(.normal).trimmingCharacters(in: .whitespacesAndNewlines))"
                                  if
                                    let startTimeRow = splitRow.rowLeft,
                                    let endTimeRow = splitRow.rowRight,
                                    let startTimeRowValue = startTimeRow.value,
                                    let endTimeRowValue = endTimeRow.value {

                                    let availabilityDict: [String: Any] = [
                                      "id": RanStringGen(length: 10).returnString(),
                                      "name": tagForAvailability,
                                      "availability_dates": [
                                          "month": date.toString(.month),
                                          "endMonth": date.toString(.month),
                                          "start_time": startTimeRowValue.toString(.timeOnly),
                                          "end_time": endTimeRowValue.toString(.timeOnly)
                                        ]
                                    ]

                                    guard let availability = Availability(JSON: availabilityDict) else {
                                      print("Error creating availability object from dictionary")
                                      return
                                    }

                                    var request = RootedContent.SaveAvailability.Request()
                                    request.availability = availability
                                    self.interactor?.saveAvailability(request: request)
                                  }
                                })
                              }
    }
  }

  func onSuccessfulAvailabilitySave(viewModel: RootedContent.SaveAvailability.ViewModel)  {
    guard let availability = viewModel.availability else { return }
    print("Availability was saved")
  }

  func handleError(viewModel: RootedContent.DisplayError.ViewModel) {
//    displayFailure(with: viewModel.errorTitle, and: viewModel.errorMessage, afterAnimating: sendToFriendsButton)
  }

  // MARK: - IBActions
  // MARK: - Use Case: Save availability and send it to friends
  @IBAction func sendToFriends(_ sender: UIButton) {
    BranchEvent.customEvent(withName: kBranchUserStartedSharingAvailability)
    sendToFriendsAction()
  }

  private func sendToFriendsAction() {
    /*
    startAnimating(shareAvailabilityButton) {

      // Create empty array of dates
      var availabilityDates = [MeetingDateClass]()

      // Check if availability times exist
      for section in self.sections {
        // For each wrapper we want to create a meeting date class object and insert it into an array
        let dateDict = [
          "start_date": section.fromDate?.toString() ?? "",
          "end_date": section.toDate?.toString() ?? "",
          "time_zone": Zones.current.toTimezone().identifier
        ]
        guard let meetingDateClass = MeetingDateClass(JSON: dateDict) else { return }
        availabilityDates.append(meetingDateClass)
      }

      // Add availabile_dates to model builder
      self.modelBuilder = self.modelBuilder.add(key: "available_dates", value: availabilityDates)

      guard let _ = self.modelBuilder.retrieve(forKey: "available_dates") as? [MeetingDateClass], let availability = self.modelBuilder.generateModel().availability else {

        self.displayFailure(with: "Oops!", and: "Please fill out the entire form to create an invite.", afterAnimating: self.shareAvailabilityButton)
        return
      }

      if let contextwrapper = self.contextWrapper, let managedobject = contextwrapper.managedObject, let jsonstring = availability.toJSONString() {

        // Update property of Core data object
        managedobject.setValue(jsonstring, forKey: "object")

        self.sendResponse(availability: availability, completion: { (success, e) in
          if let e = e {
            self.displayFailure(with: "Oops!", and: e.localizedDescription, afterAnimating: self.shareAvailabilityButton)
          } else {
            self.displaySuccess(afterAnimating: self.shareAvailabilityButton, completion: {
              self.postNotification(withName: kNotificationMyInvitesReload, completion: {
                self.dismiss(animated: true, completion: nil)
              })
            })
          }
        })

      } else {

        self.contentManager.insert(availability, completion: { (success, error) in
          if let err = error {
            self.displayFailure(with: "Oops!", and: err.localizedDescription, afterAnimating: self.shareAvailabilityButton)
          } else {
            if success {
              self.sendResponse(availability: availability, completion: { (success, e) in
                if let e = e {
                  self.displayFailure(with: "Oops!", and: e.localizedDescription, afterAnimating: self.shareAvailabilityButton)
                } else {
                  self.displaySuccess(afterAnimating: self.shareAvailabilityButton, completion: {
                    self.postNotification(withName: kNotificationMyInvitesReload, completion: {
                      self.dismiss(animated: true, completion: nil)
                    })
                  })
                }
              })
            } else {
              self.displayFailure(with: "Oops!", and: "Something went wrong. Please try again.", afterAnimating: self.shareAvailabilityButton)
            }
          }
        })

      }
    }*/
  }

  private func sendResponse(availability: Availability, completion: @escaping (Bool, Error?) -> Void) {
    guard let message = EngagementFactory.AvailabilityFactory.availabilityToMessage(availability) else { return completion(false, RError.customError("Something went wrong while sending message. Please try again.")) }
    self.conversationManager.send(message: message, of: .insert, completion)
  }

  // MARK: - Use Case: Cancel action
  @IBAction func cancelAction(_ sender: UIButton) {
    dismissView()
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      if let _ = tableView.cellForRow(at: indexPath) as? SplitRowCell<TimeRow, TimeRow> {

        var oldTempAvailabilityDictionary = self.tempAvailability

        print("Old availability stuff")
        print(oldTempAvailabilityDictionary)

        print("Index of row deleted is \(String(describing: indexPath.row))")
        let tagForAvailability = "availability_date_\(String(describing: indexPath.row))_\(currentDate.toString(.normal).trimmingCharacters(in: .whitespacesAndNewlines))"

        oldTempAvailabilityDictionary[tagForAvailability] = nil

        // Update tags for correct row
        self.tempAvailability.removeAll()

        var index = 0
        for oldTempAvailabilityKey in oldTempAvailabilityDictionary.keys {
          if let oldTempAvailability = oldTempAvailabilityDictionary[oldTempAvailabilityKey] as? [String: Any] {
            let newTagForAvailability = "availability_date_\(String(describing: index))_\(currentDate.toString(.normal).trimmingCharacters(in: .whitespacesAndNewlines))"
            if let oldTempAvailabilityDates = oldTempAvailability["availability_dates"] {
              self.tempAvailability[newTagForAvailability] = [
                "name": newTagForAvailability,
                "availability_dates": oldTempAvailabilityDates
              ]
            } else {
              self.tempAvailability[newTagForAvailability] = [
                "name": newTagForAvailability,
              ]
            }
            index += 1
          }
        }
        print("New availability stuff")
        print(self.tempAvailability)
      }
    }
    super.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
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
    guard (date.toString(.normal) == currentDate.toString(.normal) || !date.timeIntervalSince(currentDate).isLess(than: 0)) else {
      reset(to: currentDate, at: monthPosition, showError: false)
      return
    }

    guard date.timeIntervalSince(currentDate.addingTimeInterval(60 * 60 * 24 * 7)).isLess(than: 0) else {
      reset(to: currentDate, at: monthPosition, showError: true)
      return
    }

//    if !sections.keys.contains(date.toString(.normal)) {
//      sections[date.toString(.normal)] = []
//    }

    if monthPosition == .next || monthPosition == .previous {
      calendar.setCurrentPage(date, animated: true)
    }

    loadTable(for: date)
  }

  func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
//    print("\(self.dateFormatter.string(from: calendar.currentPage))")
  }

  func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
//    return self.sections[date.toString(.normal)]?.count ?? 0
    return 0
  }
}
