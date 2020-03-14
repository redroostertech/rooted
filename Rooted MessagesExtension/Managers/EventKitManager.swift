import Foundation
import EventKit
import iMessageDataKit
import MapKit

protocol EventKitManagerDelegate: class {
  func didAddInvite(_ manager: EventKitManager, meeting: Meeting)
}

class EventKitManager: NSObject {

  // MARK: - Private properties
  private let eventStore = EKEventStore()

  static var calendarIdentifier: String {
    return "Calendar"
  }

  static var calendarType: EKCalendarType {
    return EKCalendarType.calDAV
  }

  // MARK: - Private methods
  private func createRootedCalendar() {
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

  private func insertEvent(title: String, startDate: Date, endDate: Date, location: RLocation?, _ completion: @escaping (Bool, Error?) -> Void) {
    let calendars = eventStore.calendars(for: .event)
    var done = false
    for calendar in calendars {
      if calendar.type == EventKitManager.calendarType && done == false {

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        // TODO: - Use this property to be able to identify event in calendar to delete it
        // event.eventIdentifier
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
          completion(false, error)
        }
      }
    }

    if calendars.count == 0 {
      completion(false, RError.customError("There was an error retreiving your calendars.").error)
    }
  }

  // MARK: - Public methods
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

  func insertMeeting(meeting: Meeting, _ completion: @escaping (Bool, Error?) -> Void) {
    guard let meetingname = meeting.meetingName,
      let startdate = meeting.meetingDate?.startDate?.toDate()?.date,
      let enddate = meeting.meetingDate?.endDate?.toDate()?.date else {
        return completion(false, RError.generalError.error)
      }
    insertEvent(title: meetingname, startDate: startdate, endDate: enddate, location: meeting.meetingLocation, completion)
  }
}
