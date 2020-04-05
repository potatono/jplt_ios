//
//  NewProfileViewController.swift
//  PPC
//
//  Created by Justin Day on 4/2/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Photos

import Kingfisher
import FirebaseAuth

class NewProfileViewController: ProfileViewController {
    // We get a reference to this before the first segue, we update podcast after we've finished
    // ensuring there's a profile and a first podcast.
    public static var podcastChangedDelegate : PodcastChangedDelegate?
    
    @IBAction func didPressDone(_ sender: Any) {
        if let delegate = NewProfileViewController.podcastChangedDelegate {
            Episodes.changeToDefault() { (pid) in
                delegate.podcastChangedTo(pid: pid)
            }
        }
    }
}
