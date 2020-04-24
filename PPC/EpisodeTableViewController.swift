//
//  EpisodeTableViewController.swift
//  PPC
//
//  Created by Justin Day on 12/12/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import UIKit
import FirebaseAuth

class EpisodeTableViewController: UITableViewController, PodcastChangedDelegate {

    // MARK: Properties
    var episodes = Episodes()
    var podcast = Podcast(Episodes.PID)
    var titleView = UILabel()
    
    // MARK: Actions
    @IBAction func unwindDetail(unwindSegue: UIStoryboardSegue) {
        self.tableView.reloadData()
    }
  
    @IBAction func didPressMore(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let profileButton = UIAlertAction(title: "Profile", style: .default, handler: { (action) -> Void in
            self.performSegue(withIdentifier: "profileSegue", sender: sender)
        })
        alertController.addAction(profileButton)

        if podcast.owner == Auth.auth().currentUser!.uid {
            let podcastDetailButton = UIAlertAction(title: "Podcast", style: .default, handler: { (action) -> Void in
                self.performSegue(withIdentifier: "podcastDetailSegue", sender: sender)
            })
            alertController.addAction(podcastDetailButton)

            let subscribersButton = UIAlertAction(title: "Subscribers", style: .default, handler: { (action) -> Void in
                self.performSegue(withIdentifier: "subscribersSegue", sender: sender)
            })
            alertController.addAction(subscribersButton)
        }
        else {
            let leaveButton = UIAlertAction(title: "Leave Podcast", style: .default, handler: { (action) -> Void in
                let alert = UIAlertController(title: "Leave Podcast", message: "Are you sure?", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Leave", style: UIAlertAction.Style.default, handler: { _ in
                    self.leavePodcast()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
            alertController.addAction(leaveButton)
        }
            
        let logoutButton = UIAlertAction(title: "Logout", style: .default) { _ in
            do {
                try Auth.auth().signOut()
                self.performSegue(withIdentifier: "authPhoneSegue", sender: self)

            }
            catch _ { print("Sign Out Failed.") }
        }
        alertController.addAction(logoutButton)

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
        })
        alertController.addAction(cancelButton)

        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.podcastChangedToDefault()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        self.titleView.text = "Podcast"
        self.titleView.textColor = .white
        self.titleView.textAlignment = .center
        self.titleView.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
        self.navigationController!.navigationBar.topItem!.titleView = self.titleView
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem        
        episodes.addBinding(forTopic: "reload", control: self.tableView)        
        episodes.listen()
        
        // Set by changedTo
//        podcast.addBinding(forTopic: "name", control: self.titleView, options: ["resize": true])
//        podcast.addBinding(forTopic: "name", control: self)
//        podcast.listen()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        episodes.addBinding(forTopic: "reload", control: self.tableView)
        episodes.listen()

        tableView.reloadData()
        self.navigationController?.setToolbarHidden(false, animated: false)

        self.navigationController!.navigationBar.topItem!.titleView = self.titleView
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        episodes.removeBinding(self.tableView)
        self.navigationController!.navigationBar.topItem!.titleView = nil
    }

   
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.list.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "EpisodeTableViewCell"
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier,
                                                       for: indexPath) as? EpisodeTableViewCell
        else {
            fatalError("The dequeued cell is not an instance of EpisodeTableViewCell")
        }

        if episodes.list.count > 0 && episodes.list.count > indexPath.row {
            let episode = episodes.list[indexPath.row]
            cell.episode = episode
            episode.addBinding(forTopic: "title", control: cell.titleLabel)
            episode.addBinding(forTopic: "remoteThumbURL", control: cell.coverImageView)
            episode.addBinding(forTopic: "createDate", control: cell.dateLabel)
            episode.profile.addBinding(forTopic: "username", control: cell.usernameLabel)
            episode.profile.addBinding(forTopic: "remoteThumbURL", control: cell.profileImageView)
        }
        
        return cell
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let detailViewController = segue.destination as? DetailViewController {
            detailViewController.podcast = podcast
            
            if let selectedEpisode = sender as? EpisodeTableViewCell {
                let indexPath = tableView.indexPath(for: selectedEpisode)
                detailViewController.episode = episodes.list[indexPath!.row]
            }
        }
        else if let podcastViewController = segue.destination as? PodcastsCollectionViewController {
            podcastViewController.changeDelegate = self
        }
    }
    
    func podcastChangedToDefault() {
        Profiles.me() { profile in
            Episodes.changeToDefault() { (pid) in
                self.podcastChangedTo(pid: pid)
            }
        }
    }
    
    // MARK: - Methods
    func podcastChangedTo(pid: String) {
        print("podcastChangedTo \(pid)")
        self.episodes.changePid(pid: pid)
        
        podcast.removeBinding(self)
        podcast.removeBinding(self.titleView)
        podcast = Podcast(pid)
        podcast.addBinding(forTopic: "name", control: self)
        podcast.addBinding(forTopic: "name", control: self.titleView, options:["resize": true])
        podcast.listen()
    }
    
    func joinPodcast(_ inviteURLString: String) {
        print("Joining podcast " + inviteURLString)
        self.view.makeToastActivity(.center)
        
        Profiles.me() { profile in
            profile.joinPodcast(inviteURLString: inviteURLString) { pid in
                self.podcastChangedTo(pid: pid)
            
                DispatchQueue.main.sync {
                    self.view.hideAllToasts(includeActivity: true, clearQueue: true)
                }
            }
        }
    }
    
    func leavePodcast() {
        print("Leaving podcast")
        self.view.makeToastActivity(.center)

        Profiles.me().leavePodcast(podcast: podcast) {
            Episodes.changeToDefault() { (pid) in
                self.podcastChangedTo(pid: pid)
                
                DispatchQueue.main.sync {
                    self.view.hideAllToasts(includeActivity: true, clearQueue: true)
                }
            }
        }
    }
}
