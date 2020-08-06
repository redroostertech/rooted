//
//  ViewCalendarViewController.swift
//  Rooted
//
//  Created by Michael Westbrooks on 7/17/20.
//  Copyright (c) 2020 RedRooster Technologies Inc.. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import CalendarKit
import DateToolsSwift

protocol ViewCalendarDisplayLogic: class { }

class ViewCalendarViewController: DayViewController, ViewCalendarDisplayLogic {

  var interactor: ViewCalendarBusinessLogic?
//  var router: (NSObjectProtocol & ViewCalendarRoutingLogic & ViewCalendarDataPassing)?

  // MARK: - Lifecycle methods
  static func setupViewController() -> ViewCalendarViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "ViewCalendarViewController") as! ViewCalendarViewController
    return viewController
  }

  // MARK: Object lifecycle
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  // MARK: Setup
  private func setup() {
    let viewController = self
    let interactor = ViewCalendarInteractor()
    let presenter = ViewCalendarPresenter()
//    let router = ViewCalendarRouter()
    viewController.interactor = interactor
//    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
//    router.viewController = viewController
//    router.dataStore = interactor
  }
  
  // MARK: View lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    dayView.autoScrollToFirstEvent = true
  }

  override func eventsForDate(_ date: Date) -> [EventDescriptor] {
    var events = [Event]()

    let event = Event()
    event.startDate = .today()
    event.endDate = .tomorrow()
    event.text = "Test event"
    event.color = .cyan
    event.textColor = .brown

    events.append(event)

    return events
  }

  override func dayViewDidSelectEventView(_ eventView: EventView) {
    print("Event has been selected, navigate to details")
  }

  override func dayViewDidLongPressEventView(_ eventView: EventView) {
    print("Event has been long pressed")
  }

  override func dayView(dayView: DayView, didMoveTo date: Date) {
    print("DayView = \(dayView) did move to = \(date)")
  }

  override func dayView(dayView: DayView, willMoveTo date: Date) {
    print("DayVew = \(dayView) will move to = \(date)")
  }
}
