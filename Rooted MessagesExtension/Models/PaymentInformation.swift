// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let paymentInformation = try? newJSONDecoder().decode(PaymentInformation.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation
import ObjectMapper

// MARK: - PaymentInformation
public class PaymentInformation: Mappable {
  public var customerId, lastFour, brand, preferredCurrency: String?
  public var shippingInformation, billingInformation: RLocation?
  public var createdAt, updatedAt: String?
  public var metaInformation: [String: Any]?

  required public init?(map: Map) { }

  public func mapping(map: Map) {
    customerId <- map["customer_id"]
    lastFour <- map["last_four"]
    brand <- map["brand"]
    shippingInformation <- map["shipping_information"]
    billingInformation <- map["billing_information"]
    createdAt <- map["created_at"]
    updatedAt <- map["updated_at"]
    metaInformation <- map["meta_information"]
    preferredCurrency <- map["preferred_currency"]
  }
}
