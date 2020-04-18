//
//  ProfileViewController.swift
//  PPC
//
//  Created by Justin Day on 2/12/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Photos

import Kingfisher
import FirebaseAuth

class ProfileViewController: ImagePickerViewController {
    
    var profile: Profile = Profiles.me()

    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var tapToChangeLabel: UILabel!
    
    @IBAction func didTouchImage(_ sender: Any) {
        presentImagePicker(from: sender)
        tapToChangeLabel.isHidden = true
    }
    
    @IBAction func usernameEditingDidBegin(_ sender: Any) {
        self.view.frame.origin.y = -128
    }

    @IBAction func usernameEditingDidEnd(_ sender: Any) {
        self.view.frame.origin.y = 0
    }
    
    @IBAction func doneEditingUsername(_ sender: Any) {
        usernameTextField.resignFirstResponder()
    }
    
    @IBAction func didPressSave(_ sender: Any) {
        save() {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func save(completion: (()->Void)? = nil) {
        self.profile.username = usernameTextField.text
        
        if let image = pickedImage {
             // Upload saves
            self.view.makeToastActivity(.center)
            self.profile.uploadImage(image) {
                self.view.hideToastActivity()
                self.profile.setBindings() // Profiles use get instead of listen
                completion?()
            }
        }
        else {
            self.profile.save()
            self.profile.setBindings() // Profiles use get instead of listen
            completion?()
        }
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
        tapToChangeLabel.layer.cornerRadius = 5
        tapToChangeLabel.layer.masksToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        profile.addBinding(forTopic: "username", control: self.usernameTextField)
        profile.addBinding(forTopic: "remoteImageURL", control: self.imageButton, options: ["noCrop": true])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        profile.removeBinding(self.usernameTextField)
        profile.removeBinding(self.imageButton)
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
         self.view.frame.origin.y = -150 // Move view 150 points upward
    }

    @objc func keyboardWillHide(_ sender: Notification) {
         self.view.frame.origin.y = 0 // Move view to original position
    }
    
    override func crop(image: UIImage) -> UIImage {
        let r: CGRect = CGRect(x: 0, y: 0, width: 640/2, height: 640/2)
        UIGraphicsBeginImageContextWithOptions(r.size, false, 0.0)
        
        let path:UIBezierPath = UIBezierPath()
        path.move(to: CGPoint(x:12/2, y:20/2))
        path.addLine(to: CGPoint(x:628/2, y:88/2))
        path.addLine(to: CGPoint(x:328/2, y:619/2))
        path.addLine(to: CGPoint(x:12/2, y:20/2))
        path.addLine(to: CGPoint(x:628/2, y:88/2))

        if let context = UIGraphicsGetCurrentContext() {
            context.addPath(path.cgPath)
            context.setStrokeColor(red: 89/256, green: 81/256, blue: 190/256, alpha: 1.0)
            context.setLineWidth(10.0/2)
            context.strokePath()

            context.addPath(path.cgPath)
            context.clip()
        }
        image.draw(in: CGRect(origin: .zero, size: r.size))
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return UIImage()
        }
        UIGraphicsEndImageContext()
        
        return image
    }
    
    override func didPickImage(image: UIImage) {
        imageButton.setImage(image, for:UIControl.State.normal)
    }
}
