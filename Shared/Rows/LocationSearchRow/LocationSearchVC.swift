import UIKit
import Messages
import MapKit
import Eureka

protocol LocationSearchDelegate: class {
  func selectLocation(_ searchVC: LocationSearchVC, location: RLocation?)
}

final class LocationSearchRow: OptionsRow<PushSelectorCell<MKLocalSearchCompletionWrapper>>, PresenterRowType, RowType {

  typealias PresentedControllerType = LocationSearchVC

  /// Defines how the view controller will be presented, pushed, etc.
  public var presentationMode: PresentationMode<PresentedControllerType>?

  /// Will be called before the presentation occurs.
  public var onPresentCallback: ((UIViewController, PresentedControllerType) -> Void)?

  public required init(tag: String?) {
    super.init(tag: tag)
    presentationMode = .show(controllerProvider: ControllerProvider.callback { return LocationSearchVC(){ _ in } }, onDismiss: { vc in _ =
      vc.navigationController?.popViewController(animated: true)
      vc.dismiss(animated: true, completion: nil)
    })
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
      presentationMode.present(controller,
                               row: self,
                               presentingController: cell.formViewController()!)
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

class LocationSearchVC: UIViewController, TypedRowControllerType {

  public var row: RowOf<MKLocalSearchCompletionWrapper>!
  public var onDismissCallback: ((UIViewController) -> ())?

  lazy var searchResultsTableView: UITableView = { [unowned self] in
    let tableView = UITableView(frame: CGRect(x: .zero, y: 56, width: self.view.bounds.width, height: self.view.bounds.height - 56))
    if self.navigationController != nil {
      tableView.frame = CGRect(x: .zero,
                               y: self.navigationController!.navigationBar.frame.height + 56,
                               width: self.view.bounds.width,
                               height: self.view.bounds.height - (self.navigationController!.navigationBar.frame.height + 56))
    } else {
      tableView.frame = CGRect(x: .zero, y: 56, width: self.view.bounds.width, height: self.view.bounds.height - 56)
    }
    tableView.separatorStyle = .none
    tableView.estimatedRowHeight = UITableView.automaticDimension
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return tableView
  }()

  lazy var searchFormField: UISearchBar = { [unowned self] in
    let searchBar = UISearchBar()
    if self.navigationController != nil {
      searchBar.frame = CGRect(x: .zero, y: self.navigationController!.navigationBar.frame.height, width: self.view.bounds.width, height: 56)
    } else {
      searchBar.frame = CGRect(x: .zero, y: .zero, width: self.view.bounds.width, height: 56)
    }
    searchBar.backgroundColor = .white
    searchBar.setPlaceholderTextColorTo(color: .darkText)
    searchBar.setMagnifyingGlassColorTo(color: .darkText)
    return searchBar
  }()

  var emptyDataSource: EmptyDataSetSource? {
    didSet {
      guard let emptydatasource = self.emptyDataSource else { return }
      searchResultsTableView.emptyDataSetSource = emptydatasource
    }
  }

  private var locationManager = CLLocationManager()
  private var searchCompleter = MKLocalSearchCompleter()
  private var searchResults = [MKLocalSearchCompletionWrapper]()
  private var initialAuthSet = false

  public var rowValue: MKLocalSearchCompletionWrapper? {
    didSet {
      RRLogger.log(message: "Row value was set", owner: self)
      self.onDismissCallback?(self)
    }
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)
  }

  convenience public init(_ callback: ((UIViewController) -> ())?){
    self.init(nibName: nil, bundle: nil)
    onDismissCallback = callback
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupView()

    locationManager.delegate = self

    switch CLLocationManager.authorizationStatus() {
    case .denied, .restricted:
      self.initialAuthSet = true
      let okAction = UIAlertAction(title: "OK", style: .default, handler: { action in
        self.onDismissCallback?(self)
      })
      HUDFactory.displayAlert(with: "Location Permissions", message: "To add a location to this meeting, please go to your settings and allow access to your location.", and: [okAction], on: self)
    case .notDetermined:
      self.initialAuthSet = true
      self.locationManager.requestWhenInUseAuthorization()
    default:
      self.initialAuthSet = true
      break
    }
  }

  private func setupView() {
    view.addSubview(searchResultsTableView)
    searchResultsTableView.delegate = self
    searchResultsTableView.dataSource = self
    searchResultsTableView.emptyDataSetView { view in
      view.titleLabelString(NSAttributedString(string: "Find a location to meet at"))
        .image(UIImage(named: "map-folded-outlined-paper-sm"))
        .dataSetBackgroundColor(UIColor.white)
        .shouldDisplay(true)
        .shouldFadeIn(true)
        .isTouchAllowed(true)
        .isScrollAllowed(true)
        .didTapDataButton {
          // Do something
        }
        .didTapContentView {
          // Do something
      }
    }


    view.addSubview(searchFormField)
    searchFormField.delegate = self

    searchCompleter.delegate = self
  }
}

// MARK: - UITableViewDataSource
extension LocationSearchVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        cell.backgroundColor = .white
        cell.textLabel?.textColor = .darkText
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.textColor = .white

