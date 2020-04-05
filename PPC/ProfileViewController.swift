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

class ProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var profile: Profile = Profile(Auth.auth().currentUser!.uid)

    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!

    @IBAction func didTouchImage(_ sender: Any) {
        choosePhoto()
    }
    
    @IBAction func usernameEditingDidBegin(_ sender: Any) {
        self.view.frame.origin.y = -128
    }

    @IBAction func usernameEditingDidEnd(_ sender: Any) {
        self.view.frame.origin.y = 0
        self.profile.username = usernameTextField.text
        self.profile.save()
    }
    
    @IBAction func doneEditingUsername(_ sender: Any) {
        usernameTextField.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        profile.addBinding(forTopic: "username", control: self.usernameTextField)
        profile.addBinding(forTopic: "remoteImageURL", control: self.imageButton, options: ["noCrop": true])
        profile.listen()
        
//        profile.read() { (_) in
//            if let username = self.profile.username {
//                self.usernameTextField.text = username
//            }
//
//            if let remoteImageURL = self.profile.remoteImageURL {
//                self.imageButton.kf.setImage(with: remoteImageURL,
//                                        for: UIControl.State.normal)
//            }
//        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
    }
    @objc func keyboardWillShow(_ sender: Notification) {
         self.view.frame.origin.y = -150 // Move view 150 points upward
    }

    @objc func keyboardWillHide(_ sender: Notification) {
         self.view.frame.origin.y = 0 // Move view to original position
    }
    
    func ensurePhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            print("Photo access is authorized")
        case .denied, .restricted :
            print("Photo access is denied or restricted")
        case .notDetermined:
            print("Asking for permissions to photos")
            
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    print("Photo access was granted")
                case .denied, .restricted:
                    print("Photo access was denied or restricted")
                case .notDetermined:
                    print("Photo access still not determined")
                }
            }
        }
    }
    
    func choosePhoto() {
        ensurePhotoPermission()
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = (self as UIImagePickerControllerDelegate & UINavigationControllerDelegate)
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = true
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func crop(image: UIImage) -> UIImage {
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
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!)
    {
        self.dismiss(animated: true, completion: { () -> Void in
            print("Dismissed")
        })
        
        print("Setting image")
        
        if image.cgImage != nil {
            let cropped = crop(image: image)
            imageButton.setImage(cropped, for:UIControl.State.normal)
            self.profile.uploadImage(cropped)
        }
        else {
            print("Not a CGImage")
        }
    }
}
