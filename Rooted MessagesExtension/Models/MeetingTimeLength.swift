//
//  MeetingTimeLength.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import ObjectMapper

class MeetingTimeLength: Mappable {
  var id: Int?
  var length: Int?
  var name: String?
  var type: String?

  required init?(map: Map) { }

  func mapping(map: Map) {
    id <- map["id"]
    length <- map["length"]
    name <- map["name"]
    type <- map["type"]
  }
}

extension MeetingTimeLength: Equatable {
  static func == (lhs: MeetingTimeLength, rhs: MeetingTimeLength) -> Bool {
    return lhs.id == rhs.id
  }
}
