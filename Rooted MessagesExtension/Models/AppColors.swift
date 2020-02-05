//
//  AppColors.swift
//  DadHive
//
//  Created by Michael Westbrooks on 12/24/18.
//  Copyright © 2018 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit


struct AppColors {
    static var darkGreen: UIColor {
        return UIColor(hexString: "95cf7d") ?? UIColor.init(red: 149/255,
                                                            green: 207/255,
                                                            blue: 125/255,
                                                            alpha: 1.0)
    }
    static var lightGreen: UIColor {
        return UIColor(hexString: "B4D859") ?? UIColor.init(red: 180/255,
                                                            green: 216/255,
                                                            blue: 89/255,
                                                            alpha: 1.0)
    }
}
