// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let userProfileData = try? newJSONDecoder().decode(UserProfileData.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - UserProfileData
public class UserProfileData: Mappable {
  public var id: Int?
  public var firstName, lastName, fullName: String?
  public var accountTypeId, phoneNumberId: [Int]?
  public var location: RLocation?
  public var gender: Int?
  public var dob: String?
  public var userPreferences: [UserPreference]?
  public var notifications, cardOnFile: Bool?
  public var paymentInfoId, lastKnownCheckinIds: [Int]?
  public var dashboardSections: [UserProfileDataDashboardSection]?

  public var accountType: AccountType?
  public var phoneNumber: PhoneNumber?
  public var payment: PaymentInformation?
  public var checkIn: CheckIn?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    id <- map["id"]
    firstName <- map["first_name"]
    lastName <- map["last_name"]
    fullName <- map["full_name"]
    accountTypeId <- map["account_type_id"]
    phoneNumberId <- map["phone_number_id"]
    location <- map["location"]
    gender <- map["gender"]
    dob <- map["dob"]
    userPreferences <- map["user_preferences"]
    notifications <- map["notifications"]
    cardOnFile <- map["card_on_file"]
    paymentInfoId <- map["payment_info_id"]
    lastKnownCheckinIds <- map["last_known_checkin_ids"]
    dashboardSections <- map["dashboard_sections"]
    accountType <- map["account_type"]
    phoneNumber <- map["phone_number"]
    payment <- map["payment"]
    checkIn <- map["check_in"]
  }
}

// MARK: - User Profile Short
public class UserProfileShortData: Codable {
  public var id: Int?
  public var firstName, lastName, fullName: String?

  enum CodingKeys: String, CodingKey {
    case id
    case firstName = "first_name"
    case lastName = "last_name"
    case fullName = "full_name"
  }
}
