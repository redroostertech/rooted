import UIKit
import CoreData

protocol MyInvitesDelegate: class {
  func willDeleteInvite(_ manager: Any)
  func didDeleteInvite(_ manager: Any)

  func willRefreshInvites(_ manager: Any)
  func didRefreshInvites(_ manager: Any)
  func didFailRefreshingInvites(_ manager: Any, error: Error)

  func didFinishLoading(_ manager: Any)
  func didFailToLoad(_ manager: Any, error: Error)
}

private let maximumInvites = 3

class MyInvitesManager: NSObject {

  // MARK: - Private Properties
  private var coreDataManager = CoreDataManager()
  private var invites = [NSManagedObject]()

  var invite: NSManagedObject? {
      guard let entity = coreDataManager.entity else { return nil }
      let invite = NSManagedObject(entity: entity, insertInto: coreDataManager.managedContext)
      return invite
  }

  // MARK: - Public properties
  weak var cellDelegate: MyInviteCellDelegate?
  weak var invitesDelegate: MyInvitesDelegate?

  // MARK: - Lifecycle events
  override init() {
    super.init()
  }

  // MARK: - Private methods
  private func retrieveInvites(_ completion: CoreDataHandler) {
    coreDataManager.retrieve(entityName: "Invite") { (objects, error) in
      completion(objects, error)
    }
  }

  private func deleteInvite(_ invite: NSManagedObject, _ completion: CoreDataResultsHandler) {
    coreDataManager.delete(object: invite) { (success, error) in
      completion(success, error)
    }
  }

  // MARK: - Public methods
  func isMaximumReached() -> Bool {
    return invites.count >= maximumInvites
  }

  func loadData() {
    retrieveInvites { (results, error) in
      if let err = error {
        self.invitesDelegate?.didFailToLoad(self, error: err)
      } else {
        guard let res = results else {
          self.invitesDelegate?.didFinishLoading(self)
          return
        }
        invites.append(contentsOf: res)
        self.invitesDelegate?.didFinishLoading(self)
      }
    }
  }

  // MARK: - CRUD operations
  func deleteInvite(_ invite: InviteObject, atIndex index: Int) {
    self.invitesDelegate?.willDeleteInvite(self)
    invites.remove(at: index)
    deleteInvite(invite) { (success, error) in
      if let err = error, success != true {
        self.invitesDelegate?.didFailRefreshingInvites(self, error: err)
      } else {
        self.invitesDelegate?.didDeleteInvite(self)
      }
    }
  }

  func refreshInvites() {
    self.invitesDelegate?.willRefreshInvites(self)
    invites.removeAll()
    retrieveInvites { (results, error) in
      if let err = error {
        self.invitesDelegate?.didFailRefreshingInvites(self, error: err)
      } else {
        guard let res = results else { return }
        invites.append(contentsOf: res)
        self.invitesDelegate?.didRefreshInvites(self)
      }
    }
  }

  func save(title: String, endDate: Date, startDate: Date, location: RLocation?, _ completion: (Bool, Error?) -> Void) {
    guard let invite = self.invite else {
      completion(false, nil)
      return
    }

    invite.setValuesForKeys([
      kMessageEndDateKey: endDate,
      kMessageStartDateKey: startDate,
      kMessageTitleKey: title,
    ])

    if let loc = location?.toJSON().convertToJsonString() {
      invite.setValue(loc, forKey: kMessageLocationStringKey)
    }

    do {
      try coreDataManager.managedContext.save()
      invites.append(invite)
      completion(true, nil)
    } catch let error {
      completion(false, error)
    }
  }
}

// MARK: - UITableView delegate and datasource
extension MyInvitesManager: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MyInviteCell.identifier) as? MyInviteCell else {
            return UITableViewCell()
        }
      let item = invites[indexPath.row]
        cell.tag = indexPath.row
        cell.configureCell(delegate: cellDelegate,
                           invite: item)
        return cell
    }
}
