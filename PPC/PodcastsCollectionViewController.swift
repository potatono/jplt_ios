//
//  PodcastsCollectionViewController.swift
//  PPC
//
//  Created by Justin Day on 2/28/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

class PodcastsCollectionViewController : UICollectionViewController {
    var podcasts: [Podcast] = []
    
    override func viewDidLoad() {
        if let subs = Profiles.me().subscriptions {
            for sub in subs {
                let podcast = Podcast(sub)
                podcast.listen()
                podcasts.append(podcast)
            }
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcasts.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cellIdentifier = "PodcastsCollectionViewCell"
        guard let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier,
                                                            for: indexPath) as? PodcastsCollectionViewCell
        else {
            fatalError("The dequeued cell is not an instance of PodcastsCollectionViewCell")
        }

        let podcast = podcasts[indexPath.row]
        cell.podcast = podcast
        podcast.addBinding(forTopic: "remoteThumbURL", control: cell.coverImageView)
        podcast.addBinding(forTopic: "name", control: cell.nameLabel)
        
        return cell
    }
}
