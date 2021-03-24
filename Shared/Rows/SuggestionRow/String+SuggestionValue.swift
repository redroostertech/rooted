//
//  String+SuggestionValue.swift
//  SuggestionRow
//
//  Created by Mathias Claassen on 9/9/16.
//  Copyright © 2016 Helene Martin. All rights reserved.
//

import Foundation
import Eureka

extension String: SuggestionValue {
    public var suggestionString: String {
        return self
    }
}
