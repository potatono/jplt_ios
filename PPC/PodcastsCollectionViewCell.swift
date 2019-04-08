//
//  PodcastsCollectionViewCell.swift
//  PPC
//
//  Created by Justin Day on 2/28/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

class PodcastsCollectionViewCell : UICollectionViewCell {
    var podcast: Podcast?
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func prepareForReuse() {
        if let podcast = podcast {
            coverImageView.image = UIImage(named: "jplt_full")
            nameLabel.text = "New Podcast"
            
            podcast.removeBinding(coverImageView)
            podcast.removeBinding(nameLabel)
        }
    }
}
