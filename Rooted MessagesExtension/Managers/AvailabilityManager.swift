import UIKit
import CoreData

protocol AvailabilityDelegate: class {
  func willDelete(_ manager: Any?)
  func didDelete(_ manager: Any?, objects: AvailabilityContextWrapper)

  func willRefresh(_ manager: Any?)
  func didRefresh(_ manager: Any?, objects: [AvailabilityContextWrapper])
  func didFailRefreshing(_ manager: Any?, error: Error)

  func didFinishLoading(_ manager: Any?, objects: [AvailabilityContextWrapper])
  func didFailToLoad(_ manager: Any?, error: Error)
}

public typealias AvailabilityManagerDataHandler = ([AvailabilityContextWrapper]?, Error?) -> Void
public typealias AvailabilityManageResultsHandler = (Bool, Error?) -> Void

public class AvailabilityContextWrapper {
  var object: Availability?
  var managedObject: NSManagedObject?
  init(object: Availability?, managedObject: NSManagedObject?) {
    self.object = object
    self.managedObject = managedObject
  }
}

private let entityName = "AvailabilityEntity"

class AvailabilityManager: NSObject {

  // MARK: - Private Properties
  private var coreDataManager = CoreDataManager()
  private var contextWrappers = [AvailabilityContextWrapper]()

  // MARK: - Public properties
  weak var delegate: AvailabilityDelegate?

  // MARK: - Computed properties
  // Entities
  var managedObject: NSManagedObject? {
    guard let entity = coreDataManager.availabilityEntity else { return nil }
    let object = NSManagedObject(entity: entity, insertInto: coreDataManager.managedContext)
    return object
  }

  // MARK: - Lifecycle events
  override init() {
    super.init()
  }

  // MARK: - Private methods
  private func retrieveObjects(_ completion: CoreDataHandler) {
    coreDataManager.retrieve(entityName: entityName) { (objects, error) in
      completion(objects, error)
    }
  }

  private func deleteObject(_ object: NSManagedObject, _ completion: CoreDataResultsHandler) {
    coreDataManager.delete(object: object) { (success, error) in
      completion(success, error)
    }
  }

  // MARK: - Public methods
  func loadData() {
    retrieveObjects { (results, error) in
      if let err = error {
        self.delegate?.didFailToLoad(self, error: err)
      } else {
        guard results != nil else {
          self.delegate?.didFailToLoad(self, error: RError.generalError.error)
          return
        }
        for result in results! {
          if let object = DataConverter.Availabilities.coreDataToJson(result) {
            let contextWrapper = AvailabilityContextWrapper(object: object, managedObject: result)
            self.contextWrappers.append(contextWrapper)
          }
        }
        self.delegate?.didFinishLoading(self, objects: self.contextWrappers)
      }
    }
  }

  // MARK: - CRUD operations
  // Meetings
  func delete(_ managedObject: NSManagedObject) {
    self.delegate?.willDelete(self)

    // Check if we can convert `NSManagedObject` into a `Availability` object
    guard let object = DataConverter.Availabilities.coreDataToJson(managedObject) else {
      self.delegate?.didFailRefreshing(self, error: RError.generalError.error)
      return
    }

    // Remove managed object staged for deletion from contextWrapper array
    contextWrappers.removeAll { context -> Bool in
      if let managedobject = context.managedObject {
        return managedobject == managedObject
      }
      return false
    }

    // Delete managed object from core data
    deleteObject(managedObject) { (success, error) in
      if let err = error, success != true {
        self.delegate?.didFailRefreshing(self, error: err)
      } else {

        // Create a context wrapper
        let contextWrapper = AvailabilityContextWrapper(object: object, managedObject: managedObject)
        self.delegate?.didDelete(self, objects: contextWrapper)
        self.delegate?.didRefresh(self, objects: self.contextWrappers)
      }
    }
  }

  func refresh() {
    self.delegate?.willRefresh(self)

    // Remove all context wrappers
    contextWrappers.removeAll()

    // Retrieve managed objects
    retrieveObjects { (results, error) in
      if let err = error {
        self.delegate?.didFailRefreshing(self, error: err)
      } else {
        guard results != nil else {
          self.delegate?.didFailRefreshing(self, error: RError.generalError.error)
          return
        }
        for result in results! {
          if let object = DataConverter.Availabilities.coreDataToJson(result) {
            let contextWrapper = AvailabilityContextWrapper(object: object, managedObject: result)
            self.contextWrappers.append(contextWrapper)
          }
        }
        self.delegate?.didFinishLoading(self, objects: self.contextWrappers)
      }
    }
  }

  func save(_ object: Availability, _ completion: InvitesManageResultsHandler) {
    guard let managedobject = self.managedObject, let objectString = object.toJSONString()  else {
      completion(false, nil)
      return
    }

    let referenceDate = Date()

    managedobject.setValuesForKeys([
      "id": RanStringGen(length: 10).returnString(),
      "object": objectString,
      "createdAt": referenceDate,
      "updatedAt": referenceDate
      ])

    do {
      try coreDataManager.managedContext.save()
      let contextWrapper = AvailabilityContextWrapper(object: object, managedObject: managedobject)
      contextWrappers.append(contextWrapper)
      completion(true, nil)
    } catch let error {
      completion(false, error)
    }
  }
}
