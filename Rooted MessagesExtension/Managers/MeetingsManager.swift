import UIKit
import ObjectMapper
import CoreData

public typealias InvitesManagerDataHandler = ([MeetingContextWrapper]?, Error?) -> Void
public typealias InvitesManageResultsHandler = (Bool, Error?) -> Void

protocol MeetingsManagerDelegate: class {
  func willDeleteInvite(_ manager: Any?)
  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper)

  func didFinishLoading(_ manager: Any?, invites: [MeetingContextWrapper])
  func didFailToLoad(_ manager: Any?, error: Error)
}

extension MeetingsManagerDelegate {
  func willDeleteInvite(_ manager: Any?) { }
  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper) { }

  func didFinishLoading(_ manager: Any?, invites: [MeetingContextWrapper]) { }
  func didFailToLoad(_ manager: Any?, error: Error) { }
}

public class MeetingContextWrapper {
  var meeting: Meeting?
  var managedObject: NSManagedObject?
  init(meeting: Meeting?, managedObject: NSManagedObject?) {
    self.meeting = meeting
    self.managedObject = managedObject
  }
}

class MeetingsManager: NSObject {

  // MARK: - Private Properties
  private var coreDataManager = CoreDataManager()
  private var meetings = [MeetingContextWrapper]()

  // MARK: - Public properties
  weak var delegate: MeetingsManagerDelegate?

