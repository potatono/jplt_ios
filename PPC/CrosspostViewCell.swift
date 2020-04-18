//
//  CrosspostViewCell.swift
//  PPC
//
//  Created by Justin Day on 4/12/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation
import Foundation
import UIKit

class CrosspostViewCell : UITableViewCell {

    var podcast: Podcast?
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func prepareForReuse() {
        coverImageView.image = UIImage(named: "cover_icon")
        nameLabel.text = "New Podcast"

        if let podcast = podcast {
            podcast.removeBinding(coverImageView)
            podcast.removeBinding(nameLabel)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        accessoryType = selected ? .checkmark : .none
    }
}
