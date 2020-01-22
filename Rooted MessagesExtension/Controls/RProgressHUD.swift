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

  internal static var hud: UIView?

  public static func show(on view: UIView?) {
    guard let appWindow = view else { return }

    let spinnerView = UIView.init(frame: appWindow.bounds)
    spinnerView.backgroundColor = UIColor.gradientColor1.withAlphaComponent(0.75)
    let ai = UIActivityIndicatorView.init(style: .whiteLarge)
    ai.startAnimating()
    ai.center = spinnerView.center

    DispatchQueue.main.async {
      spinnerView.addSubview(ai)
      appWindow.addSubview(spinnerView)
      appWindow.bringSubviewToFront(spinnerView)
    }

    RProgressHUD.hud = spinnerView
  }

  public static func dismiss() {
    DispatchQueue.main.async {
      RProgressHUD.hud?.removeFromSuperview()
      RProgressHUD.hud = nil
    }
  }
}
