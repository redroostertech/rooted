import UIKit
import ObjectMapper
import CoreData

protocol MyInvitesDelegate: class {
  func willDeleteInvite(_ manager: Any?)
  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper)

  func didFinishLoading(_ manager: Any?, invites: [MeetingContextWrapper])
  func didFailToLoad(_ manager: Any?, error: Error)
}

public typealias InvitesManagerDataHandler = ([MeetingContextWrapper]?, Error?) -> Void
public typealias InvitesManageResultsHandler = (Bool, Error?) -> Void

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
  private var invites = [MeetingContextWrapper]()

  // MARK: - Public properties
  weak var delegate: MyInvitesDelegate?

  // MARK: - Computed properties

  // Core
  var maximumReached: Bool {
    return invites.filter { meetingContextWrapper -> Bool in
      guard let meeting = meetingContextWrapper.meeting, let dashboardSectionId = meeting.dashboardSectionId else { return false }
      return dashboardSectionId == 1
    }.count >= maximumInvites
  }

  // Entities
  private var meeting: NSManagedObject? {
    guard let entity = coreDataManager.meetingEntity else { return nil }
    let invite = NSManagedObject(entity: entity, insertInto: coreDataManager.managedContext)
    return invite
  }

  // MARK: - Lifecycle events
  override init() {
    super.init()
  }

  // MARK: - Private CRUD operations
  // DELETE
  private func delete(invite: NSManagedObject, _ completion: CoreDataResultsHandler) {
    coreDataManager.delete(object: invite) { (success, error) in
      completion(success, error)
    }
  }

  // CREATE
  private func create(jsonString: String, _ completion: @escaping (NSManagedObject?, Error?) -> Void) {
    guard let object = meeting else {
      completion(nil, RError.generalError.error)
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

  // READ
  private func retrieveInvites(_ completion: CoreDataHandler) {
    coreDataManager.retrieve(entityName: "MeetingEntity") { (objects, error) in
      completion(objects, error)
    }
  }

  // UPDATE


  // MARK: - Public methods
  func refreshMeetings() {
    loadInvites()
  }

  // MARK: - Public CRUD operations
  func deleteInvite(_ managedObject: NSManagedObject) {
    self.delegate?.willDeleteInvite(self)

    // Check if we can convert `NSManagedObject` into a `Meeting` object
    guard let meeting = MessageFactory.Meetings.coreDataToJson(managedObject) else {
      self.delegate?.didFailToLoad(self, error: RError.generalError.error)
      return
    }

    invites.removeAll { context -> Bool in
      if let managedobject = context.managedObject {
        return managedobject == managedObject
      }
      return false
    }
    
    delete(invite: managedObject) { (success, error) in
      if let err = error, success != true {
        self.delegate?.didFailToLoad(self, error: err)
      } else {
        let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: managedObject)
        self.delegate?.didDeleteInvite(self, invite: meetingWrapper)
        self.delegate?.didFinishLoading(self, invites: self.invites)
      }
    }
  }

  func createInvite(_ object: Meeting, _ completion: ((Bool, Error?) -> Void)?) {
    // Check if JSONString can be created from object
    guard let jsonString = object.toJSONString() else {
      let generalError = RError.generalError.error
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
          self.invites.append(meetingWrapper)
          self.delegate?.didFinishLoading(self, invites: self.invites)
          completion?(true, nil)
        } else {
          let generalError = RError.generalError.error
          self.delegate?.didFailToLoad(self, error: generalError)
          completion?(false, generalError)
        }
      }
    }
  }

  func loadInvites() {
    invites.removeAll()
    retrieveInvites { (results, error) in
      if let err = error {

        self.delegate?.didFailToLoad(self, error: err)

      } else {

        guard results != nil else {
          self.delegate?.didFailToLoad(self, error: RError.generalError.error)
          return
        }

        for result in results! {

          if
            // Check if meeting object can be deserialized
            let meeting = MessageFactory.Meetings.coreDataToJson(result),
            // Check that meeting has a start date
            let _ = meeting.meetingDate?.startDate?.toDate()?.date,
            // Check that meeting has an end date
            let endDate = meeting.meetingDate?.endDate?.toDate()?.date,
            // Check if meeting has an end date greater than today
            !endDate.timeIntervalSince(Date()).isLess(than: 0) {
            let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: result)
            self.invites.append(meetingWrapper)
          }
        }

        self.invites = self.invites.sorted(by: { (current, next) -> Bool in
          guard let cur = current.meeting, let curDate = cur.meetingDate?.startDate?.toDate()?.date, let nx = next.meeting, let nxDate = nx.meetingDate?.startDate?.toDate()?.date else {
            return false
          }
          return curDate.timeIntervalSince(nxDate).isLess(than: 0)
        })

        self.delegate?.didFinishLoading(self, invites: self.invites)
      }
    }
  }

}
