//
//  AvatarHelper.swift
//  Neone.net
//
//  Created by Dave Glassco on 8/13/19.
//  Copyright © 2019 Neone. All rights reserved.
//

import Foundation
import UIKit

class AvatarHelper {
    
    static func convertToAvatarData(profileName: String, avatarString: String?) -> (AvatarImageViewDataSource) {
        
        var profileAvatar: UIImage?
        
        if let avatarEncodedString = avatarString {
            if !avatarEncodedString.isEmpty{
                if let avatarData = Data(base64Encoded: avatarEncodedString) {
                    profileAvatar = UIImage(data: avatarData) ?? nil
                }
            }
        }
        
        struct AvatarData: AvatarImageViewDataSource {
            var name: String
            var avatar: UIImage?
            
            init(profileName: String, profileAvatar: UIImage?) {
                name = profileName
                avatar = profileAvatar
            }
        }
        
        let avatarDataSource  = AvatarData(profileName: profileName, profileAvatar: profileAvatar)
        return avatarDataSource
    }

  static func setDefaultAvatar(displayName: String, avatarString: String? = nil, avatarImage: UIImage? = nil, isRound: Bool = false, borderWidth: CGFloat = 0, borderColor: UIColor = UIColor.white, avatarView: AvatarViewController) {

      let avatarData = AvatarViewData(displayName: displayName, avatarString: avatarString, avatarImage: avatarImage, isRound: isRound, borderWidth: borderWidth, borderColor: borderColor)
      avatarView.configureAvatarView(avatarViewData: avatarData)
  }
}
