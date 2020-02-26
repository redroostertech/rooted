import UIKit
import Messages
import MapKit

protocol LocationSearchDelegate: class {
  func selectLocation(_ searchVC: LocationSearchVC, location: RLocation?)
}

class LocationSearchVC: BaseAppViewController {

  @IBOutlet private var backButton: UIButton!
  @IBOutlet private weak var searchResultsTableView: UITableView!
  @IBOutlet private var searchFormField: UISearchBar!

  private var searchCompleter = MKLocalSearchCompleter()
  private var searchResults = [MKLocalSearchCompletion]()

  weak var locSearchDelegate: LocationSearchDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.applyPrimaryGradient()

    searchCompleter.delegate = self

    searchFormField.setPlaceholderTextColorTo(color: .white)
    searchFormField.setMagnifyingGlassColorTo(color: .white)
  }

  // MARK: - Private methods
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

    dict["address_1"] = address1

    if let name = mapItem.name {
      dict["name"] = name
    }

    if let city = mapItem.placemark.locality {
      dict["city"] = city
    }

    if let state =  mapItem.placemark.administrativeArea {
      dict["state"] = state
    }

    if let state_sh = mapItem.placemark.subAdministrativeArea {
      dict["state_sh"] = state_sh
    }

    if let country = mapItem.placemark.countryCode {
      dict["country"] = country
    }

    if let zip_code = mapItem.placemark.postalCode {
      dict["zip_code"] = zip_code
    }

    dict["coordinates"] = [
      "long": mapItem.placemark.coordinate.longitude,
      "lat": mapItem.placemark.coordinate.latitude
    ]

    dict["meta_information"] = [
      "country_iso": mapItem.placemark.isoCountryCode,
      "phone": mapItem.phoneNumber,
      "website": mapItem.url?.absoluteString
    ]

    return RLocation(JSON: dict)
  }

  @IBAction func back(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
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

        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white

        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let completion = searchResults[indexPath.row]

        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in

          guard let mapItem = response?.mapItems[0], let location = self.generateRLocation(from: mapItem) else { return }

          // Add MKMapItem to RLocation
          location.mapItem = mapItem

          self.dismiss(animated: true, completion: {
            self.locSearchDelegate?.selectLocation(self, location: location)
          })
        }
    }
}


// MARK: - UISearchBarDelegate
extension LocationSearchVC: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchCompleter.queryFragment = searchText
  }
}

// MARK: - MKLocalSearchCompleterDelegate
extension LocationSearchVC: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    searchResults = completer.results
    searchResultsTableView.reloadData()
  }

  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    // handle error
  }
}
