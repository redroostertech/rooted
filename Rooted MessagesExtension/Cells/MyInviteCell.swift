import UIKit
import CoreData

// TODO: - Transform into a struct
public typealias InviteObject = NSManagedObject

protocol MyInviteCellDelegate: class {
  func trash(_ cell: UITableViewCell, invite: InviteObject?)
  func share(_ cell: UITableViewCell, invite: InviteObject?)
}

class MyInviteCell: UITableViewCell {
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var whereLabel: UILabel!
  @IBOutlet private var whenLabel: UILabel!
  @IBOutlet private var trashButton: UIButton!
  @IBOutlet private var shareButton: UIButton!

  private weak var delegate: MyInviteCellDelegate?
  private var invite: InviteObject? {
    didSet {
      guard let item = self.invite else { return }
      if let title = item.value(forKey: "title") as? String {
        titleLabel.text = title
      }
      if let locationName = item.value(forKey: "locationName") as? String {
        whereLabel.text = locationName
      }
      if let startDate = item.value(forKey: "startDate") as? Date, let endDate = item.value(forKey: "endDate") as? Date {
        whenLabel.text = startDate.toString(.rooted) + " to " + endDate.toString(.rooted)
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    trashButton.applyCornerRadius()
    contentView.backgroundColor = .clear
    backgroundColor = .clear
  }

  func configureCell(delegate: MyInviteCellDelegate?,
                     invite: InviteObject) {
    self.delegate = delegate
    self.invite = invite
  }

  @IBAction private func trashItem(_ sender: UIButton) {
    delegate?.trash(self, invite: invite)
  }

  @IBAction private func shareItem(_ sender: UIButton) {
    delegate?.share(self, invite: invite)
  }

}
