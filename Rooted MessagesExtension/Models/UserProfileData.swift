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
  public var id: String?
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
  public var id: String?
  public var firstName, lastName, fullName: String?

  enum CodingKeys: String, CodingKey {
    case id
    case firstName = "first_name"
    case lastName = "last_name"
    case fullName = "full_name"
  }
}

extension UserProfileData {
  static var anonymousUser: UserProfileData? {
    let dict: [String: Any] = [
      "first_name": "",
      "last_name": "",
      "full_name": "",
      "account_type_id": [0],
      "user_preferences": [
        [
          "preference_id": 0,
          "preference_selection_id": 0,
          "meta_information": [],
          "preference": [
            "priority": 0,
            "minimum_user_type_required": 0,
            "id": 0,
            "title": "Notifications",
            "type": "boolean",
            "description": "Enable push notifications",
            "is_on": true,
            "action" : [
              "type": "URL",
              "data": "www.google.com"
            ],
            "choices": [
              [
                "order": 0,
                "id": 0,
                "title": "true",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],
              [
                "order": 1,
                "id": 1,
                "title": "false",
                "meta_information": [],
                "minimum_user_type_required": 0
              ]
            ],
            "created_at": "",
            "updated_at": ""
          ]
        ],
        [
          "preference_id": 1,
          "preference_selection_id": 0,
          "meta_information": [],
          "preference": [
            "priority": 0,
            "minimum_user_type_required": 0,
            "id": 1,
            "title": "Location",
            "description": "Allow access to your location?",
            "is_on": true,
            "action" : [
              "type": "URL",
              "data": "www.google.com",
              "meta_information": []
            ],
            "type": "boolean",
            "choices": [
              [
                "order": 0,
                "id": 0,
                "title": "true",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],
              [
                "order": 1,
                "id": 1,
                "title": "false",
                "meta_information": [],
                "minimum_user_type_required": 0
              ]
            ],
            "created_at": "",
            "updated_at": ""
          ]
        ],
        [
          "preference_id": 2,
          "preference_selection_id": 0,
          "meta_information": [],
          "preference": [
            "priority": 0,
            "minimum_user_type_required": 0,
            "id": 2,
            "title": "Start of the Week",
            "description": "",
            "is_on": false,
            "action" : [
              "type": "URL",
              "data": "www.google.com",
              "meta_information": []
            ],
            "type": "picker",
            "choices": [
              [
                "order": 0,
                "id": 0,
                "title": "Sunday",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 1,
                "id": 1,
                "title": "Monday",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 2,
                "id": 2,
                "title": "Tuesday",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 3,
                "id": 3,
                "title": "Wednesday",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 4,
                "id": 4,
                "title": "Thursday",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 5,
                "id": 5,
                "title": "Friday",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 6,
                "id": 6,
                "title": "Saturday",
                "meta_information": [],
                "minimum_user_type_required": 0
              ]
            ],
            "created_at": "",
            "updated_at": ""
          ]
        ],
        [
          "preference_id": 3,
          "preference_selection_id": 0,
          "meta_information": [],
          "preference": [
            "priority": 0,
            "minimum_user_type_required": 0,
            "id": 3,
            "title": "Show declined events",
            "type": "boolean",
            "description": "Show declined events",
            "is_on": true,
            "action" : [
              "type": "URL",
              "data": "www.google.com"
            ],
            "choices": [
              [
                "order": 0,
                "id": 0,
                "title": "true",
                "meta_information": [],
                "is_premium": false
              ],
              [
                "order": 1,
                "id": 1,
                "title": "false",
                "meta_information": [],
                "is_premium": false
              ]
            ],
            "created_at": "",
            "updated_at": ""
          ]
        ],
        [
          "preference_id": 4,
          "preference_selection_id": 0,
          "meta_information": [],
          "preference": [
            "priority": 1,
            "minimum_user_type_required": 0,
            "id": 4,
            "title": "Default Reminder Notifications",
            "type": "picker",
            "description": "Enable reminder notifications",
            "is_on": true,
            "action" : [
              "type": "URL",
              "data": "www.google.com"
            ],
            "choices": [
              [
                "order": 0,
                "id": 0,
                "title": "10 minutes before",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 1,
                "id": 1,
                "title": "25 minutes before",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 2,
                "id": 2,
                "title": "30 minutes before",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 3,
                "id": 3,
                "title": "1 hour before",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 4,
                "id": 4,
                "title": "1 day before",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 5,
                "id": 5,
                "title": "1 week before",
                "meta_information": [],
                "minimum_user_type_required": 0
              ],[
                "order": 6,
                "id": 6,
                "title": "Custom",
                "meta_information": [
                  [
                    "options": [
                      [
                        "id": 0,
                        "title": "Minutes"
                      ],
                      [
                        "id": 1,
                        "title": "Hours"
                      ],
                      [
                        "id": 2,
                        "title": "Days"
                      ],
                      [
                        "id": 3,
                        "title": "Weeks"
                      ],
                      [
                        "id": 4,
                        "title":"Months"
                      ]
                    ]
                  ]
                ],
                "minimum_user_type_required": 0
              ]
            ],
            "created_at": "",
            "updated_at": ""
          ]
        ]
      ],
      "notifications": false,
      "card_on_file": false,
      "dashboard_sections": [
        [
          "dashboard_id": 0,
          "header_is_visible": false,
          "meta_information": [],
          "dashboard_section": [
            "priority": 0,
            "id": 0,
            "header_title": "Incoming Meetings",
            "header_description": "Meetings that have been requested"
          ]
        ],
        [
          "dashboard_id": 1,
          "header_is_visible": false,
          "meta_information": [],
          "dashboard_section": [
            "priority": 1,
            "id": 1,
            "header_title": "Today",
            "header_description": "Meetings that are today"
          ]
        ],
        [
          "dashboard_id": 2,
          "header_is_visible": false,
          "meta_information": [],
          "dashboard_section": [
            "priority": 2,
            "id": 2,
            "header_title": "Tomorrow",
            "header_description": "Meetings that are tomorrow"
          ]
        ]
      ],

      "account_type" : [
        [
          "id": 0,
          "max_dashboard_sections_count": 3,
          "created_at": "",
          "updated_at": "",
          "meta_information": [],
          "owner": [
            "id": 0,
            "first_name": "John",
            "last_name": "Doe",
            "full_name": "John Doe"
          ]
        ]
      ]
    ]
    return UserProfileData(JSON: dict)
  }
}
