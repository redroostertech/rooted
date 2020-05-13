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

class AvailabilityViewController: FormMessagesAppViewController, RootedContentDisplayLogic {

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

//  private var contentManager = RootedContentInteractor(managerType: .send)
//  private var dataManager = AvailabilityManager()

  private var contextWrapper: AvailabilityContextWrapper?

  private var datesOfAvailability: [NSManagedObject] = []

  // Model
  private var modelBuilder = AvailabilityModelBuilder().start()
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
//    dataManager.delegate = self
//    dataManager.loadData()
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

    /*
    contentManager.checkCalendarPermissions { success in
      if success {
        self.shareAvailabilityButton.isEnabled = true
      } else {
        self.shareAvailabilityButton.isEnabled = false
        self.showError(title: kCalendarPermissions, message: kCalendarAccess)
      }
    }
     */
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

  private func loadTable(for date: Date) {
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

                              // If we select on a day and it already exists, then append the rows
                              if self.sections.count > 0 {
                                for dateRange in self.sections {
                                  let dateRangeIndex = self.sections.index(of: dateRange)
                                  $0.append(
                                    DateRangePickerInlineRow( "availability_date_\(String(describing: dateRangeIndex))_\(date.toString(.normal))") {
                                      $0.title = dateRange.readableString ?? "Select Availability Time Range"
                                      $0.cell.detailTextLabel?.textColor = .clear
                                      $0.value = dateRange
                                    }
                                  )
                                }
                              } else {
                                $0.multivaluedRowToInsertAt = { index in
                                  return DateRangePickerInlineRow( "availability_date_\(index)_\(self.calendar.selectedDate!.toString(.normal))") {
                                    $0.title = "Select Availability Time Range"
                                    $0.cell.detailTextLabel?.textColor = .clear
                                    }.onChange { row in
                                      guard let value = row.value else { return }
                                      row.title = value.readableString ?? "Select Availability Time Range"
                                      row.updateCell()

                                      self.sections.append(value)
                                  }
                                }
                              }
    }
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
      if let cell = tableView.cellForRow(at: indexPath) as? PushSelectorCell<DateRangeCompletionWrapper>, let title = cell.row.tag, title.components(separatedBy: "_").count > 0 {
        let date = title.components(separatedBy: "_")[3]
//        if var sectionsArrayValues = self.sections[date], sectionsArrayValues.indices.contains(indexPath.row) {
//          sectionsArrayValues.remove(at: indexPath.row)
//          self.sections[date] = sectionsArrayValues
//        }
      }
    }
    super.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
  }
}

// MARK: - AvailabilityDelegate
extension AvailabilityViewController: AvailabilityDelegate {
  func willDelete(_ manager: Any?) {
    // Will remove invite
  }

  func didDelete(_ manager: Any?, objects: AvailabilityContextWrapper) {
    // Invite was deleted
  }

  func didFinishLoading(_ manager: Any?, objects: [AvailabilityContextWrapper]) {

    if let firstContextWrapper = objects.first {
      contextWrapper = firstContextWrapper
    }

    for object in objects.uniqueElementsInOrder {
      guard let availability = object.object, let dates = availability.availabilityDates else { return }
      for date in dates {
        guard let startdate = date.startDate?.toDate()?.date, let enddate = date.endDate?.toDate()?.date else { return }
//        let dateRange = DateRangeCompletionWrapper(from: startdate, to: enddate)
//        let dateRange = DateRangeCompletionWrapper(month: <#T##String#>, from: <#T##Date#>, to: <#T##Date#>)
//        if var ranges = sections[startdate.toString(.normal)] {
//          ranges.append(dateRange)
//          sections[startdate.toString(.normal)] = ranges
//        } else {
//          sections[startdate.toString(.normal)] = [dateRange]
//        }
      }
    }

    loadTable(for: currentDate)
    
  }

  func didFailToLoad(_ manager: Any?, error: Error) {
    showError(title: "Error", message: error.localizedDescription)
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
