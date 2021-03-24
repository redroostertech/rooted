import Foundation
import EventKit
import iMessageDataKit
import MapKit
import DateToolsSwift

protocol EventKitManagerDelegate: class {
  func didAddInvite(_ manager: EventKitManager, meeting: Meeting)
}

class EventKitManager: NSObject {

  override init() {
    super.init()
    setCalendar()
  }

  // MARK: - Private properties
  private let eventStore = EKEventStore()

  static var calendarTitle: String {
    return "Rooted Calendar"
  }

  static var authStatus: Bool {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized: return true
    case .denied, .notDetermined: return false
    default: return false
    }
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

  // MARK: - Use Case: Retrieve default calendar
  static var defaultRootedCalendar: String {
    return UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendar") ?? "None"
  }

  // MARK: - Use Case: Set and create a `Rooted` calendar
  func setCalendar() {
    let calendars = eventStore.calendars(for: .event)
    for abc in calendars {
      if abc.title == EventKitManager.calendarTitle {
        UserDefaults.standard.set(EventKitManager.calendarTitle, forKey: "EventTrackerPrimaryCalendar")
        UserDefaults.standard.set(abc.calendarIdentifier, forKey: "EventTrackerPrimaryCalendarIdentifier")
        return
      }
    }
    let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
    newCalendar.title = EventKitManager.calendarTitle
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

    if let calendarIdentifier = UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendarIdentifier"), let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) {
      let event = EKEvent(eventStore: eventStore)
      event.title = String(format: kCaptionTitle, arguments: [title])
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
        //      event.title = "ROOTED EVENT: \(title)"
        event.title = String(format: kCaptionTitle, arguments: [title])
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
        event.title = String(format: kCaptionTitle, arguments: [title])
        event.startDate = startDate
        event.endDate = endDate

        self.insertEvent(event, into: calendar, update: meeting, completion: completion)
      }
    }
  }

  private func insertEvent(_ event: EKEvent, into calendar: EKCalendar?, update meeting: Meeting, completion: @escaping (Meeting?, Bool, Error?) -> Void) {
     event.calendar = calendar
     event.addAlarm(EKAlarm(relativeOffset: -3600))
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
  func removeFromCalendar(meeting: Meeting, recurrently: Bool = false, _ completion: @escaping (Meeting?, Bool, Error?) -> Void) {
    guard let startdate = meeting.meetingDate?.startDate?.toDate()?.date,
      let enddate = meeting.meetingDate?.endDate?.toDate()?.date else {
        return completion(nil, false, RError.customError("There was an error retreiving the meeting."))
    }

    let calendars = eventStore.calendars(for: .event)

    let predicate = eventStore.predicateForEvents(withStart: startdate, end: enddate, calendars: calendars)

    let events = eventStore.events(matching: predicate)

    if events.count == 0 {
      completion(nil, false, RError.customError("There was an error retreiving the meeting."))
    }

    for event in events {
      if let eventTitle = event.title, let meetingName = meeting.meetingName, eventTitle.contains("ROOTED"), eventTitle.contains(meetingName) {
        do {
          try eventStore.remove(event, span: recurrently ? .futureEvents : .thisEvent)
          completion(meeting, true, nil)
        } catch {
          completion(nil, false, error)
        }
      }
    }
  }

  // MARK: - Use Case: Fetching events from a particular calendar
  func getEventsFromCalenderWith(identifier: String? = nil,
                                 startDate: Date,
                                 endDate: Date,
                                 includeFreeTime: Bool = false) -> [EKEvent] {
    let calendars = eventStore.calendars(for: .event)
    var eventArray = [EKEvent]()
    for calendar in calendars {
        if
            let calendarIdentifier = identifier,
            (calendar.calendarIdentifier == calendarIdentifier || calendar.title == calendarIdentifier)
        {
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])

            let events = eventStore.events(matching: predicate)
            for event in events {
              eventArray.append(event)
            }
            
      } else {
            /// Find events for the day
            let todayPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
            let todayEvents = eventStore.events(matching: todayPredicate)
            eventArray.append(contentsOf: todayEvents)
        }
    }
    
    if includeFreeTime {
      let freeTimeEvents = FreeTimeFinder.find(with: eventStore,
                                               in: eventArray,
                                               from: startDate,
                                               to: endDate,
                                               startTime: startDate.beginningOfDay,
                                               endTime: endDate.beginningOfDay,
                                               freeTime: TimeInterval(3600),
                                               transitTime: TimeInterval.zero,
                                               ignoreAllDay: true,
                                               ignoreHolidays: true)
      eventArray.append(contentsOf: freeTimeEvents)
    }
    return eventArray
  }
    
    private let calculator: EventDateCalculator = .init()

  // MARK: - Use Case: Show list of current calendars
  // TODO: - EKCalendarChooser is not supported in Extension apps. Look to create your own instance
