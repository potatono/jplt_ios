//
//  ImagePickerViewController.swift
//  PPC
//
//  Created by Justin Day on 4/18/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Photos
import Kingfisher

class ImagePickerViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var pickedImage: UIImage?

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
                @unknown default:
                    print("Unknown status \(status)")
                }
            }
        @unknown default:
            print("Unknown status \(status)")
        }
    }
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.presentImagePicker(for: type)
        }
    }

    func presentImageSourceDialog(from sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            if let sourceView = sender as? UIView {
                alertController.popoverPresentationController?.sourceView = sourceView
                alertController.popoverPresentationController?.sourceRect = sourceView.bounds
                alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
            }
        }

        self.navigationController?.present(alertController, animated: true)
    }
    
    func presentImagePicker(from sender: Any) {
        ensurePhotoPermission()
        presentImageSourceDialog(from: sender)
    }
    
    private func presentImagePicker(for type:UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = (self as UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        imagePicker.sourceType = type;
        imagePicker.allowsEditing = true
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func crop(image: UIImage) -> UIImage {
        return image
    }
    
    func didPickImage(image: UIImage) {
        
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!)
    {
        self.dismiss(animated: true, completion: { () -> Void in
            print("Dismissed")
        })
        
        print("Setting image")
        
        if image.cgImage != nil {
            pickedImage = crop(image: image)
            didPickImage(image: pickedImage!)
        }
        else {
            print("Not a CGImage")
        }
    }
}
