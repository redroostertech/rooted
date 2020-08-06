//
//  ViewParticipantsViewController.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 6/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages
import Branch

class ViewParticipantsViewController: BaseAppViewController, RootedContentDisplayLogic {

  // MARK: - IBOutlets
  @IBOutlet private weak var mainTable: UITableView!
  @IBOutlet private weak var backButton: UIButton!
  @IBOutlet private weak var actionsContainerView: UIView!

  // MARK: - Private Properties
   private var interactor: RootedContentBusinessLogic?
   private var conversationManager = ConversationManager.shared
   private var shouldSendRespone = false
   private var meeting: RootedCellViewModel?

  // MARK: - Lifecycle methods
  static func setupViewController(meeting: RootedCellViewModel) -> ViewParticipantsViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "ViewParticipantsViewController") as! ViewParticipantsViewController
    viewController.meeting = meeting
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
    checkCalendarPermissions()
  }

  // MARK: - Use Case: Setup the UI for the view
  private func setupUI() {
    mainTable.delegate = self
    mainTable.dataSource = self
    mainTable.separatorStyle = .none
    backButton.applyCornerRadius()
    view.bringSubviewToFront(actionsContainerView)
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

  // MARK: - Use Case: Check if user is logged in and if not, show login screen
  func presentPhoneLoginViewController() {
    dismissHUD()
    showError(title: "Login In", message: "You are not logged in. Please do so and try again.", style: .alert, defaultButtonText: "OK")
  }

  // MARK: - Use Case: On Successful login resume setting up the view controller
  func onSucessfulLogin(_ sender: PhoneLoginViewController, uid: String?) {
    sender.dismiss()
  }

  // MARK: - Use Case: On failed login attempt, resume setting up the view controller
  func handleFailedLogin(_ sender: PhoneLoginViewController, reason: String) {
    // Don't do anything yet
  }

  // MARK: - IBActions
  // MARK: - Use Case: Accept the meeting, save it locally, and add it to your calendar
  @IBAction func back(_ sender: UIButton) {
    dismissView()
  }
}

// Reusable components
extension ViewParticipantsViewController {
  // MARK: - Use Case: Show ProgressHUD
  func showHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.show()
    }
  }

  // MARK: - Use Case: Dismiss ProgressHUD
  func dismissHUD() {
    DispatchQueue.main.async {
      self.progressHUD?.dismiss()
    }
  }
}

// MARK: - UITableViewDataSource
extension ViewParticipantsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0: return "Invited"
    case 1: return "Accepted"
    case 2: return "Declined"
    default: return ""
    }
  }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      switch section {
      case 0: return meeting?.data?.meetingInvitePhoneNumbers?.count ?? 0
      case 1: return meeting?.data?.participants?.count ?? 0
      case 2: return meeting?.data?.declinedParticipants?.count ?? 0
      default: return 0
      }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      guard let mtng = meeting?.data else { return UITableViewCell() }
      switch indexPath.section {
      case 0:
        guard let meetingParticipants = mtng.meetingInvitePhoneNumbers else { return UITableViewCell() }
        let meetingParticipant = meetingParticipants[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .darkText
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.textColor = .lightGray

        cell.textLabel?.text = meetingParticipant.firstName ?? ""
        cell.detailTextLabel?.text = meetingParticipant.phone ?? ""

        return cell
      case 1:
        guard let meetingParticipants = mtng.participants else { return UITableViewCell() }
        let meetingParticipant = meetingParticipants[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .darkText
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.textColor = .lightGray

        cell.textLabel?.text = meetingParticipant.fullName ?? ""
        if let meetingOwner = mtng.ownerId {

          if meetingOwner == meetingParticipant.uid ?? "" {
            cell.textLabel?.text! += "(Organizer)"
          }

          if let currentUserId = SessionManager.shared.currentUser?.uid, meetingParticipant.uid ?? "" != currentUserId {
            cell.detailTextLabel?.text = meetingParticipant.email ?? ""
          } else {
            cell.detailTextLabel?.text = "You"
          }
        }
        return cell
      case 2:
        guard let meetingParticipants = mtng.declinedParticipants else { return UITableViewCell() }
        let meetingParticipant = meetingParticipants[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .darkText
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.textColor = .lightGray

        cell.textLabel?.text = meetingParticipant.fullName ?? ""
        if let meetingOwner = mtng.ownerId {

          if meetingOwner == meetingParticipant.uid ?? "" {
            cell.textLabel?.text! += "(Organizer)"
          }

          if let currentUserId = SessionManager.shared.currentUser?.uid, meetingParticipant.uid ?? "" != currentUserId {
            cell.detailTextLabel?.text = meetingParticipant.email ?? ""
          } else {
            cell.detailTextLabel?.text = "You"
          }
        }
        return cell
      default:
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .darkText
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.textColor = .lightGray
        cell.textLabel?.text = "No data available"
        return cell
      }

    }
}
