import UIKit
import Messages
import MapKit
import EventKit
import iMessageDataKit
import SSSpinnerButton
import CoreLocation

class InviteDetailsVC: MSMessagesAppViewController {

    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var locationNameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var acceptInviteButton: SSSpinnerButton!

    var eventStore: EKEventStore?
    var titleText: String?
    var startDate: Date?
    var endDate: Date?
    var selectedLocationName: String?
    var selectedLocation: (MKMapItem, MKPlacemark)?
    var selectedLocationNew: (MKMapItem, MKPlacemark)?
    var location: CLLocation? {
        didSet {
            guard let location = self.location else { return }
            self.reverseGeocode(usingLocation: location)
        }
    }
    var locationManager: CLLocationManager?
    var geoCoder = CLGeocoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.applyPrimaryGradient()
        acceptInviteButton.layer.cornerRadius = acceptInviteButton.frame.height / 2
        if locationManager == nil {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        loadVC()
    }

    func loadVC() {
        if let titleText = self.titleText {
            self.titleLabel.text = titleText
        }

        if let startDate = self.startDate {
            self.timeLabel.text = startDate.toString(CustomDateFormat.rooted)
        }

        if let endDate = self.endDate?.toString(CustomDateFormat.rooted) {
            self.timeLabel.text = timeLabel.text! + " to " +  endDate
        }

        if let selectedLocationName = self.selectedLocationName {
            self.locationNameLabel.text = selectedLocationName
        }

        if let selectedLocation = self.selectedLocation {
            self.location = CLLocation(latitude: selectedLocation.1.coordinate.latitude, longitude: selectedLocation.1.coordinate.longitude)
            self.locationLabel.text =
                String(describing: selectedLocation.1.addressDictionary?["subThoroughfare"] ?? "")
                + " " + String(describing: selectedLocation.1.addressDictionary?["thoroughfare"] ?? "") + "\n" + String(describing: selectedLocation.1.addressDictionary?["locality"] ?? "") + ", " + String(describing: selectedLocation.1.addressDictionary?["administrativeArea"] ?? "")
        }
    }

    @IBAction func acceptInvite(_ sender: UIButton) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            accept()
        case .denied, .notDetermined:
            self.eventStore?.requestAccess(to: .event, completion: { (granted: Bool, error: Error?) -> Void in
                if granted {
                    self.accept()
                } else {
                    
                }
            })
        default: print("Case default")
        }
    }

    @IBAction func declineInvite(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    func accept() {
        acceptInviteButton.startAnimate(spinnerType: SpinnerType.ballClipRotate, spinnercolor: UIColor.gradientColor1, spinnerSize: 20, complete: {
            if
                let eventStore = self.eventStore,
                let title = self.titleText,
                let startDate = self.startDate,
                let endDate = self.endDate,
                let locationName = self.selectedLocationName {
                self.insertEvent(store: eventStore, title: title, startDate: startDate, endDate: endDate, location: self.selectedLocationNew, locationName: locationName)
            } else {
                self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: CompletionType.fail,backToDefaults: true, complete: {
                    let alert = UIAlertController(title: "Error", message: "Something went wrong. Please try again.", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                })
            }
        })
    }

    func insertEvent(store: EKEventStore, title: String, startDate: Date, endDate: Date, location: (MKMapItem, MKPlacemark)?, locationName name: String) {
        let calendars = store.calendars(for: .event)
        var done = false
        for calendar in calendars {
            if calendar.type == EventKitManager.calendarType && done == false {

                let event = EKEvent(eventStore: store)
                event.calendar = calendar

                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.addAlarm(EKAlarm(relativeOffset: -10800))
                
                if let loc = location {
                    event.location = name
                    loc.0.name = name
                    event.structuredLocation = EKStructuredLocation(mapItem: loc.0)
                }

                do {
                    try store.save(event, span: .thisEvent)
                    done = true
                    self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .success, backToDefaults: true, complete: {
                        self.dismiss(animated: true, completion: nil)
                    })
                } catch {
                    print(error.localizedDescription)
//                    self.acceptInviteButton.stopAnimationWithCompletionTypeAndBackToDefaults(completionType: .none, backToDefaults: true, complete: {
//                            print("Error saving event in calendar")
//                    })
                }
            }
        }
    }
}

extension InviteDetailsVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
        } else {
        }
    }
    func reverseGeocode(usingLocation location: CLLocation) {
        self.geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let _ = error {
                print("Error reverse geocoding location")
            } else {
                if let place = placemarks?.first {
                    let placeMark = MKPlacemark(placemark: place)
                    let mapItem = MKMapItem(placemark: placeMark)
                    self.selectedLocationNew = (mapItem, placeMark)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
