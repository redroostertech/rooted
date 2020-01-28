// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let phoneNumber = try? newJSONDecoder().decode(PhoneNumber.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - PhoneNumber
public class PhoneNumber: DataClass {
  public var ownerId, countryCode, areaCode: Int?
  public var phoneSh, fullPhone: Int?
  public var phoneString, createdAt, updatedAt: String?

  public var owner: UserProfileShortData?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    owner <- map["owner"]
    ownerId <- map["owner_id"]
    countryCode <- map["country_code"]
    areaCode <- map["area_code"]
    phoneSh <- map["phone_sh"]
    fullPhone <- map["full_phone"]
    phoneString <- map["phone_string"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    owner <- map["owner"]
  }
}
