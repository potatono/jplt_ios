//
//  PodcastsCollectionViewController.swift
//  PPC
//
//  Created by Justin Day on 2/28/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

protocol PodcastChangedDelegate {
    func podcastChangedTo(pid: String)
}

class PodcastsCollectionViewController : UICollectionViewController {
    var changeDelegate: PodcastChangedDelegate?
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
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let changeDelegate = self.changeDelegate {
            let pid = podcasts[indexPath.row].pid
            print("Changing podcast to \(pid)")
            changeDelegate.podcastChangedTo(pid: pid)
            self.navigationController?.popViewController(animated: true)
        }

        return false
    }
}
