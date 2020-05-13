import UIKit
import ObjectMapper
import CoreData

public typealias AvailabilityManagerDataHandler = ([AvailabilityContextWrapper]?, Error?) -> Void
public typealias AvailabilityManageResultsHandler = (Bool, Error?) -> Void

protocol AvailabilityManagerDelegate: class {
  func willDeleteAvailability(_ manager: Any?)
  func didDeleteAvailability(_ manager: Any?, objects: AvailabilityContextWrapper)

  func didFinishLoading(_ manager: Any?, objects: [AvailabilityContextWrapper])
  func didFailToLoad(_ manager: Any?, error: Error)
}

extension AvailabilityManagerDelegate {
  func willDeleteAvailability(_ manager: Any?) { }
  func didDeleteAvailability(_ manager: Any?, objects: AvailabilityContextWrapper) { }

  func didFinishLoading(_ manager: Any?, objects: [AvailabilityContextWrapper]) { }
  func didFailToLoad(_ manager: Any?, error: Error) { }
}

public class AvailabilityContextWrapper {
  var object: Availability?
  var managedObject: NSManagedObject?
  init(object: Availability?, managedObject: NSManagedObject?) {
    self.object = object
    self.managedObject = managedObject
  }
  func getValue(for key: String) -> Any? {
    guard let managedKeys = managedObject?.entity.attributesByName.keys else { return nil }
    let keys = Array(managedKeys)
    guard let dict = managedObject?.dictionaryWithValues(forKeys: keys) else { return nil }
    return dict[key]
  }
}

extension AvailabilityContextWrapper: Equatable {
  public static func == (lhs: AvailabilityContextWrapper, rhs: AvailabilityContextWrapper) -> Bool {
    return lhs.object == rhs.object
  }
}

private let entityName = "AvailabilityEntity"

class AvailabilityManager: NSObject {

  // MARK: - Private Properties
  private var coreDataManager = CoreDataManager()
  private var availability = [AvailabilityContextWrapper]()

  // MARK: - Public properties
  weak var delegate: AvailabilityManagerDelegate?

  // MARK: - Use Case: As a business, we want to limit access to creating availability beyond  a certain date than (n) based on account type

  // MARK: - Use Case: Retrieve availability for user
  func retrieveAvailability() {
    availability.removeAll()
    retrieveObjects { (results, error) in
      if let err = error {
        self.delegate?.didFailToLoad(self, error: err)
      } else {
        guard results != nil else {
          self.delegate?.didFailToLoad(self, error: RError.generalError)
          return
        }
        for result in results! {
          if
            // Check if availability object can be deserialized
            let availability = EngagementFactory.AvailabilityFactory.coreDataToJson(result),
            // Check that meeting has dates
            let availabilityDates = availability.availabilityDates,
            let firstAvailability = availabilityDates.first,
            let firstAvailabilityDate = firstAvailability.endDate?.toDate()?.date,
            // Check if availability has an end date greater than today
            !firstAvailabilityDate.timeIntervalSince(Date()).isLess(than: 0) {
            let availabilityWrapper = AvailabilityContextWrapper(object: availability, managedObject: result)
            self.availability.append(availabilityWrapper)
          }
        }
        self.delegate?.didFinishLoading(self, objects: self.availability)
      }
    }
  }

  private func retrieveObjects(_ completion: CoreDataHandler) {
    coreDataManager.retrieve(entityName: entityName) { (objects, error) in
      completion(objects, error)
    }
  }

  // MARK: - Use Case: Create availability
  func createAvailability(_ object: Availability, _ completion: ((Bool, Error?) -> Void)?) {
    // Check if JSONString can be created from object
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
          let availabilityWrapper = AvailabilityContextWrapper(object: object, managedObject: managedobject)
          self.availability.append(availabilityWrapper)
          self.delegate?.didFinishLoading(self, objects: self.availability)
          completion?(true, nil)
        } else {
          let generalError = RError.generalError
          self.delegate?.didFailToLoad(self, error: generalError)
          completion?(false, generalError)
        }
      }
    }
  }

  private func create(jsonString: String, _ completion: @escaping (NSManagedObject?, Error?) -> Void) {
    guard let object = coreDataManager.availabilityManagedObject else {
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

  // MARK: - Use Case: Delete availability
  func deleteAvailability(_ managedObject: NSManagedObject) {
    self.delegate?.willDeleteAvailability(self)

    // Check if we can convert `NSManagedObject` into a `Meeting` object
    guard let object = EngagementFactory.AvailabilityFactory.coreDataToJson(managedObject) else {
      self.delegate?.didFailToLoad(self, error: RError.generalError)
      return
    }

    availability.removeAll { context -> Bool in
      if let managedobject = context.managedObject {
        return managedobject == managedObject
      }
      return false
    }

    delete(invite: managedObject) { (success, error) in
      if let err = error, success != true {
        self.delegate?.didFailToLoad(self, error: err)
      } else {
        let availabilityWrapper = AvailabilityContextWrapper(object: object, managedObject: managedObject)
        self.delegate?.didDeleteAvailability(self, objects: availabilityWrapper)
        self.delegate?.didFinishLoading(self, objects: self.availability)
      }
    }
  }

  private func delete(invite: NSManagedObject, _ completion: CoreDataResultsHandler) {
    coreDataManager.delete(object: invite) { (success, error) in
      completion(success, error)
    }
  }

  // UPDATE

  // MARK: - Public methods
  func refresh() {
//    loadData()
  }

}
