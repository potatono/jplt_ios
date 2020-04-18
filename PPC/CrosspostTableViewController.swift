//
//  CrosspostTableViewController.swift
//  PPC
//
//  Created by Justin Day on 4/12/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation
import UIKit

class CrosspostTableViewController : UITableViewController {
    var episode: Episode? = nil
    var podcasts: [Podcast] = []
    
    @IBAction func didPressSend(_ sender: Any) {
        let indexPaths = self.tableView.indexPathsForSelectedRows
        var numSelected = 0
        var showActivity = false
        
        if let indexPaths = indexPaths {
            for indexPath in indexPaths {
                let podcast = podcasts[indexPath.row]
                
                if let episode = episode {
                    showActivity = true
                    numSelected += 1
                    
                    episode.crosspost(podcast: podcast) {
                        numSelected -= 1
                        
                        if numSelected == 0 {
                            self.view.hideAllToasts(includeActivity: true, clearQueue: true)
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }
        
        if showActivity {
            self.view.makeToastActivity(.center)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        for podcast in podcasts {
            podcast.listen()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CrosspostViewCell"
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier,
                                                            for: indexPath) as? CrosspostViewCell
        else {
                fatalError("The dequeued cell is not an instance of CrosspostViewCell")
        }
    
        cell.podcast = podcasts[indexPath.row]
        cell.podcast!.addBinding(forTopic:"name", control: cell.nameLabel)
        cell.podcast!.addBinding(forTopic:"remoteThumbURL", control: cell.coverImageView)
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
      {
          return 100.0;//Choose your custom row height
      }
}
