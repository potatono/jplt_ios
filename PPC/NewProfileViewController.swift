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
    @IBOutlet weak var doneButton: UIButton!
    
    @IBAction func didPressDone(_ sender: Any) {
        save() {
            if let delegate = NewProfileViewController.podcastChangedDelegate {
                print("New Profile Podcast Changed To Default")
                
                Episodes.changeToDefault() { (pid) in
                    delegate.podcastChangedTo(pid: pid)
                }
            }
        }
    }
    
    @IBAction func didEditUsername(_ sender: Any) {
        doneButton.isEnabled = (usernameTextField.text != nil && usernameTextField.text != "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        doneButton.isEnabled = (usernameTextField.text != nil && usernameTextField.text != "")
    }
}
