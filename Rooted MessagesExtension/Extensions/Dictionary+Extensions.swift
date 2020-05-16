//
//  Dictionary+Extensions.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 1/29/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation

extension Dictionary {
  func convertToJsonString() -> String? {
    let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [])
    let jsonString = String(data: jsonData!, encoding: .utf8)
    return jsonString
  }
}
