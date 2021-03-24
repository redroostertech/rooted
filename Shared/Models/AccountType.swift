// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let accountType = try? newJSONDecoder().decode(AccountType.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - AccountType
public class AccountType: DataClass {
  public var maxDashboardSectionsCount, yearlyFee, monthlyFee, maximumEventsCount: Int?
  public var createdAt, updatedAt, key, yearlySubscriptionId, monthlySubscriptionId: String?

  required public init?(map: Map) {
    super.init(map: map)
  }

  public override func mapping(map: Map) {
    super.mapping(map: map)
    id <- map["id"]
    yearlyFee <- map["yearly_fee"]
    yearlySubscriptionId <- map["yearly_subscription_id"]
    monthlyFee <- map["monthly_fee"]
    monthlySubscriptionId <- map["monthly_subscription_id"]
    maxDashboardSectionsCount <- map["max_dashboard_sections_count"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    key <- map["key"]
  }
}
