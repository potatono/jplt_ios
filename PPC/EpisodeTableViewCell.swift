//
//  EpisodeTableViewCell.swift
//  PPC
//
//  Created by Justin Day on 12/12/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import UIKit

class EpisodeTableViewCell: UITableViewCell {

    // MARK: Properties
    var episode: Episode?
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        if let episode = episode {

            coverImageView.image = UIImage(named: "cover_icon")
            profileImageView.image = UIImage(named: "jplt_profile_thumb")
            
            episode.removeBinding(coverImageView)
            episode.removeBinding(titleLabel)
            episode.profile.removeBinding(profileImageView)
        }
    }
}
