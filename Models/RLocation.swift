// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let ation = try? newJSONDecoder().decode(Ation.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Location
public class RLocation: Mappable {
  public var address1, address2, address3, address4: String?
  public var city, state, stateSh, zipCode: String?
  public var coordinates: Coordinates?
  public var metaInformation: [String: Any]?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    address1 <- map["address_1"]
    address2 <- map["address_2"]
    address3 <- map["address_3"]
    address4 <- map["address_4"]
    city <- map["city"]
    state <- map["state"]
    stateSh <- map["state_sh"]
    zipCode <- map["zip_code"]
    coordinates <- map["coordinates"]
    metaInformation <- map["meta_information"]
  }

}
