//
//  DateRangePickerInlineRow.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/9/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit
import Eureka

open class DateRangeCompletionWrapper: Equatable {
  var month: String?
  var fromDate: Date?
  var toDate: Date?

  init(month: String, from: Date, to: Date) {
    self.month = month
    fromDate = from
    toDate = to
  }

  public static func == (lhs: DateRangeCompletionWrapper, rhs: DateRangeCompletionWrapper) -> Bool {
    return lhs.fromDate == rhs.fromDate && lhs.toDate == rhs.toDate
  }

  var readableString: String? {
    guard let fromdate = fromDate, let todate = toDate else { return nil }
    return "\(fromdate.toString(.timeOnly)) to \(todate.toString(.timeOnly))"
  }
}

protocol DateRangeDelegate: class {
  func selectRange(_ rangeVC: UIViewController, from: Date, to: Date)
}

final class DateRangePickerInlineRow: OptionsRow<PushSelectorCell<DateRangeCompletionWrapper>>, PresenterRowType, RowType {

  typealias PresentedControllerType = DateRangeVC

  /// Defines how the view controller will be presented, pushed, etc.
  public var presentationMode: PresentationMode<PresentedControllerType>?

  /// Will be called before the presentation occurs.
  public var onPresentCallback: ((UIViewController, PresentedControllerType) -> Void)?

  public required init(tag: String?) {
    super.init(tag: tag)
    presentationMode = .show(controllerProvider: ControllerProvider.callback { return DateRangeVC(){ _ in } }, onDismiss: { vc in _ = vc.navigationController?.popViewController(animated: true) })
  }

  /**
   Extends `didSelect` method
   */
  public override func customDidSelect() {
    super.customDidSelect()
    guard let presentationMode = presentationMode, !isDisabled else { return }
    if let controller = presentationMode.makeController() {
      controller.row = self
      controller.title = selectorTitle ?? controller.title
      onPresentCallback?(cell.formViewController()!, controller)
      presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
    } else {
      presentationMode.present(nil, row: self, presentingController: self.cell.formViewController()!)
    }
  }

  /**
   Prepares the pushed row setting its title and completion callback.
   */
  public override func prepare(for segue: UIStoryboardSegue) {
    super.prepare(for: segue)
    guard let rowVC = segue.destination as? PresentedControllerType else { return }
    rowVC.title = selectorTitle ?? rowVC.title
    rowVC.onDismissCallback = presentationMode?.onDismissCallback ?? rowVC.onDismissCallback
    onPresentCallback?(cell.formViewController()!, rowVC)
    rowVC.row = self
  }

}

class DateRangeVC: UIViewController, TypedRowControllerType {

  @IBOutlet private weak var selectRangeButton: UIButton!
  @IBOutlet private weak var selectFromRangeButton: UIButton!
  @IBOutlet private weak var selectToRangeButton: UIButton!
  @IBOutlet private weak var cancelButton: UIButton!

  public var row: RowOf<DateRangeCompletionWrapper>!
  public var onDismissCallback: ((UIViewController) -> ())?

  // The managing container for the control
  private var container: UIView?

  private var month: String?
  private var fromDate: Date?
  private var fromDatePicker: UIDatePicker?
  private var toDate: Date?
  private var toDatePicker: UIDatePicker?