  // MARK: - Use Case: As a business, we want to limit access to creating more than (n) meetings based on account type
  func didUserReachMaximumInvites(_ completion: (Bool) -> Void) {
    getMeetings {
      (results, error) in
      if let _ = error {
        completion(false)
      } else {
        guard results != nil else {
          completion(false)
          return
        }

        for result in results! {

          if
            // Check if meeting object can be deserialized
            let meeting = EngagementFactory.Meetings.coreDataToJson(result),
            // Check that meeting has a start date
            let _ = meeting.meetingDate?.startDate?.toDate()?.date,
            // Check that meeting has an end date
            let endDate = meeting.meetingDate?.endDate?.toDate()?.date,
            // Check if meeting has an end date greater than today
            !endDate.timeIntervalSince(Date()).isLess(than: 0) {
            let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: result)
            self.meetings.append(meetingWrapper)
          }
        }

        self.meetings = self.meetings.sorted(by: { (current, next) -> Bool in
          guard let cur = current.meeting, let curDate = cur.meetingDate?.startDate?.toDate()?.date, let nx = next.meeting, let nxDate = nx.meetingDate?.startDate?.toDate()?.date else {
            return false
          }
          return curDate.timeIntervalSince(nxDate).isLess(than: 0)
        })

        let diduserreachmaximuminvites = self.meetings.filter { meetingContextWrapper -> Bool in
          guard let meeting = meetingContextWrapper.meeting, let dashboardSectionId = meeting.dashboardSectionId else { return false }
          return dashboardSectionId == 1
        }.count >= maximumInvites

        completion(diduserreachmaximuminvites)

      }
    }
  }

  // MARK: - Use Case: Retrieve meetings for user
  func retrieveMeetings() {
    meetings.removeAll()
    getMeetings { (results, error) in
      if let err = error {
        self.delegate?.didFailToLoad(self, error: err)
      } else {
        guard results != nil else {
          self.delegate?.didFailToLoad(self, error: RError.generalError)
          return
        }
        for result in results! {

          if
            // Check if meeting object can be deserialized
            let meeting = EngagementFactory.Meetings.coreDataToJson(result) {
//            // Check that meeting has a start date
//            let _ = meeting.meetingDate?.startDate?.toDate()?.date,
//            // Check that meeting has an end date
//            let endDate = meeting.meetingDate?.endDate?.toDate()?.date,
//            // Check if meeting has an end date greater than today
//            !endDate.timeIntervalSince(Date()).isLess(than: 0) {
            let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: result)
            self.meetings.append(meetingWrapper)
          }
        }

        self.meetings = self.meetings.sorted(by: { (current, next) -> Bool in
          guard let cur = current.meeting, let curDate = cur.meetingDate?.startDate?.toDate()?.date, let nx = next.meeting, let nxDate = nx.meetingDate?.startDate?.toDate()?.date else {
            return false
          }
          return curDate.timeIntervalSince(nxDate).isLess(than: 0)
        })

        self.delegate?.didFinishLoading(self, invites: self.meetings)
      }
    }
  }

  private func getMeetings(_ completion: CoreDataHandler) {
    coreDataManager.retrieve(entityName: kEntityMeeting) { (objects, error) in
      completion(objects, error)
    }
  }

  // MARK: - Use Case: Create a meeting
  func createInvite(_ object: Meeting, _ completion: ((Bool, Error?) -> Void)?) {
    // Check if meeting already exists
    getMeetings { (objects, error) in
      if let results = objects, results.count >= 1 {
        for result in results {
          if let meeting = EngagementFactory.Meetings.coreDataToJson(result), meeting.id == object.id {
            let duplicateError = RError.customError("Meeting already exists.")
            self.delegate?.didFailToLoad(self, error: duplicateError)
            completion?(false, duplicateError)
          } else {
            guard let jsonString = object.toJSONString() else {
              let generalError = RError.generalError
              self.delegate?.didFailToLoad(self, error: generalError)
              completion?(false, generalError)
              return
            }
            // Perform create method using jsonString
            create(jsonString: jsonString) { (managedObject, error) in
              if let err = error {
                self.delegate?.didFailToLoad(self, error: err)
                completion?(false, err)
              } else {
                if let managedobject = managedObject {
                  let meetingWrapper = MeetingContextWrapper(meeting: object, managedObject: managedobject)
                  self.meetings.append(meetingWrapper)
                  self.delegate?.didFinishLoading(self, invites: self.meetings)
                  completion?(true, nil)
                } else {
                  let generalError = RError.generalError
                  self.delegate?.didFailToLoad(self, error: generalError)
                  completion?(false, generalError)
                }
              }
            }
          }
        }
      } else {
        guard let jsonString = object.toJSONString() else {
          let generalError = RError.generalError
          self.delegate?.didFailToLoad(self, error: generalError)
          completion?(false, generalError)
          return
        }
        // Perform create method using jsonString
        create(jsonString: jsonString) { (managedObject, error) in
          if let err = error {
            self.delegate?.didFailToLoad(self, error: err)
            completion?(false, err)
          } else {
            if let managedobject = managedObject {
              let meetingWrapper = MeetingContextWrapper(meeting: object, managedObject: managedobject)
              self.meetings.append(meetingWrapper)
              self.delegate?.didFinishLoading(self, invites: self.meetings)
              completion?(true, nil)
            } else {
              let generalError = RError.generalError
              self.delegate?.didFailToLoad(self, error: generalError)
              completion?(false, generalError)
            }
          }
        }
      }
    }
   }

   private func create(jsonString: String, _ completion: @escaping (NSManagedObject?, Error?) -> Void) {
     guard let object = coreDataManager.meetingManagedObject else {
       completion(nil, RError.generalError)
       return
     }

     let referenceDate = Date()

     object.setValuesForKeys([
       "id": RanStringGen(length: 10).returnString(),
       "object": jsonString,
       "createdAt": referenceDate,
       "updatedAt": referenceDate
       ])

     do {
       try coreDataManager.managedContext.save()
       completion(object, nil)
     } catch let error {
       completion(nil, error)
     }
   }

  // MARK: - Use Case: Delete a meeting
  func deleteMeeting(_ managedObject: NSManagedObject) {

    self.delegate?.willDeleteInvite(self)

    // Check if we can convert `NSManagedObject` into a `Meeting` object
    guard EngagementFactory.Meetings.coreDataToJson(managedObject) != nil else {
      self.delegate?.didFailToLoad(self, error: RError.generalError)
      return
    }

    meetings.removeAll { context -> Bool in
      if let managedobject = context.managedObject {
        return managedobject == managedObject
      }
      return false
    }

    delete(meeting: managedObject) { (success, error) in
      if let err = error, success != true {
        self.delegate?.didFailToLoad(self, error: err)
      } else {
        let meetingWrapper = MeetingContextWrapper(meeting: nil, managedObject: managedObject)
        self.delegate?.didDeleteInvite(self, invite: meetingWrapper)
        self.delegate?.didFinishLoading(self, invites: self.meetings)
      }
    }
  }

  // MARK: - Use Case: Delete a meeting
  func deleteDraftMeeting(_ managedObject: NSManagedObject) {

    self.delegate?.willDeleteInvite(self)

    // Check if we can convert `NSManagedObject` into a `Meeting` object
    guard EngagementFactory.Meetings.coreDataToJson(managedObject) != nil, let contextId = managedObject.value(forKey: "id") as? String else {
      self.delegate?.didFailToLoad(self, error: RError.generalError)
      return
    }

    coreDataManager.retrieveMeetingWith(id: contextId, entityName: kEntityMeeting) { (managedObj, error) in
      if let err = error {
        self.delegate?.didFailToLoad(self, error: err)
      } else {
        guard let managedobj = managedObj?.first else {
          self.delegate?.didFailToLoad(self, error: RError.generalError)
          return
        }

        meetings.removeAll { context -> Bool in
          if let managedobject = context.managedObject {
            return managedobject == managedobj
          }
          return false
        }

        self.delete(meeting: managedobj) { (success, error) in
          if let err = error, success != true {
            self.delegate?.didFailToLoad(self, error: err)
          } else {
            let meetingWrapper = MeetingContextWrapper(meeting: nil, managedObject: managedobj)

            self.retrieveMeetings()
            
            self.delegate?.didDeleteInvite(self, invite: meetingWrapper)
            self.delegate?.didFinishLoading(self, invites: self.meetings)
          }
        }
      }
    }
  }

  private func delete(meeting: NSManagedObject, _ completion: CoreDataResultsHandler) {
    coreDataManager.delete(object: meeting) { (success, error) in
      completion(success, error)
    }
  }

  // MARK: - Use Case: Delete a meeting
  func updateMeeting(_ managedObject: NSManagedObject, withValue value: Any, forKey key: String, _ completion: ((Bool, Error?) -> Void)?) {

    managedObject.setValue(value, forKey: key)
    
    do {
      try coreDataManager.managedContext.save()
      completion?(true, nil)
    } catch let error {
      completion?(false, error)
    }
  }
}
