//
//  PodcastSubscribersViewCell.swift
//  PPC
//
//  Created by Justin Day on 4/9/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

class PodcastSubscribersViewCell : UITableViewCell {

    var profile: Profile?
    var inviteURL: URL?
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var inviteLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    
    override func prepareForReuse() {
        if let profile = profile {
            profile.removeBinding(profileImage)
            profile.removeBinding(usernameLabel)
            self.profile = nil
        }
    }
}
