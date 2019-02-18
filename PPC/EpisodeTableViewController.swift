//
//  EpisodeTableViewController.swift
//  PPC
//
//  Created by Justin Day on 12/12/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import UIKit
import FirebaseAuth

class EpisodeTableViewController: UITableViewController {

    // MARK: Properties
    var episodes = Episodes()
    
    // MARK: Actions
    @IBAction func unwindDetail(unwindSegue: UIStoryboardSegue) {
        print("unwindDetail")

        self.tableView.reloadData()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        episodes.addBinding(forTopic: "reload", control: self.tableView)        
        episodes.listen()

        Profile(Auth.auth().currentUser!.uid).ensureExists {
            self.performSegue(withIdentifier: "profileSegue", sender: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        // self.navigationController!.setToolbarHidden(false, animated: false)
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        episodes.removeBinding(self.tableView)
    }

    @IBAction func didPressMore(_ sender: Any) {
        let alertController = UIAlertController(title: "Show", message: nil, preferredStyle: .actionSheet)

        let profileButton = UIAlertAction(title: "Edit Profile", style: .default, handler: { (action) -> Void in
            self.performSegue(withIdentifier: "profileSegue", sender: sender)
        })
        alertController.addAction(profileButton)

        if Episodes.PID == "prealpha" {
            let testingButton = UIAlertAction(title: "Switch to Testing Podcast", style: .default) { _ in
                self.episodes.changePid(pid: "testing")
            }
            alertController.addAction(testingButton)
        }
        else {
            let testingButton = UIAlertAction(title: "Switch to Alpha Podcast", style: .default) { _ in
                self.episodes.changePid(pid: "prealpha")
            }
            alertController.addAction(testingButton)
        }

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
        })
        alertController.addAction(cancelButton)

        
        self.navigationController!.present(alertController, animated: true, completion: nil)
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
        
        let episode = episodes.list[indexPath.row]
        cell.episode = episode
        episode.addBinding(forTopic: "title", control: cell.titleLabel)
        episode.addBinding(forTopic: "remoteThumbURL", control: cell.coverImageView)
        episode.addBinding(forTopic: "createDate", control: cell.dateLabel)
        episode.profile.addBinding(forTopic: "username", control: cell.usernameLabel)
        episode.profile.addBinding(forTopic: "remoteThumbURL", control: cell.profileImageView)
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let detailViewController = segue.destination as? DetailViewController {
            if let selectedEpisode = sender as? EpisodeTableViewCell {
                let indexPath = tableView.indexPath(for: selectedEpisode)
                detailViewController.episode = episodes.list[indexPath!.row]
            }
        }
    }
}
