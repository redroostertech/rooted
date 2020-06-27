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
    spinnerView.backgroundColor = UIColor.gradientColor1.withAlphaComponent(1.0)
    let ai = UIActivityIndicatorView.init(style: .whiteLarge)
    ai.startAnimating()
    ai.center = spinnerView.center

    let label = UILabel(frame: CGRect(x: spinnerView.center.x - CGFloat(62), y: spinnerView.center.y + CGFloat(50), width: CGFloat(124), height: CGFloat(24)))
    label.textColor = .white
    label.text = "Updating app..."

    spinnerView.addSubview(label)
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
