import Foundation
import EventKit
import iMessageDataKit
import MapKit

class EventKitManager: NSObject {
    let eventStore = EKEventStore()

    static var calendarIdentifier: String {
        return "Calendar"
    }
    static var calendarType: EKCalendarType {
        return EKCalendarType.calDAV
    }

    func getCalendarPermissions(_ completion: @escaping (Bool) -> Void) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized: completion(true)
        case .denied, .notDetermined:
            eventStore.requestAccess(to: .event, completion: { (granted: Bool, error: Error?) -> Void in
                if granted {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        default: completion(false)
        }
    }

    func createRootedCalendar() {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = EventKitManager.calendarIdentifier
        let sourcesInEventStore = eventStore.sources
        newCalendar.source = sourcesInEventStore.filter{
            (source: EKSource) -> Bool in
            source.sourceType == EKSourceType.local
            }.first
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
        } catch {
            print(error)
            print("Error saving calendar")
        }
    }

    func insertEvent(title: String, startDate: Date, endDate: Date, location: RLocation?, _ completion: @escaping (Bool, Error?) -> Void) {
        let calendars = eventStore.calendars(for: .event)
        var done = false
        for calendar in calendars {
            if calendar.type == EventKitManager.calendarType && done == false {

                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.addAlarm(EKAlarm(relativeOffset: -10800))
                event.addAlarm(EKAlarm(relativeOffset: -86400))

                if let loc = location, let name = loc.name, let mapItem = loc.mapItem {
                    event.location = name
                    event.structuredLocation = EKStructuredLocation(mapItem: mapItem)
                }

                do {
                    try eventStore.save(event, span: .thisEvent)
                    done = true
                    completion(done, nil)
                } catch {
                    print(error.localizedDescription)
                    print("Error saving event in calendar")
                    completion(false, error)
                }
            }
        }

    }
}
