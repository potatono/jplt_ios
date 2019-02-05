//
//  EpisodeTableViewController.swift
//  PPC
//
//  Created by Justin Day on 12/12/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import UIKit

class EpisodeTableViewController: UITableViewController {

    // MARK: Properties
    var episodes = Episodes()
    
    // MARK: Actions
    @IBAction func unwindDetail(unwindSegue: UIStoryboardSegue) {
        self.tableView.reloadData()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
       // self.navigationController!.setToolbarHidden(false, animated: false)
        
    }

    @IBAction func didPressMore(_ sender: Any) {
        print("Show Actionsheet")
        let alertController = UIAlertController(title: "Show", message: nil, preferredStyle: .actionSheet)
        
        let sendButton = UIAlertAction(title: "Manage Subscribers", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
        })
        
        let  deleteButton = UIAlertAction(title: "Show Details", style: .default, handler: { (action) -> Void in
            print("Delete button tapped")
        })
        
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        
        alertController.addAction(sendButton)
        alertController.addAction(deleteButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    // MARK: - Table view data source
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.dict.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "EpisodeTableViewCell"
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier,
                                                       for: indexPath) as? EpisodeTableViewCell
        else {
                fatalError("The dequeued cell is not an instance of EpisodeTableViewCell")
        }
        
        let episode = episodes.list[indexPath.row]
        cell.titleLabel.text = episode.title
        cell.coverImageView.image = episode.cover

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
    
    private func loadData() {
        episodes.addListener { episodes in
            self.tableView.reloadData()
        }
    }
}
