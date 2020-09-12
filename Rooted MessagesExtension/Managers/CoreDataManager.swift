import Foundation
import CoreData

typealias CoreDataHandler = ([NSManagedObject]?, Error?) -> Void
typealias CoreDataResultsHandler = (Bool, Error?) -> Void

class CoreDataManager: NSObject {
  private lazy var applicationDocumentsDirectory: URL? = {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.yourdomain.YourAwesomeApp" in the application's documents Application Support directory.
    return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kGroupName) ?? nil
  }()

  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "Invites")
    //  Setup Core Data for communication via App Groups
    let storeURL = URL.storeURL(for: "group.com.rrtech.rooted.Rooted.MessagesExtension", databaseName: "Rooted")
    let storeDescription = NSPersistentStoreDescription(url: storeURL)
    container.persistentStoreDescriptions = [storeDescription]

    /*
     var persistentStoreDescriptions: NSPersistentStoreDescription

    let description = NSPersistentStoreDescription()
    description.shouldInferMappingModelAutomatically = true
    description.shouldMigrateStoreAutomatically = true
    description.url = applicationDocumentsDirectory ?? nil

    container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: applicationDocumentsDirectory!.appendingPathComponent("Rooted.sqlite"))]
     */

    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      } else {
        print("Successfully connected to store.")
      }
    })
    return container
  }()

  var managedContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }

  func saveContext() {
    if managedContext.hasChanges {
      do {
        try managedContext.save()
      } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }

  // MARK: - Meetings
  private var meetingEntity: NSEntityDescription? {
    let entity = NSEntityDescription.entity(forEntityName: "MeetingEntity", in: persistentContainer.viewContext)
    return entity
  }

  public var meetingManagedObject: NSManagedObject? {
    guard let entity = meetingEntity else { return nil }
    let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
    return managedObject
  }

  // MARK: - Meeting Drafts
  private var meetingDraftEntity: NSEntityDescription? {
    let entity = NSEntityDescription.entity(forEntityName: "MeetingDraftsEntity", in: persistentContainer.viewContext)
    return entity
  }

  public var meetingDraftManagedObject: NSManagedObject? {
    guard let entity = meetingDraftEntity else { return nil }
    let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
    return managedObject
  }

  // MARK: - Availability
  private var availabilityEntity: NSEntityDescription? {
    let entity = NSEntityDescription.entity(forEntityName: "AvailabilityEntity", in: persistentContainer.viewContext)
    return entity
  }

  public var availabilityManagedObject: NSManagedObject? {
    guard let entity = availabilityEntity else { return nil }
    let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
    return managedObject
  }

  // MARK: - Session
  private var sessionEntity: NSEntityDescription? {
    let entity = NSEntityDescription.entity(forEntityName: "SessionEntity", in: persistentContainer.viewContext)
    return entity
  }

  public var sessionManagedObject: NSManagedObject? {
    guard let entity = availabilityEntity else { return nil }
    let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
    return managedObject
  }

  // MARK: - Use Case: App needs to be able retrieve objects by entity name from core data
  func retrieve(entityName: String, _ completion: CoreDataHandler) {
    let sectionSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
    let sortDescriptors = [sectionSortDescriptor]

    let predicate = NSPredicate(format: "createdAt != nil")

    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = sortDescriptors
    do {
      let data = try managedContext.fetch(fetchRequest)
      completion(data, nil)
    } catch let error {
      print("Could not retrieve results. \(error.localizedDescription)")
      completion(nil, error)
    }
  }

  // MARK: - Use Case: Test this out
  func retrieveMeetingWith(id: String, entityName: String, _ completion: CoreDataHandler) {
    let sectionSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
    let sortDescriptors = [sectionSortDescriptor]

    let predicate = NSPredicate(format: "id == %@", id)

    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = sortDescriptors
    do {
      let data = try managedContext.fetch(fetchRequest)
      completion(data, nil)
    } catch let error {
      print("Could not retrieve results. \(error.localizedDescription)")
      completion(nil, error)
    }
  }

  // MARK: - Use Case: App needs to be able to delete managed objects from core data
  func delete(object: NSManagedObject, _ completion: CoreDataResultsHandler) {
    managedContext.delete(object)
    do {
      try managedContext.save()
      completion(true, nil)
    } catch let error {
      completion(false, error)
    }
  }
}

public extension URL {
  /// Returns a URL for the given app group and database pointing to the sqlite database.
  static func storeURL(for appGroup: String, databaseName: String) -> URL {
    guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
      fatalError("Shared file container could not be created.")
    }
    return fileContainer.appendingPathComponent("\(databaseName).sqlite")
  }
}
