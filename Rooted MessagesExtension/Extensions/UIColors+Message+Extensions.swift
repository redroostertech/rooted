//
//  UIColors+Ext.swift
//  boothnoire
//
//  Created by Michael Westbrooks on 8/26/18.
//  Copyright © 2018 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    @nonobjc class var gradientColor1: UIColor {
        return UIColor(red: 248/255,
                       green: 165/255,
                       blue: 9/255,
                       alpha: 1.0)
    }

    @nonobjc class var gradientColor2: UIColor {
        return UIColor(red: 245/255,
                       green: 119/255,
                       blue: 45/255,
                       alpha: 1.0)
    }

    @nonobjc class var gradientColor3: UIColor {
        return UIColor(red: 240/255,
                       green: 88/255,
                       blue: 67/255,
                       alpha: 1.0)
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
    
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        return nil
    }

}
