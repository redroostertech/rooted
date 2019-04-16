import Foundation
import CoreData

typealias CoreDataHandler = ([NSManagedObject]?, Error?) -> Void
typealias CoreDataResultsHandler = (Bool, Error?) -> Void

class CoreDataManager: NSObject {
    private lazy var applicationDocumentsDirectory: URL? = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.yourdomain.YourAwesomeApp" in the application's documents Application Support directory.
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rrtech.rooted.Rooted") ?? nil
    }()

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Invites")
        var persistentStoreDescriptions: NSPersistentStoreDescription

        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = applicationDocumentsDirectory ?? nil

        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: applicationDocumentsDirectory!.appendingPathComponent("Rooted.sqlite"))]

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Successfully connected to store.")
            }
        })
        return container
    }()

    var entity: NSEntityDescription? {
        let entity = NSEntityDescription.entity(forEntityName: "Invite", in: persistentContainer.viewContext)
        return entity
    }

    var managedContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext () {
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

    // MARK: - CRUD operations
    func retrieve(entityName: String, _ completion: CoreDataHandler) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        do {
            let data = try managedContext.fetch(fetchRequest)
            completion(data, nil)
        } catch let error {
            print("Could not retrieve results. \(error.localizedDescription)")
            completion(nil, error)
        }
    }

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
