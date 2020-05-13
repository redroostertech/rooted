
//
//  NavigationCoordinator.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 4/30/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Messages

final class NavigationCoordinator {
  static func performExpandedNavigation(from: BaseAppViewController, _ completion: @escaping () -> Void) {
    from.requestPresentationStyle(.expanded)
    completion()
  }

  static func performCompactNavigation(from: BaseAppViewController, _ completion: @escaping () -> Void) {
    from.requestPresentationStyle(.compact)
    completion()
  }
}
