//
//  RProgressHUD.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 1/22/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

public class RProgressHUD {

  private var hud: UIView?
  private var parent: UIView?

  init(on view: UIView?) {
    parent = view
  }

  public func show() {
    
    guard let appWindow = parent else { return }

    let spinnerView = UIView.init(frame: appWindow.bounds)
    spinnerView.backgroundColor = UIColor.gradientColor1.withAlphaComponent(0.75)
    let ai = UIActivityIndicatorView.init(style: .whiteLarge)
    ai.startAnimating()
    ai.center = spinnerView.center

    spinnerView.addSubview(ai)
    appWindow.addSubview(spinnerView)
    appWindow.bringSubviewToFront(spinnerView)

    hud = spinnerView
  }

  public func dismiss() {
    self.hud?.removeFromSuperview()
    self.hud = nil
  }
}
