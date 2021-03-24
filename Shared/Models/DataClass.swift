// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let dataClass = try? newJSONDecoder().decode(DataClass.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import ObjectMapper
import Foundation

// MARK: - DataClass
public class DataClass: Mappable {
  var id: Int?
  var metaInformation: [String: Any]?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    metaInformation <- map["meta_information"]
  }
}