  private var dateRange: DateRangeCompletionWrapper? {
    if let month = self.month, let fromdate = self.fromDate, let todate = self.toDate {
      return DateRangeCompletionWrapper(month: month, from: fromdate, to: todate)
    }
    return nil
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: "DateRangeVC", bundle: nil)
  }

  convenience public init(_ callback: ((UIViewController) -> ())?){
    self.init(nibName: nil, bundle: nil)
    onDismissCallback = callback
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    selectRangeButton.applyCornerRadius(0.05)
    selectRangeButton.backgroundColor = .gradientColor2

    selectFromRangeButton.applyCornerRadius(0.05)
    selectFromRangeButton.applyBorder(withColor: .lightGray, andThickness: 1.0)

    selectToRangeButton.applyCornerRadius(0.05)
    selectToRangeButton.applyBorder(withColor: .lightGray, andThickness: 1.0)

    if let title = row.tag, title.components(separatedBy: "_").count > 0 {
      let date = title.components(separatedBy: "_")[3]
      self.month = date
      self.updateNavigationBar(title: date)
    }
    updateBackButton(color: .darkText)
    hideNavigationBarHairline()

  }

  // MARK: - Picker view methods
  @objc
  func doneFromPicker(_ sender: UIButton) {
    fromDate = fromDatePicker!.date
    selectFromRangeButton.setTitle(fromDate!.toString(.timeOnly), for: .normal)
    self.container?.removeFromSuperview()
    self.container = nil
  }

  @objc
  func doneToPicker(_ sender: UIDatePicker) {
    toDate = toDatePicker!.date
    selectToRangeButton.setTitle(toDate!.toString(.timeOnly), for: .normal)
    self.container?.removeFromSuperview()
    self.container = nil
  }

  @objc func cancelPicker() {
    self.container?.removeFromSuperview()
    self.container = nil
  }

  @IBAction func selectRange(_ sender: UIButton) {
    if let daterange = dateRange, daterange.readableString != nil {
      row.value = daterange
      self.onDismissCallback?(self)
    } else {
      RRLogger.log(message: "There was an error", owner: self)
    }
  }

  @IBAction func selectFromRange(_ sender: UIButton) {
    let containerView = UIView.init(frame: self.view.bounds)
    // Create UIDatePicker
    let picker = UIDatePicker(frame: CGRect(x: .zero, y: containerView.frame.maxY - 200, width: containerView.bounds.width, height: 200))
    picker.backgroundColor = .white
    picker.datePickerMode = .time
    picker.minuteInterval = 15
    picker.accessibilityIdentifier = "from_range"

    // Create UIToolBar
    let toolBar = UIToolbar(frame: CGRect(x: .zero, y: picker.frame.origin.y - 44, width: containerView.bounds.width, height: 44))
    toolBar.barStyle = UIBarStyle.default
    toolBar.isTranslucent = false
    toolBar.tintColor = .darkText
    toolBar.sizeToFit()

    // Create `Done` button for toolbar
    let doneButton = UIButton(type: .system)
    doneButton.frame.size.width = 100
    doneButton.setTitle("Done", for: .normal)
    doneButton.addTarget(self, action: #selector(self.doneFromPicker(_:)), for: .touchUpInside)
    doneButton.contentHorizontalAlignment = .center

    let doneBarButton = UIBarButtonItem(customView: doneButton)

    // Add space between `Done` button and `Cancel` button
    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)

    // Create `Cancel` button for toolbar
    let cancelButton = UIButton(type: .system)
    cancelButton.frame.size.width = 100
    cancelButton.setTitle("Cancel", for: .normal)
    cancelButton.contentHorizontalAlignment = .center
    cancelButton.addTarget(self, action: #selector(self.cancelPicker), for: .touchUpInside)

    let cancelBarButton = UIBarButtonItem(customView: cancelButton)

    // Set buttons as items within toolbar
    toolBar.setItems([cancelBarButton, spaceButton, doneBarButton], animated: false)
    toolBar.isUserInteractionEnabled = true

    // Add views to container view
    DispatchQueue.main.async {
      containerView.addSubview(toolBar)
      containerView.addSubview(picker)
      self.view.addSubview(containerView)
      self.view.bringSubviewToFront(containerView)
    }

    // Set container view now that it is ready
    fromDatePicker = picker
    container = containerView
  }

  @IBAction func selectToRange(_ sender: UIButton) {
    let containerView = UIView.init(frame: self.view.bounds)
    // Create UIDatePicker
    let picker = UIDatePicker(frame: CGRect(x: .zero, y: containerView.frame.maxY - 200, width: containerView.bounds.width, height: 200))
    picker.backgroundColor = .white
    picker.datePickerMode = .time
    picker.minuteInterval = 15
    picker.accessibilityIdentifier = "to_range"

    // Create UIToolBar
    let toolBar = UIToolbar(frame: CGRect(x: .zero, y: picker.frame.origin.y - 44, width: containerView.bounds.width, height: 44))
    toolBar.barStyle = UIBarStyle.default
    toolBar.isTranslucent = false
    toolBar.tintColor = .darkText
    toolBar.sizeToFit()

    // Create `Done` button for toolbar
    let doneButton = UIButton(type: .system)
    doneButton.frame.size.width = 100
    doneButton.setTitle("Done", for: .normal)
    doneButton.addTarget(self, action: #selector(self.doneToPicker(_:)), for: .touchUpInside)
    doneButton.contentHorizontalAlignment = .center

    let doneBarButton = UIBarButtonItem(customView: doneButton)

    // Add space between `Done` button and `Cancel` button
    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)

    // Create `Cancel` button for toolbar
    let cancelButton = UIButton(type: .system)
    cancelButton.frame.size.width = 100
    cancelButton.setTitle("Cancel", for: .normal)
    cancelButton.contentHorizontalAlignment = .center
    cancelButton.addTarget(self, action: #selector(self.cancelPicker), for: .touchUpInside)

    let cancelBarButton = UIBarButtonItem(customView: cancelButton)

    // Set buttons as items within toolbar
    toolBar.setItems([cancelBarButton, spaceButton, doneBarButton], animated: false)
    toolBar.isUserInteractionEnabled = true

    // Add views to container view
    DispatchQueue.main.async {
      containerView.addSubview(toolBar)
      containerView.addSubview(picker)
      self.view.addSubview(containerView)
      self.view.bringSubviewToFront(containerView)
    }

    // Set container view now that it is ready
    toDatePicker = picker
    container = containerView
  }

  @IBAction func cancelAction(_ sender: UIButton) {
    self.onDismissCallback?(self)
  }

}

// MARK: - DateTimePickerDelegate
extension DateRangeVC: DateTimePickerDelegate {
  func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {

  }
}
