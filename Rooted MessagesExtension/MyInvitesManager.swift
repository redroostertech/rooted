import UIKit
import CoreData

class MyInvitesManager: NSObject {

    var invite: NSManagedObject? {
        guard let entity = coreDataManager.entity else { return nil }
        let invite = NSManagedObject(entity: entity, insertInto: coreDataManager.managedContext)
        return invite
    }
    var invites: [NSManagedObject]?
    var coreDataManager = CoreDataManager()
    var delegate: MyInviteCellDelegate?

    override init() {
        super.init()
        retrieveInvites { (results, error) in
            if let err = error {
                print("There was an error. Error message: \(err.localizedDescription)")
                fatalError(err.localizedDescription)
            } else {
                invites = results
            }
        }
    }

    func checkCount() -> Int? {
        return invites?.count
    }

    func removeInvite(atIndex index: Int) {
        invites?.remove(at: index)
    }

    func refreshInvites(_ completion: @escaping () -> Void) {
        retrieveInvites { (results, error) in
            if let err = error {
                print("There was an error. Error message: \(err.localizedDescription)")
                fatalError(err.localizedDescription)
                completion()
            } else {
                invites = results
                completion()
            }
        }
    }

    // MARK: - CoreData manager
    private func retrieveInvites(_ completion: CoreDataHandler) {
        coreDataManager.retrieve(entityName: "Invite") { (objects, error) in
            completion(objects, error)
        }
    }

    func deleteInvite(_ invite: NSManagedObject, _ completion: CoreDataResultsHandler) {
        coreDataManager.delete(object: invite) { (success, error) in
            completion(success, error)
        }
    }

    func saveInvite(endDate: Date,
                    locationAddress: String,
                    locationCity: String,
                    locationCountry: String,
                    locationLat: Double,
                    locationLon: Double,
                    locationName: String,
                    locationState: String,
                    locationStreet: String,
                    locationZip: String,
                    startDate: Date,
                    title: String,
                    _ completion: (Bool, Error?) -> Void) {
        guard let invite = self.invite else {
            completion(false, nil)
            return
        }
        invite.setValuesForKeys([
            "endDate": endDate,
            "locationAddress": locationAddress,
            "locationCity": locationCity,
            "locationCountry": locationCountry,
            "locationLat": locationLat,
            "locationLon": locationLon,
            "locationName": locationName,
            "locationState": locationState,
            "locationStreet": locationStreet,
            "locationZip": locationZip,
            "startDate": startDate,
            "title": title,
            ])

        do {
            try coreDataManager.managedContext.save()
            invites?.append(invite)
            completion(true, nil)
        } catch let error {
            completion(false, error)
        }
    }
}

// MARK: - UITableView delegate and datasource
extension MyInvitesManager: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkCount() ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MyInviteCell.identifier) as? MyInviteCell, let invites = self.invites else {
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        cell.delegate = delegate
        let item = invites[indexPath.row]
        if let title = item.value(forKey: "title") as? String {
            cell.titleLabel?.text = title
        }
        if let locationName = item.value(forKey: "locationName") as? String {
            cell.whereLabel?.text = locationName
        }
        if let startDate = item.value(forKey: "startDate") as? Date, let endDate = item.value(forKey: "endDate") as? Date {
            cell.whenLabel?.text = startDate.toString(.rooted) + " to " + endDate.toString(.rooted)
        }
        return cell
    }
}
