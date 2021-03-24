//
//  Success.swift
//  DadHive
//
//  Created by Michael Westbrooks on 2/18/19.
//  Copyright © 2019 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import ObjectMapper

class Success: Mappable {
    var result: Bool?
    var message: String?

    required init?(map: Map) { }

    func mapping(map: Map) {
        result <- map["result"]
        message <- map["message"]
    }
}
