//
//  PodcastSubscribersTableViewController.swift
//  PPC
//
//  Created by Justin Day on 4/9/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Toast_Swift
import Kingfisher
import LinkPresentation

class PodcastSubcribersTableViewController : UITableViewController, UIActivityItemSource {
    public var podcast:Podcast = Podcast(Episodes.PID)

//    @IBAction func didPressInviteButton(_ sender: Any) {
//        UIPasteboard.general.string = podcast.inviteURL?.absoluteString
//        self.view.makeToast("Copied")
//        self.parent!.view.makeToast("Copied")
//    }
    
    @available(iOS 13.0, *)
    @IBAction func didPressAdd(_ sender: Any) {
        //let url = podcast.inviteURL!
//        let name = podcast.name ?? "New Podcast"
//        let title = "Join a podcast: \(name)"
    
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [self], applicationActivities: nil)

        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)

        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo
        ]

        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return podcast.inviteURL!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return podcast.inviteURL!
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let image = UIImage(named: "cover_icon")!
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        metadata.url = podcast.inviteURL!
        metadata.title = "Join a podcast: \(podcast.name!)"
        
        return metadata
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //podcast.addBinding(forTopic: "subscribers", control: subscribersViewController.subscribers as NSObject)
        podcast.addBinding(forTopic: "subscribers", control: self.tableView)
        podcast.listen()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcast.subscribers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PodcastSubscribersViewCell"
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier,
                                                            for: indexPath) as? PodcastSubscribersViewCell
        else {
            fatalError("The dequeued cell is not an instance of PodcastSubscribersViewCell")
        }
        
        let subscriber = podcast.subscribers[indexPath.row]
        let profile = Profiles.get(subscriber)

        cell.inviteURL = nil
        cell.profile = profile

        profile.addBinding(forTopic: "remoteThumbURL", control: cell.profileImage)
        profile.addBinding(forTopic: "username", control: cell.usernameLabel)
        profile.listen()
    
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 64.0;//Choose your custom row height
    }
    
}
