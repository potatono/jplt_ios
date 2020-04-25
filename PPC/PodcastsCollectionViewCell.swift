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

    var badgeLabel: UILabel
    
    override init(frame: CGRect) {
        self.badgeLabel =  UILabel.init(badgeText: "", color: UIColor.red, fontSize: 18.0)
        super.init(frame: frame)
        self.addSubview(self.badgeLabel)
        badgeLabel.isHidden = true
        badgeLabel.topAnchor.constraint(equalTo:self.topAnchor, constant: 10).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo:self.rightAnchor, constant: -10).isActive = true
    }
    
    required init?(coder: NSCoder) {
        self.badgeLabel =  UILabel.init(badgeText: "", color: UIColor.red, fontSize: 18.0)
        super.init(coder: coder)
        self.addSubview(self.badgeLabel)
        badgeLabel.isHidden = true
        badgeLabel.topAnchor.constraint(equalTo:self.topAnchor, constant: 10).isActive = true
        badgeLabel.rightAnchor.constraint(equalTo:self.rightAnchor, constant: -10).isActive = true
        
    }
    
    override func prepareForReuse() {
        if let podcast = podcast {
            coverImageView.image = UIImage(named: "cover")
            nameLabel.text = "New Podcast"
            podcast.removeBinding(coverImageView)
            podcast.removeBinding(nameLabel)
        }
    }
}
