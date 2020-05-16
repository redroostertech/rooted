//
//  ListViewSection.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

public let kListViewSectionSize: CGFloat = 50.0

public enum ListViewSection {

  typealias RawValue = String

  // These are the meetings that you received from other users on the platform but have not given a response to, nor viewed the invite
  case incoming

  // These are meetings that are happening today, in order of start time
  case today

  // These are meetings that are happening tomorrow in order of start date and time
  case tomorrow

  case sent

  case none
  case custom(String)

  var rawValue: RawValue {
    switch self {
    case .incoming: return "incoming"
    case .today: return "today"
    case .tomorrow: return "tomorrow"
    case .sent: return "sent"
    case .none: return ""
    case .custom(let value) where value != "incoming" || value != "today" || value != "tomorrow" || value != "" : return value
    default: fatalError("ListViewSection is not valid")
    }
  }

  var title: String {
    switch self {
    case .custom(let value):
      return value
    case .incoming:
      return "Incoming Invites"
    case .today:
      return "Today' Invites"
    case .tomorrow:
      return "Tomorrow's Invites"
    case .sent:
      return "Sent Invites"
    case .none: return ""
    }
  }

  var headerView: UIView {
    switch self {
    case .incoming, .tomorrow, .today, .sent:
      let view = UIView(frame: CGRect(x: .zero, y: .zero, width: UIScreen.main.bounds.width, height: kListViewSectionSize))
      view.backgroundColor = .white
      let titleLabel = UILabel(frame: view.frame)
      titleLabel.text = self.title
      view.addSubview(titleLabel)
      return view
    case .none:
      return UIView(frame: CGRect(x: .zero, y: .zero, width: UIScreen.main.bounds.width, height: .zero))
    case .custom(let value):
      let view = UIView(frame: CGRect(x: .zero, y: .zero, width: UIScreen.main.bounds.width, height: kListViewSectionSize))
      view.backgroundColor = .white
      let titleLabel = UILabel(frame: view.frame)
      titleLabel.text = value
      view.addSubview(titleLabel)
      return view
    }
  }

  var reusableView: UICollectionReusableView {
    switch self {
    case .incoming, .tomorrow, .today, .sent:
      let view = UICollectionReusableView(frame: CGRect(x: .zero, y: .zero, width: UIScreen.main.bounds.width, height: kListViewSectionSize))
      view.backgroundColor = .white
      let titleLabel = UILabel(frame: view.frame)
      titleLabel.text = self.title
      view.addSubview(titleLabel)
      return view
    case .none:
      return UICollectionReusableView(frame: CGRect(x: .zero, y: .zero, width: UIScreen.main.bounds.width, height: .zero))
    case .custom(let value):
      let view = UICollectionReusableView(frame: CGRect(x: .zero, y: .zero, width: UIScreen.main.bounds.width, height: kListViewSectionSize))
      view.backgroundColor = .white
      let titleLabel = UILabel(frame: view.frame)
      titleLabel.text = value
      view.addSubview(titleLabel)
      return view
    }
  }
}

extension ListViewSection: Hashable, Equatable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }

  public static func ==(lhs: ListViewSection, rhs: ListViewSection) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

