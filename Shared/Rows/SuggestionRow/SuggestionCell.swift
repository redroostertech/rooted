//
//  SuggestionCell.swift
//
//  Adapted from Mathias Claassen 4/14/16 by Hélène Martin 8/11/16
//
//

import Foundation
import UIKit
import Eureka

/// General suggestion cell. Create a subclass or use SuggestionCollectionCell or SuggestionTableCell.
open class SuggestionCell<T: SuggestionValue>: _FieldCell<T>, CellType {
    let cellReuseIdentifier = "Eureka.SuggestionCellIdentifier"
    var suggestions: [T]?
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .sentences
    }
    
    //MARK: UITextFieldDelegate
    open override func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let formviewcontroller = formViewController() as? FormMessagesAppViewController else { return }
        formviewcontroller.beginEditing(of: self)
        formviewcontroller.textInputDidBeginEditing(textField, cell: self)
        textField.selectAll(nil)
        
        if let text = textField.text {
            setSuggestions(text)
        }
    }
    
    open override func textFieldDidChange(_ textField: UITextField) {
        super.textFieldDidChange(textField)
        if let text = textField.text {
            setSuggestions(text)
        }

    }
    
    open override func textFieldDidEndEditing(_ textField: UITextField) {
        guard let formviewcontroller = formViewController() as? FormMessagesAppViewController else { return }
        formviewcontroller.endEditing(of: self)
        formviewcontroller.textInputDidEndEditing(textField, cell: self)
        textField.text = row.displayValueFor?(row.value)
    }

    func setSuggestions(_ string: String) {}
    
    func reload() {}
}
