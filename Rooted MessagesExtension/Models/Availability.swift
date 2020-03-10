//
//  Availability.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 3/9/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import ObjectMapper

// MARK: - Meeting
public class Availability: Mappable {
  public var id: String?
  public var metaInformation: [String: Any]?
  public var availabilityOwnerId, availabilityName, availabilityDescription: String?
  public var availabilityDates: [MeetingDateClass]?
  public var createdAt, updatedAt: String?

  public var owner: UserProfileShortData?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    metaInformation <- map["meta_information"]
    owner <- map["owner"]
    availabilityOwnerId <- map["availability_owner_id"]
    availabilityName <- map["availability_name"]
    availabilityDescription <- map["availability_description"]
    availabilityDates <- map["availability_dates"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    metaInformation <- map["meta_information"]
    owner <- map["owner"]
  }
}
