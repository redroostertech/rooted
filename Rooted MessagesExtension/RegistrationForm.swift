//
//  RegistrationForm.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/3/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

protocol RootedFormDelegate: class {
  func didReturn(_ form: RegistrationForm, textField: UITextField)
  func didBeginEditing(_ form: RegistrationForm, textField: UITextField)
  func valueFrom(_ form: RegistrationForm, key: String, value: Any?)
  func form(_ form: RegistrationForm, error: Error)
  func didCancel(_ form: RegistrationForm)
}

class RegistrationForm: UIView {
  @IBOutlet weak var saveDisplayNameButton: UIButton!
  @IBOutlet weak var setDIsplayNameTextField: UITextField!

  // Our custom view from the XIB file
  var view: UIView!

  private weak var delegate: RootedFormDelegate?

  override init(frame: CGRect) {
    // 1. setup any properties here

    // 2. call super.init(frame:)
    super.init(frame: frame)

    // 3. Setup view from .xib file
    xibSetup()
  }

  required init?(coder aDecoder: NSCoder) {
    // 1. setup any properties here

    // 2. call super.init(coder:)
    super.init(coder: aDecoder)

    // 3. Setup view from .xib file
    xibSetup()
    //        self.view = loadViewFromNib() as! CustomView
  }

  func xibSetup() {
    view = loadViewFromNib()

    // use bounds not frame or it'll be offset
    view.frame = bounds

    // Make the view stretch with containing view
    view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]

    // Adding custom subview on top of our view (over any custom drawing > see note below)
    addSubview(view)
  }

  func loadViewFromNib() -> UIView {
    let bundle = Bundle(for: type(of:self))
    let nib = UINib(nibName: "RegistrationForm", bundle: bundle)

    // Assumes UIView is top level and only object in CustomView.xib file
    let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
    
    return view
  }

  func configure(delegate: RootedFormDelegate) {
    self.delegate = delegate
    setDIsplayNameTextField.delegate = self
  }

  @IBAction func saveDisplayName(_ sender: UIButton) {
    if setDIsplayNameTextField.text == nil {
      self.delegate?.form(self, error: RError.generalError.error)
      return
    }

    if setDIsplayNameTextField.text == "" {
      self.delegate?.form(self, error: RError.generalError.error)
      return
    }

    delegate?.valueFrom(self, key: "display_name", value: setDIsplayNameTextField.text!)

    self.removeFromSuperview()
  }

  @IBAction func cancelAction(_ sender: UIButton) {
    delegate?.didCancel(self)
    self.removeFromSuperview()
  }
}

extension RegistrationForm: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    delegate?.didBeginEditing(self, textField: textField)
    return true
  }
  func textFieldDidBeginEditing(_ textField: UITextField) {
    delegate?.didBeginEditing(self, textField: textField)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    delegate?.didReturn(self, textField: textField)
    return true
  }
}