//  func showCalendarChooser() -> EKCalendarChooser {
//    return EKCalendarChooser(selectionStyle: .single, displayStyle: .allCalendars, entityType: .event, eventStore: eventStore)
//  }
}

extension EKEvent {
    var hasGeoLocation: Bool {
        return structuredLocation?.geoLocation != nil
    }

    var isBirthdayEvent: Bool {
        return birthdayContactIdentifier != nil
    }
    
    var color: UIColor {
        return UIColor(cgColor: calendar.cgColor)
    }
    
    var toCalendarKitEvent: CalendarKitEvent {
      let calendarKitEvent = CalendarKitEvent()
      calendarKitEvent.startDate = self.startDate
      calendarKitEvent.endDate = self.endDate
      if Date.today().isGreaterThanDate(self.endDate) {
          if self.title.contains(kCaptionTitleBase) {
              calendarKitEvent.color = .systemOrange
              calendarKitEvent.textColor = .darkText
          } else {
              calendarKitEvent.color = .lightGray
              calendarKitEvent.textColor = .darkText
          }
      } else {
          calendarKitEvent.color = .lightGray
          calendarKitEvent.textColor = .darkText
      }
      calendarKitEvent.text = self.title
      calendarKitEvent.isAllDay = self.isAllDay
      return calendarKitEvent
    }
}

