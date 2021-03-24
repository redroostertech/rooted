// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let option = try? newJSONDecoder().decode(Option.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Option
public class Option: Mappable {
  public var id: Int?
  public var title: String?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    title <- map["title"]
  }
}
