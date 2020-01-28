// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let media = try? newJSONDecoder().decode(Media.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - Media
public class Media: DataClass {
  public var order: Int?
  public var fileName, fileType, fileUrl, fileThumbnailUrl: String?
  public var ownerId: Int?
  public var createdAt, updatedAt: String?

  public var owner: UserProfileShortData?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    order <- map["order"]
    fileName <- map["file_name"]
    fileType <- map["file_type"]
    fileUrl <- map["file_url"]
    fileThumbnailUrl <- map["file_thumbnail_url"]
    ownerId <- map["owner_id"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    owner <- map["owner"]
  }
}
