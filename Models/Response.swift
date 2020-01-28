// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let response = try? newJSONDecoder().decode(Response.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Response
public class Response: Mappable {
  public var success: Bool?
  public var message, error: String?
  public var data: DataClass?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    success <- map["success"]
    message <- map["message"]
    error <- map["error"]
    data <- map["data"]
  }
}
