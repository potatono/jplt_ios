//
//  PodcastDetailViewController.swift
//  PPC
//
//  Created by Justin Day on 4/9/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Photos
import Toast_Swift

class PodcastDetailViewController : ImagePickerViewController {
    public var podcast:Podcast = Podcast(Episodes.PID)

    @IBOutlet weak var coverButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var tapToChangeLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        podcast.addBinding(forTopic: "name", control: nameTextField)
        podcast.addBinding(forTopic: "remoteCoverURL", control: coverButton, options: ["noCrop": true])
        podcast.addBinding(forTopic: "inviteURL", control: inviteButton, options: ["asText": true])
        podcast.listen()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
        tapToChangeLabel.layer.cornerRadius = 5
        tapToChangeLabel.layer.masksToBounds = true
        
    }
          
    @objc func keyboardWillShow(_ sender: Notification) {
        self.view.frame.origin.y = -150 // Move view 150 points upward
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        self.view.frame.origin.y = 0 // Move view to original position
    }
    
    @IBAction func didEditName(_ sender: Any) {
        //podcast.name = nameTextField.text ?? "New Podcast"
    }
    
    @IBAction func didPressCover(_ sender: Any) {
        presentImagePicker(from: sender)
    }
    
    @IBAction func didPressInvite(_ sender: Any) {
        UIPasteboard.general.string = podcast.inviteURL?.absoluteString
        self.view.makeToast("Copied")
    }
    
    @IBAction func didPressDelete(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Podcast", message: "Are you sure?  This action cannot be undone.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive, handler: { _ in
            self.podcast.delete()
            Profiles.me().removeSubscription(podcast: self.podcast)
            Notifications.me().clearUnread(pid: self.podcast.pid)
            self.getEpisodeTableViewController()!.podcastChangedToDefault()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didPressSave(_ sender: Any) {
        podcast.name = nameTextField.text ?? "New Podcast"

        if let image = pickedImage {
            self.view.makeToastActivity(.center)
            podcast.uploadCover(image) {
                self.view.hideToastActivity()
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            podcast.save()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func getEpisodeTableViewController() -> EpisodeTableViewController? {
        for controller in self.navigationController!.children {
            if let episodeTableViewController = controller as? EpisodeTableViewController {
                return episodeTableViewController
            }
        }
        
        return nil
    }

    override func didPickImage(image: UIImage) {
        coverButton.setImage(image, for:UIControl.State.normal)
        tapToChangeLabel.isHidden = true
    }
}