// Proof of concept
public final class FreeTimeFinder {
    public typealias Result = [(Date, Date)]
    public static func find(with eventStore: EKEventStore,
                            in events: [EKEvent],
                            from: Date, to: Date,
                            startTime: Date,
                            endTime: Date,
                            freeTime: TimeInterval,
                            transitTime: TimeInterval,
                            ignoreAllDay: Bool,
                            ignoreHolidays: Bool) -> [EKEvent] {
        
        let freeTimePeriodCollection = TimePeriodCollection()
        let timePeriodCollection = TimePeriodCollection()
      
        for event in events {
            if ignoreAllDay, !event.isAllDay {
                let timePeriod = TimePeriod(beginning: event.startDate,
                                            end: event.endDate)
                timePeriod.beginning = event.startDate
                timePeriod.end = event.endDate
                timePeriodCollection.append(timePeriod)
            }
        }
        
      let sortedTimePeriodCollection = timePeriodCollection.sortedByEnd()
        
      // MARK: - Handle case where there are no applicable events to generate free time periods from
      /// If no periods were created via the events, then user is free all day
      if sortedTimePeriodCollection.periodsInGroup.isEmpty {
        /// Generate a time period for all day
        let timePeriod = TimePeriod(beginning: startTime,
                                    end: endTime)
        timePeriod.beginning = startTime
        timePeriod.end = endTime
        
        // Check for duplicates before adding a new free time period
        if !freeTimePeriodCollection.contains(where: { period -> Bool in
          return period.equals(timePeriod)
        }) {
          freeTimePeriodCollection.append(timePeriod)
        }
      }
      
        var i = 0
        while i < sortedTimePeriodCollection.periodsInGroup.count {
            /// Get all of the periods
            let periods = sortedTimePeriodCollection.periodsInGroup
            
            /// Get current period
            let currentPeriod = periods[i]
            
            // MARK: - Handle case where there is only 1 event to generate free time periods from
            /// Check if current period is the only period
            if periods.count == 1 {
                if
                  let currentPeriodStart = currentPeriod.beginning,
                  let currentPeriodEnd = currentPeriod.end {

                    if
                      /// Check if the current event's start time is after midnight
                      currentPeriodStart.isGreaterThanDate(startTime) {
                      /// Generate the period form the start of the current day to the start of the event
                      let timePeriod = TimePeriod()
                      timePeriod.beginning = startTime
                      timePeriod.end = currentPeriodStart
                      if !freeTimePeriodCollection.contains(where: { period -> Bool in
                        return period.equals(timePeriod)
                      }) {
                        freeTimePeriodCollection.append(timePeriod)
                      }
                      
                      /// Generate the period from the end of the event to the end of the day
                      if currentPeriodEnd.isLessThanDate(endTime) {
                        let timePeriod = TimePeriod()
                        timePeriod.beginning = currentPeriodEnd
                        timePeriod.end = endTime
                        
                        // Check for duplicates before adding a new free time period
                        if !freeTimePeriodCollection.contains(where: { period -> Bool in
                          return period.equals(timePeriod)
                        }) {
                          freeTimePeriodCollection.append(timePeriod)
                        }
                      }
                    }
                    
                    if
                      /// Check if the current event is an extension from the previous day
                      currentPeriodStart.isLessThanDate(startTime),
                      /// Check to see if event ends in the current day
                      currentPeriodEnd.isLessThanDate(endTime) {
                      
                      /// Generate the period from the end of the event on the current day to the end of the current day
                      let timePeriod = TimePeriod()
                      timePeriod.beginning = currentPeriodEnd
                      timePeriod.end = endTime
                      
                      // Check for duplicates before adding a new free time period
                      if !freeTimePeriodCollection.contains(where: { period -> Bool in
                        return period.equals(timePeriod)
                      }) {
                        freeTimePeriodCollection.append(timePeriod)
                      }
                    }
                }
            }
            
            // MARK: - Handle case where there are 2+ events to generate free time preiods from
            else {
              
              /// Get previous period
              let previousPeriodIndex = i - 1
      
              /// Qeue up next period
              let nextPeriodIndex = i + 1
              
              if nextPeriodIndex > periods.count {
                /// We are at the end of the collection, so only do work for current period
              }
              
              /// if index for next period is less than total periods in the array, we can start generating free time periods
              if nextPeriodIndex < periods.count {
                
                /// Get the next event
                let nextPeriod = periods[nextPeriodIndex]
                
                /// Check to see if item is the first item in the list
                /// Previous index will be -1 if item is first in list
                if previousPeriodIndex < 0 {
                  
                  if
                    let currentPeriodStart = currentPeriod.beginning,
                    let currentPeriodEnd = currentPeriod.end {
                    
                    if
                      /// Check if events start time is after midnight
                      currentPeriodStart.isGreaterThanDate(startTime) {
                      
                      /// Generate the period form the start of the current day to the start of the event
                      let timePeriod = TimePeriod()
                      timePeriod.beginning = startTime
                      timePeriod.end = currentPeriodStart
                      if !freeTimePeriodCollection.contains(where: { period -> Bool in
                        return period.equals(timePeriod)
                      }) {
                        freeTimePeriodCollection.append(timePeriod)
                      }
                      
                      /// When generating the period after the event, check to see what the current event's relation to the next event is. Only calculate if the
                      /// relation is either before or end touching
                      switch currentPeriod.relation(to: nextPeriod) {
                      case .after, .startTouching:
                        /// Generate the period from the end of the event to the beginning of the next event
                        let timePeriod = TimePeriod()
                        timePeriod.beginning = currentPeriodEnd
                        timePeriod.end = nextPeriod.beginning ?? endTime
                        
                        // Check for duplicates before adding a new free time period
                        if !freeTimePeriodCollection.contains(where: { period -> Bool in
                          return period.equals(timePeriod)
                        }) {
                          freeTimePeriodCollection.append(timePeriod)
                        }
                      default:
                        break
                      }
                    }
  
                    if
                      /// Check if the current event is an extension from the previous day
                      currentPeriodStart.isLessThanDate(startTime),
                      /// Check to see if event ends in the current day
                      currentPeriodEnd.isLessThanDate(endTime)
                    {
                      /// When generating the period after the event, check to see what the current event's relation to the next event is. Only calculate if the
                      /// relation is either before or end touching
                      switch currentPeriod.relation(to: nextPeriod) {
                      case .before, .endTouching:
                        /// Generate the period from the end of the event to the end of the day/// Generate the period from the end of the event to the beginning of the next event
                        let timePeriod = TimePeriod()
                        timePeriod.beginning = currentPeriodEnd
                        timePeriod.end = nextPeriod.beginning ?? endTime
                        
                        // Check for duplicates before adding a new free time period
                        if !freeTimePeriodCollection.contains(where: { period -> Bool in
                          return period.equals(timePeriod)
                        }) {
                          freeTimePeriodCollection.append(timePeriod)
                        }
                      default:
                        break
                      }
                    }
                  }
                }
                
                /// Check to see if item is the next item in the list
                else {
                  /// Get the previous event
                  let previousPeriod = periods[previousPeriodIndex]
                  
                  if
                    let currentPeriodStart = currentPeriod.beginning,
                    let currentPeriodEnd = currentPeriod.end {
                    
                    /// When generating the period before the event, check to see what the current event's relation to the next event is. Only calculate if the
                    /// relation is either after or start touching
                    switch currentPeriod.relation(to: previousPeriod) {
                    case .after, .startTouching:
                      /// Generate the period from the end of the event to the end of the day/// Generate the period from the end of the event to the beginning of the next event
                      let timePeriod = TimePeriod()
                      timePeriod.beginning = previousPeriod.end ?? startTime
                      timePeriod.end = currentPeriodStart
                      
                      // Check for duplicates before adding a new free time period
                      if !freeTimePeriodCollection.contains(where: { period -> Bool in
                        return period.equals(timePeriod)
                      }) {
                        freeTimePeriodCollection.append(timePeriod)
                      }
                    default:
                      break
                    }
                    
                    /// When generating the period after the event, check to see what the current event's relation to the next event is. Only calculate if the
                    /// relation is either after or start touching
                    switch currentPeriod.relation(to: nextPeriod) {
                    case .before, .endTouching:
                      /// Generate the period from the end of the event to the end of the day/// Generate the period from the end of the event to the beginning of the next event
                      let timePeriod = TimePeriod()
                      timePeriod.beginning = currentPeriodEnd
                      timePeriod.end = nextPeriod.beginning ?? endTime
                      
                      // Check for duplicates before adding a new free time period
                      if !freeTimePeriodCollection.contains(where: { period -> Bool in
                        return period.equals(timePeriod)
                      }) {
                        freeTimePeriodCollection.append(timePeriod)
                      }
                    default:
                      break
                    }
                  }
                }
              }
            }
            
            i+=1
        }

      return freeTimePeriodCollection.map { period -> EKEvent in
        let event = EKEvent(eventStore: eventStore)
        event.title = "Free"
        event.endDate = period.end
        event.startDate = period.beginning
        return event
      }.uniques
    }
}

