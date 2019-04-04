import UIKit
import CoreData

protocol MyInviteCellDelegate {
    func trash(_ cell: UITableViewCell)
    func share(_ cell: UITableViewCell)
}

class MyInviteCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var whereLabel: UILabel!
    @IBOutlet var whenLabel: UILabel!
    @IBOutlet var trashButton: UIButton!
    @IBOutlet var shareButton: UIButton!
    var delegate: MyInviteCellDelegate?
    var invite: NSManagedObject?
    override func awakeFromNib() {
        super.awakeFromNib()
        trashButton.applyCornerRadius()
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    @IBAction func trashItem(_ sender: UIButton) {
        delegate?.trash(self)
    }
    @IBAction func shareItem(_ sender: UIButton) {
        delegate?.share(self)
    }
}

extension MyInviteCell {
    static var identifier: String {
        return String(describing: MyInviteCell.self)
    }
}
