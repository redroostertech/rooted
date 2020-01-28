// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let action = try? newJSONDecoder().decode(Action.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Action
public class Action: Mappable {

  public var type, data: String?
  public var metaInformation: [JSONAny]?

  enum CodingKeys: String, CodingKey {
      case type, data
      case metaInformation = "meta_information"
  }

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    type <- map["type"]
    data <- map["data"]
    metaInformation <- map["meta_information"]
  }
}
