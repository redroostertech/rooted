//
//  ImageViewerCell.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 8/4/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit
import Foundation
import SDWebImage

public protocol ImageViewerRowProtocol: class {
    var imageString: String? { get set }
}

open class ImageViewerCell: Cell<String>, CellType {

  @IBOutlet weak public var imageForView: UIImageView!

  override open func awakeFromNib() {
    super.awakeFromNib()
  }

  public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    let imageForView = UIImageView()
    self.imageForView = imageForView
    self.imageForView.translatesAutoresizingMaskIntoConstraints = false

    super.init(style: style, reuseIdentifier: reuseIdentifier)

    self.contentView.addSubview(self.imageForView)
    self.imageForView.center = self.contentView.center
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  open override func setup() {
    super.setup()
    selectionStyle = .none
    accessoryType = .none
    editingAccessoryType =  .none
    height = { UITableView.automaticDimension }
    imageForView.backgroundColor = .gray
    imageForView.applyCornerRadius()
//      datePicker.datePickerMode = datePickerMode()
//      datePicker.addTarget(self, action: #selector(DatePickerCell.datePickerValueChanged(_:)), for: .valueChanged)
  }

  deinit {
//    imageForView?.removeTarget(self, action: nil, for: .allEvents)
  }

  open override func update() {
    super.update()
    selectionStyle = row.isDisabled ? .none : .default
    imageForView.isUserInteractionEnabled = !row.isDisabled
    imageForView?.image = nil

    // Update image
    imageForView?.sd_setImage(with: URL(string: (row as? ImageViewerRowProtocol)?.imageString ?? ""), placeholderImage: nil)
  }
}

open class _ImageViewerRow: Row<ImageViewerCell>, ImageViewerRowProtocol {

  open var imageString: String?

  required public init(tag: String?) {
    super.init(tag: tag)
    displayValueFor = nil
  }
}

/// A row with an Date as value where the user can select a date directly.
public final class ImageViewerRow: _ImageViewerRow, RowType {
  public required init(tag: String?) {
    super.init(tag: tag)
  }
}