public final class EventDateCalculator {
    public init() {}

    public func isContains(source sourceEKEvent: EKEvent, dist distEKEvent: EKEvent) -> Bool {
        isContains(source: sourceEKEvent, at: distEKEvent.startDate)
            && isContains(source: sourceEKEvent, at: distEKEvent.endDate)
    }

    public func isIntersects(source sourceEKEvent: EKEvent, dist distEKEvent: EKEvent) -> Bool {
        isContains(source: sourceEKEvent, at: distEKEvent.startDate)
            || isContains(source: sourceEKEvent, at: distEKEvent.endDate)
            || isContains(source: sourceEKEvent, dist: distEKEvent)
            || isContains(source: distEKEvent, dist: sourceEKEvent)
    }

    public func isContains(source EKEvent: EKEvent, at date: Date) -> Bool {
        EKEvent.startDate <= date && EKEvent.endDate >= date
    }

    public func timeInterval(from fromEKEvent: EKEvent, to toEKEvent: EKEvent) -> TimeInterval {
        if fromEKEvent.endDate <= toEKEvent.startDate {
//            return fromEKEvent.endDate.distance(to: toEKEvent.startDate)
            return toEKEvent.endDate.timeIntervalSince(fromEKEvent.startDate)
        } else {
//            return toEKEvent.endDate.distance(to: fromEKEvent.startDate)
            return fromEKEvent.endDate.timeIntervalSince(toEKEvent.startDate)
        }
    }

