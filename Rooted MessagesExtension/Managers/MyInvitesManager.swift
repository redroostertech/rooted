import UIKit
import CoreData

protocol MyInvitesDelegate: class {
  func willDeleteInvite(_ manager: Any?)
  func didDeleteInvite(_ manager: Any?, invite: MeetingContextWrapper)

  func willRefreshInvites(_ manager: Any?)
  func didRefreshInvites(_ manager: Any?, invites: [MeetingContextWrapper])
  func didFailRefreshingInvites(_ manager: Any?, error: Error)

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

class MyInvitesManager: NSObject {

  // MARK: - Private Properties
  private var coreDataManager = CoreDataManager()
  private var invites = [MeetingContextWrapper]()

  // MARK: - Public properties
  weak var invitesDelegate: MyInvitesDelegate?

  // MARK: - Computed properties

  // Core
  var maximumReached: Bool {
    return invites.count >= maximumInvites
  }

  // Entities
  var invite: NSManagedObject? {
    guard let entity = coreDataManager.inviteEntiry else { return nil }
    let invite = NSManagedObject(entity: entity, insertInto: coreDataManager.managedContext)
    return invite
  }

  var meeting: NSManagedObject? {
    guard let entity = coreDataManager.meetingEntity else { return nil }
    let invite = NSManagedObject(entity: entity, insertInto: coreDataManager.managedContext)
    return invite
  }

  // MARK: - Lifecycle events
  override init() {
    super.init()
  }

  // MARK: - Private methods
  private func retrieveInvites(_ completion: CoreDataHandler) {
    coreDataManager.retrieve(entityName: "MeetingEntity") { (objects, error) in
      completion(objects, error)
    }
  }

  private func deleteInvite(_ invite: NSManagedObject, _ completion: CoreDataResultsHandler) {
    coreDataManager.delete(object: invite) { (success, error) in
      completion(success, error)
    }
  }

  // MARK: - Public methods
  func loadData() {
    retrieveInvites { (results, error) in
      if let err = error {

        self.invitesDelegate?.didFailToLoad(self, error: err)

      } else {

        guard results != nil else {
          self.invitesDelegate?.didFailToLoad(self, error: RError.generalError.error)
          return
        }

        for result in results! {

          if let meeting = DataConverter.Meetings.coreDataToJson(result) {
            let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: result)
            self.invites.append(meetingWrapper)
          }
        }

        self.invitesDelegate?.didFinishLoading(self, invites: self.invites)
      }
    }
  }

  // MARK: - CRUD operations
  // Meetings
  func deleteMeeting(_ managedObject: NSManagedObject) {
    self.invitesDelegate?.willDeleteInvite(self)

    // Check if we can convert `NSManagedObject` into a `Meeting` object
    guard let meeting = DataConverter.Meetings.coreDataToJson(managedObject) else {
      self.invitesDelegate?.didFailRefreshingInvites(self, error: RError.generalError.error)
      return
    }

    invites.removeAll { context -> Bool in
      if let managedobject = context.managedObject {
        return managedobject == managedObject
      }
      return false
    }
    
    deleteInvite(managedObject) { (success, error) in
      if let err = error, success != true {
        self.invitesDelegate?.didFailRefreshingInvites(self, error: err)
      } else {
        let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: managedObject)
        self.invitesDelegate?.didDeleteInvite(self, invite: meetingWrapper)
        self.invitesDelegate?.didRefreshInvites(self, invites: self.invites)
      }
    }
  }

  func refreshMeetings() {
    self.invitesDelegate?.willRefreshInvites(self)

    invites.removeAll()

    retrieveInvites { (results, error) in
      if let err = error {
        self.invitesDelegate?.didFailRefreshingInvites(self, error: err)
      } else {

        guard results != nil else {
          self.invitesDelegate?.didFailRefreshingInvites(self, error: RError.generalError.error)
          return
        }

        for result in results! {

          if let meeting = DataConverter.Meetings.coreDataToJson(result) {
            let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: result)
            self.invites.append(meetingWrapper)
          }
        }

        self.invitesDelegate?.didRefreshInvites(self, invites: self.invites)
      }
    }
  }

  func save(meeting: Meeting, _ completion: InvitesManageResultsHandler) {
    guard let object = self.meeting, let objectString = meeting.toJSONString()  else {
      completion(false, nil)
      return
    }

    let referenceDate = Date()

    object.setValuesForKeys([
      "id": RanStringGen(length: 10).returnString(),
      "object": objectString,
      "createdAt": referenceDate,
      "updatedAt": referenceDate
      ])
    
    do {
      try coreDataManager.managedContext.save()
      let meetingWrapper = MeetingContextWrapper(meeting: meeting, managedObject: object)
      invites.append(meetingWrapper)
      completion(true, nil)
    } catch let error {
      completion(false, error)
    }
  }
}
