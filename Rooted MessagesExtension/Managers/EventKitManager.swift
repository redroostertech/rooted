import Foundation
import EventKit
import iMessageDataKit
import MapKit

protocol EventKitManagerDelegate: class {
  func didAddInvite(_ manager: EventKitManager, meeting: Meeting)
}

class EventKitManager: NSObject {

  override init() {
    super.init()
    if UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendar") == nil {
      createRootedCalendar()
    }
  }

  // MARK: - Private properties
  private let eventStore = EKEventStore()

  static var calendarIdentifier: String {
    return "Rooted Calendar"
  }

  static var calendarType: EKCalendarType {
    return EKCalendarType.calDAV
  }

  // MARK: - Public methods
  func checkCalendarPermissions(_ completion: @escaping (Bool) -> Void) {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized: completion(true)
    default: completion(false)
    }
  }

  // MARK: - Use Case: Handle the retrieval od calendar permissions
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

  // MARK: - Use Case: Set and create a `Rooted` calendar
  func setCalendar() {
    if UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendar") == nil {
      createRootedCalendar()
    }
  }

  private func createRootedCalendar() {
    let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
    newCalendar.title = EventKitManager.calendarIdentifier
    newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
    do {
      try eventStore.saveCalendar(newCalendar, commit: true)
      UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
    } catch {
      print(error)
      print("Error saving calendar")
    }
  }

  // MARK: - Use Case: Check completion of the meeting and then add the meeting to the calendar
  func saveToCalendar(meeting: Meeting, _ completion: @escaping (Meeting?, Bool, Error?) -> Void) {
    guard let meetingname = meeting.meetingName,
      let startdate = meeting.meetingDate?.startDate?.toDate()?.date,
      let enddate = meeting.meetingDate?.endDate?.toDate()?.date else {
        return completion(nil, false, RError.generalError)
      }
    addToCalendar(meeting: meeting, title: meetingname, startDate: startdate, endDate: enddate, location: meeting.meetingLocation, completion)
  }

  private func addToCalendar(meeting: Meeting, title: String, startDate: Date, endDate: Date, location: RLocation?, _ completion: @escaping (Meeting?, Bool, Error?) -> Void) {

    if let calendarIdentifier = UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendar"), let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) {
      let event = EKEvent(eventStore: eventStore)
      event.title = title
      event.startDate = startDate
      event.endDate = endDate
      if let loc = location, let name = loc.name, let mapItem = loc.mapItem {
        event.location = name
        event.structuredLocation = EKStructuredLocation(mapItem: mapItem)
      }

      insertEvent(event, into: calendar, update: meeting, completion: completion)

    } else {
      if let calendar = eventStore.defaultCalendarForNewEvents {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        if let loc = location, let name = loc.name, let mapItem = loc.mapItem {
          event.location = name
          event.structuredLocation = EKStructuredLocation(mapItem: mapItem)
        }

        self.insertEvent(event, into: calendar, update: meeting, completion: completion)

      } else {
        let calendar = eventStore.calendars(for: .event).first { $0.type == .calDAV || $0.type == .local }
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate

        self.insertEvent(event, into: calendar, update: meeting, completion: completion)
      }
    }
  }

  private func insertEvent(_ event: EKEvent, into calendar: EKCalendar?, update meeting: Meeting, completion: @escaping (Meeting?, Bool, Error?) -> Void) {
     event.calendar = calendar
     event.addAlarm(EKAlarm(relativeOffset: -10800))
     event.addAlarm(EKAlarm(relativeOffset: -86400))
     if !eventAlreadyExists(event: event) {
       do {
         try eventStore.save(event, span: .thisEvent)
         meeting.calendarId = event.eventIdentifier
         completion(meeting, true, nil)
       } catch {
         completion(nil, false, error)
       }
     } else {
       completion(nil, false, RError.customError("Event already exists in calendar."))
     }
   }

  private func eventAlreadyExists(event eventToAdd: EKEvent) -> Bool {
      let predicate = eventStore.predicateForEvents(withStart: eventToAdd.startDate, end: eventToAdd.endDate, calendars: nil)
      let existingEvents = eventStore.events(matching: predicate)

      let eventAlreadyExists = existingEvents.contains { (event) -> Bool in
          return eventToAdd.title == event.title && event.startDate == eventToAdd.startDate && event.endDate == eventToAdd.endDate
      }
      return eventAlreadyExists
  }

  // MARK: - Use Case: Remove meeting from calendar
  func removeFromCalendar(meeting: Meeting, _ completion: @escaping (Meeting?, Bool, Error?) -> Void) {
    if let event = eventStore.event(withIdentifier: meeting.calendarId ?? "") {
      do {
        try eventStore.remove(event, span: .thisEvent)
        completion(meeting, true, nil)
      } catch {
        completion(nil, false, error)
      }
    } else {
      completion(nil, false, RError.customError("There was an error retreiving the meeting."))
    }
  }
}
