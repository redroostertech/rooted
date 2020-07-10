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
import MapKit

// MARK: - Location
public class RLocation: Mappable, SuggestionValue {
  public var name, address1, address2, address3, address4: String?
  public var city, state, stateAbbr, zipCode, country: String?
  public var coordinates: Coordinates?
  public var metaInformation: [String: Any]?

  public var mapItem: MKMapItem?

  public var readableWhereString: String {
    var string = ""
    if let name = self.name {
      string += name
    }

    if self.readableAddres != "" {
      string += " at \(self.readableAddres)"
    }
    return string
  }

  public var readableAddres: String {
    var addressString = ""
    if let address1 = self.address1 {
      addressString += address1
    }

    if self.city != nil || self.state != nil || self.zipCode != nil {
      addressString += " "

      if let city = self.city {
        addressString += city
        if self.state != nil {
          addressString += ", "
        }
      }

      if let state = self.state {
        addressString += state
      }

      if let zip = self.zipCode {
        addressString += zip
      }

    }
    return addressString
  }

  // Text that is displayed as a completion suggestion.
  public var suggestionString: String {
    return "\(readableAddres)"
  }
  
  required public init?(map: Map) { }

  // Required by `InputTypeInitiable`, can always return nil in the SuggestionValue context.
  required convenience public init?(string stringValue: String) {
    return nil
  }

  public func mapping(map: Map) {
    name <- map["name"]
    address1 <- map["address_line_1"]
    address2 <- map["address_line_2"]
    address3 <- map["address_line_3"]
    address4 <- map["address_line_4"]
    city <- map["address_city"]
    state <- map["address_state"]
    stateAbbr <- map["address_state_sh"]
    country <- map["address_country"]
    zipCode <- map["address_zip"]
    coordinates <- map["address_coordinates"]
    metaInformation <- map["meta_information"]
  }

}

extension RLocation: Equatable {
  public static func == (lhs: RLocation, rhs: RLocation) -> Bool {
    return lhs.coordinates?.lat == rhs.coordinates?.lat && lhs.coordinates?.long == rhs.coordinates?.long
  }
}
