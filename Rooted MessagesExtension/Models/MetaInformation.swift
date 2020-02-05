// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let metaInformation = try? newJSONDecoder().decode(MetaInformation.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - MetaInformation
public class MetaInformation: Mappable {

  public var options: [Option]?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    options <- map["options"]
  }
  
}
