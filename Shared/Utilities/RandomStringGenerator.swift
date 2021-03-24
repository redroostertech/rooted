//
//  RandomStringGenerator.swift
//  untitled
//
//  Created by Michael Westbrooks II on 11/15/17.
//  Copyright © 2017 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

class RanStringGen: NSObject {
    var len: Int
    let genCharacters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".characters)
    
    init(length: Int) {
        len = length
    }
    
    func returnString() -> String {
        var returnString = ""
        for _ in 0..<len {
            // generate a random index based on your array of characters count
            let rand = arc4random_uniform(UInt32(genCharacters.count))
            // append the random character to your string
            returnString.append(genCharacters[Int(rand)])
        }
        return returnString
    }
}