        cell.textLabel?.text = searchResult.suggestionString
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let searchResult = searchResults[indexPath.row]
        row.value = searchResult
        onDismissCallback?(self)
    }
}


// MARK: - UISearchBarDelegate
extension LocationSearchVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//    searchCompleter.queryFragment = searchText
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchCompleter.queryFragment = searchBar.text ?? ""
    self.view.endEditing(true)
  }
}

// MARK: - MKLocalSearchCompleterDelegate
extension LocationSearchVC: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    searchResults = completer.results.map({ (localSearchCompletion) -> MKLocalSearchCompletionWrapper in
      return MKLocalSearchCompletionWrapper(localSearchCompletion: localSearchCompletion)
    })
    searchResultsTableView.reloadData()
  }

  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    // handle error
  }
}

// MARK: - CLLocationManager delegate
extension LocationSearchVC: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if initialAuthSet {
      switch status {
      case .denied, .restricted:
        onDismissCallback?(self)
      default:
        break
      }
    }
  }
}

open class MKLocalSearchCompletionWrapper: SuggestionValue {

  private var mkLocalSearchCompletion: MKLocalSearchCompletion?
  var rLocation: RLocation?

  public var suggestionString: String {
    return "\(mkLocalSearchCompletion?.title ?? "") at \(mkLocalSearchCompletion?.subtitle ?? "")"
  }

  init(localSearchCompletion: MKLocalSearchCompletion) {

    mkLocalSearchCompletion = localSearchCompletion
    let searchRequest = MKLocalSearch.Request(completion: localSearchCompletion)
    searchRequest.naturalLanguageQuery = suggestionString

    let search = MKLocalSearch(request: searchRequest)
    search.start { (response, error) in

      print("Response items")
      print(response?.mapItems)

      print(error?.localizedDescription)

      guard let mapItem = response?.mapItems[0] else {
        RRLogger.log(message: "Map item couldn't be created", owner: self)
        return
      }

      guard let location = self.generateRLocation(from: mapItem) else {
        RRLogger.log(message: "RLocation couldn't be created.", owner: self)
        return
      }

      // Add MKMapItem to RLocation
      location.mapItem = mapItem

      self.rLocation = location
    }
  }

  required convenience public init?(string stringValue: String) {
    return nil
  }

  private func generateRLocation(from mapItem: MKMapItem) -> RLocation? {
    var dict = [String: Any]()

    var address1: String = ""
    if let subthoroughfare = mapItem.placemark.subThoroughfare {
      address1 += subthoroughfare
    }

    if let thoroughfare = mapItem.placemark.thoroughfare {
      address1 += " "
      address1 += thoroughfare
    }

    dict["address_line_1"] = address1

    if let name = mapItem.name {
      dict["name"] = name
    }

    if let city = mapItem.placemark.locality {
      dict["address_city"] = city
    }

    if let state =  mapItem.placemark.administrativeArea {
      dict["address_state"] = state
    }

    if let state_sh = mapItem.placemark.subAdministrativeArea {
      dict["address_state_sh"] = state_sh
    }

    if let country = mapItem.placemark.countryCode {
      dict["address_country"] = country
    }

    if let zip_code = mapItem.placemark.postalCode {
      dict["address_zip"] = zip_code
    }

    dict["address_coordinates"] = [
      "address_long": mapItem.placemark.coordinate.longitude,
      "address_lat": mapItem.placemark.coordinate.latitude
    ]

    dict["meta_information"] = [
      "country_iso": mapItem.placemark.isoCountryCode,
      "phone": mapItem.phoneNumber,
      "website": mapItem.url?.absoluteString
    ]

    return RLocation(JSON: dict)
  }

  public static func == (lhs: MKLocalSearchCompletionWrapper, rhs: MKLocalSearchCompletionWrapper) -> Bool {
    return lhs.mkLocalSearchCompletion?.title == rhs.mkLocalSearchCompletion?.title && lhs.mkLocalSearchCompletion?.subtitle == rhs.mkLocalSearchCompletion?.subtitle
  }
}