    public func startTimeInterval(at date: Date, for EKEvent: EKEvent) -> TimeInterval {
//        date.distance(to: EKEvent.startDate)
        EKEvent.startDate.timeIntervalSince(date)
    }

    public func endTimeInterval(at date: Date, for EKEvent: EKEvent) -> TimeInterval {
//        EKEvent.endDate.distance(to: date)
        date.timeIntervalSince(EKEvent.endDate)
    }

    public func convert(_ date: Date, to today: Date, calendar: Calendar = .init(identifier: .gregorian), timeZone: TimeZone = .current) -> Date {
        var calendar = calendar
        calendar.timeZone = timeZone
        var dateComponentsSrc = calendar.dateComponents([.hour, .minute], from: date)
        dateComponentsSrc.calendar = calendar
        dateComponentsSrc.timeZone = timeZone

        var dateComponentsDist = calendar.dateComponents([.year, .month, .day], from: today)
        dateComponentsDist.calendar = calendar
        dateComponentsDist.timeZone = timeZone
        dateComponentsDist.hour = dateComponentsSrc.hour
        dateComponentsDist.minute = dateComponentsSrc.minute
        dateComponentsDist.second = 0
        dateComponentsDist.nanosecond = 0

        return calendar.date(from: dateComponentsDist)!
    }

    public func split(from fromDate: Date, to toDate: Date, startTime: Date, endTime: Date, calendar: Calendar = .init(identifier: .gregorian), timeZone: TimeZone = .current) -> [(Date, Date)] {
        assert(fromDate <= toDate, "toDate must large than fromDate")

        var calendar = calendar
        calendar.timeZone = timeZone
        var fromDateComponents = calendar.dateComponents([.year, .month, .day], from: fromDate)
        fromDateComponents.timeZone = timeZone

        var toDateComponents = calendar.dateComponents([.year, .month, .day], from: toDate)
        toDateComponents.timeZone = timeZone
        let toDateForCompare = calendar.date(from: toDateComponents)!

        var currentDateComponents = fromDateComponents
        var appendDateComponents = DateComponents()
        appendDateComponents.day = 1

        var result: [(Date, Date)] = []
        repeat {
            let date = calendar.date(from: currentDateComponents)!
            let from = convert(startTime, to: date)
            let to = convert(endTime, to: date)
            result.append((from, to))

            let nextDate = calendar.date(byAdding: appendDateComponents, to: date)!
            currentDateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
            currentDateComponents.timeZone = timeZone
        } while calendar.date(from: currentDateComponents)! <= toDateForCompare
        return result
    }
}


extension Collection where Element == EKEvent {
    public func search(in startDate: Date, and endDate: Date) -> [EKEvent] {
        filter { entity in
            if startDate <= entity.startDate, endDate >= entity.endDate {
                return true
            } else if entity.startDate <= startDate, entity.endDate >= endDate {
                return true
            } else if startDate <= entity.startDate, endDate >= entity.startDate {
                return true
            } else if startDate <= entity.endDate, endDate >= entity.endDate {
                return true
            } else {
                return false
            }
        }
    }
}

extension Array where Element: Hashable {
    var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}

extension TimePeriodCollection {
  public var periodsInGroup: [TimePeriodProtocol] {
      return periods
  }
  /**
   *  Return collection with sorted periods array by end
   *
   * - returns: Collection with sorted periods
   */
  public func sortedByEnd() -> TimePeriodCollection {
      let array = periodsInGroup.sorted { (period1: TimePeriodProtocol, period2: TimePeriodProtocol) -> Bool in
          if period1.end == nil && period2.end == nil {
              return false
          } else if (period1.end == nil) {
              return true
          } else if (period2.end == nil) {
              return false
          } else {
              return period2.end! > period1.end!
          }
      }
      let collection = TimePeriodCollection()
      collection.append(array)
      return collection
  }
}
