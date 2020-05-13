import UIKit
import Messages

class InfoViewController: BaseAppViewController, RootedContentDisplayLogic {

  // MARK: - IBOutlets
  @IBOutlet private weak var versionLabel: UILabel!
  @IBOutlet private weak var closeButton: UIButton!
  @IBOutlet private weak var grantAccessButton: UIButton!

  // MARK: - Private Properties
  private var interactor: RootedContentBusinessLogic?
  private var appVersion: String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
  }

  // MARK: - Lifecycle methods
  static func setupViewController() -> InfoViewController {
    let storyboard = UIStoryboard(name: kStoryboardMain, bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "InfoViewController") as! InfoViewController
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

  // MARK: - Use Case: Setup the UI for the view
  private func setupUI() {
    closeButton.applyCornerRadius()
    closeButton.applyPrimaryGradient()
    grantAccessButton.applyCornerRadius()
    versionLabel.text = "Version \(appVersion)"
  }

  @IBAction func closeAction(_ sender: UIButton) {
    dismissView()
  }

  @IBAction func grantAccessAction(_ sender: UIButton) {
    self.showError(title: "Calendar Permissions", message: "In order to use Rooted, we need to have permission to access your calendar. To update settings, please go to\nSETTINGS > PRIVACY > CALENDAR > ROOTED")
  }
}

// Reusable components
extension InfoViewController {
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

  // MARK: - Use Case: Check if app has access to calendar permissions
  func checkCalendarPermissions() {
    let request = RootedContent.CheckCalendarPermissions.Request()
    interactor?.checkCalendarPermissions(request: request)
  }

  func handleCalendarPermissions(viewModel: RootedContent.CheckCalendarPermissions.ViewModel) {
    RRLogger.log(message: "Calendar Permissions: \(viewModel.isGranted)", owner: self)
    if viewModel.isGranted {
      self.grantAccessButton.setTitle("ACCESS GRANTED", for: .normal)
      self.grantAccessButton.applyPrimaryGradient()
    } else {
      self.showCalendarError()
      self.grantAccessButton.setTitleColor(.gradientColor1, for: .normal)
      self.grantAccessButton.setTitle("GRANT ACCESS NOW", for: .normal)
      self.grantAccessButton.backgroundColor = .white
    }
  }

  private func showCalendarError() {
     self.showError(title: kCalendarPermissions, message: kCalendarAccess)
  }

  // MARK: - Use Case: As a business, we want to limit access to creating more than (n) meetings based on account type
  func checkMaximumMeetingsReached() {
    let request = RootedContent.CheckMaximumMeetingsReached.Request()
    interactor?.checkMaximumMeetingsReached(request: request)
  }

  func handleMaximumLimitReached(viewModel: RootedContent.CheckMaximumMeetingsReached.ViewModel) {
    if viewModel.isMaximumumReached {
      self.showError(title: viewModel.errorTitle, message: viewModel.errorMessage)
    } else {
      // Do something is maximum is not reached
    }
  }
}
