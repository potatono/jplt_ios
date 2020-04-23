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
    
    
    @IBAction func didPressAdd(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let joinButton = UIAlertAction(title: "Join Podcast", style: .default, handler: { (action) -> Void in
            let alert = UIAlertController(title: "Join Podcast", message: "Invite URL", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Join", style: UIAlertAction.Style.default, handler: { _ in
                self.joinPodcast(alert.textFields![0].text!)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            alert.addTextField(configurationHandler: {(textField: UITextField!) in
                textField.placeholder = "Invite URL"
                textField.isSecureTextEntry = false
            })
            self.present(alert, animated: true, completion: nil)
        })
        alertController.addAction(joinButton)
        
        let newButton = UIAlertAction(title: "Create New Podcast", style: .default, handler: { (action) -> Void in
            self.createPodcast()
        })
        alertController.addAction(newButton)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
               })
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)

    }
    
    override func viewDidLoad() {
        let subs = Profiles.me().subscriptions
        
        for sub in subs {
            let podcast = Podcast(sub)
            podcast.listen()
            podcasts.append(podcast)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Notifications.me().housekeeping()
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

        if indexPath.row < podcasts.count {
            let podcast = podcasts[indexPath.row]
            cell.podcast = podcast
            podcast.addBinding(forTopic: "remoteCoverURL", control: cell.coverImageView)
            podcast.addBinding(forTopic: "name", control: cell.nameLabel)
            guard let unread = Notifications.getInstance(uid: Profiles.me().uid!).unreads[podcast.pid]
                else {
                    cell.badgeLabel.isHidden = true
                    return cell
                }
            
            cell.badgeLabel.text = String(unread)
            cell.badgeLabel.isHidden = unread <= 0
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let changeDelegate = self.changeDelegate {
            
      

            let pid = podcasts[indexPath.row].pid
            changeDelegate.podcastChangedTo(pid: pid)
            Notifications.getInstance(uid:Profiles.me().uid!).clearUnread(pid: pid)
            self.navigationController?.popViewController(animated: true)
        }

        return false
    }
    
    func createPodcast() {
        print("Creating new podcast")
        let podcast = Podcast()
        podcast.save()
        podcasts.append(podcast)
        Profiles.me().subscriptions.append(podcast.pid)
        Profiles.me().save()
        
        self.changeDelegate?.podcastChangedTo(pid: podcast.pid)
        self.navigationController?.popViewController(animated: true)
    }
    
    func joinPodcast(_ inviteURLString: String) {
        print("Joining podcast " + inviteURLString)
        self.view.makeToastActivity(.center)
        
        Profiles.me() { profile in
            profile.joinPodcast(inviteURLString: inviteURLString) { pid in
                self.changeDelegate?.podcastChangedTo(pid: pid)
            
                DispatchQueue.main.sync {
                    self.view.hideAllToasts(includeActivity: true, clearQueue: true)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
