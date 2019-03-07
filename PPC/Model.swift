//
//  Model.swift
//  PPC
//
//  Created by Justin Day on 2/15/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

import Firebase
import FirebaseAuth

class Model {
    var bindings: ControlBindings = ControlBindings()
    
    func addBinding(forTopic: String, control: UIView, setter: ((UIView, Any?) -> Void)?) {
        bindings.addBinding(forTopic: forTopic, control: control, setter: setter)
        setBindings(forTopic: forTopic)
    }
    
    func addBinding(forTopic: String, control: UIView) {
        addBinding(forTopic: forTopic, control: control, setter: nil)
    }
    
    func removeBinding(_ control: UIView) {
        bindings.removeBinding(control)
    }
    
    func setBindings() {
        setBindings(forTopic:nil)
    }
    
    func setBindings(forTopic:String?) {
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let label = child.label {
                if label != "bindings" && (forTopic == nil || forTopic == label)
                {
                    bindings.set(label, child.value)
                }
            }
        }
    }
    
    func createRemotePath(_ filename:String) -> String {
        return filename
    }
    
    func upload(filename:String, data:Data, completion: @escaping ((URL)->Void)) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child(self.createRemotePath(filename))
        
        print("Uploading \(filename)..")
        
        fileRef.putData(data, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                print("Error occured while uploading file: \(error!)")
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            print("Uploaded " + String(size) + " bytes")
            
            fileRef.downloadURL { url, err in
                if err != nil {
                    print("Error while getting download URL \(err!)")
                }
                else {
                    print("Download URL is \(url!)")
                    completion(url!)
                }
            }
        }
    }
}
