//
//  Profile.swift
//  PPC
//
//  Created by Justin Day on 2/14/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation

import Firebase
import FirebaseAuth

class Profile : Model {
    var listenerRegistration: ListenerRegistration?
    
    var uid: String
    var remoteImageURL: URL?
    var remoteThumbURL: URL?
    var username: String?

    init(_ uid: String) {
        self.uid = uid
    }
    
    override init() {
        self.uid = Auth.auth().currentUser!.uid
    }
    
    func getDocumentReference() -> DocumentReference {
        let db = Firestore.firestore()
        let doc = db.collection("profiles").document(uid)
        return doc
    }
    
    deinit {
        if let listenerRegistration = self.listenerRegistration {
            listenerRegistration.remove()
        }
    }
    
    func listen() {
        let docRef = getDocumentReference()
        listenerRegistration = docRef.addSnapshotListener { (snap, err) in
            if let err = err {
                print("Error in listener for \(self): \(err)")
            }
            else if let data = snap?.data() {
                self.restore(data)
            }
        }
    }
    
    func restore(_ data: [String:Any]) {
        self.username = data["username"] as? String
        
        if let remoteImageURL = data["remoteImageURL"] as? String {
            self.remoteImageURL = URL(string: remoteImageURL)
        }
        else {
            self.remoteImageURL = URL(string: "asset://jplt_profile")
        }
        
        if let remoteThumbURL = data["remoteThumbURL"] as? String {
            self.remoteThumbURL = URL(string: remoteThumbURL)
        }
        else {
            self.remoteThumbURL = URL(string: "asset://jplt_profile_thumb")
        }

        self.setBindings()
    }
    
    func save() {
        let docref = self.getDocumentReference()
        
        var doc: [String: Any] = [
            "uid": uid,
            "username": username as Any
        ]
        
        if remoteImageURL != nil {
            doc["remoteImageURL"] = remoteImageURL!.absoluteString
        }
        
        if remoteThumbURL != nil {
            doc["remoteThumbURL"] = remoteThumbURL!.absoluteString
        }
        
        docref.setData(doc) { err in
            if let err = err {
                print ("Error writing profile \(err)")
            }
            else if self.listenerRegistration == nil {
                self.listen()
            }
        }
    }
    
    func createRemotePath(_ filename:String) -> String {
        return "profiles/\(uid)/\(filename)"
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
    
    func uploadImage(_ image:UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            print("Uploading profile image..")
            
            self.upload(filename: "profile.jpg",
                        data: data,
                        completion: { (url) in
                            self.remoteImageURL = url
                            self.save()
            })
        }
        
        let thumb = image.kf.resize(to: CGSize(width: 64, height: 64))
        if let data = thumb.pngData() {
            print("Uploading profile thumb..")
            
            self.upload(filename: "profile-thumb.png",
                        data: data,
                        completion: { (url) in
                            self.remoteThumbURL = url
                            self.save()
            })
        }
    }
    
    func ensureExists(doesNotCompletion: @escaping (()->Void)) {
        let docRef = getDocumentReference()
        docRef.getDocument { (snap, err) in
            if let err = err {
                print("Error getting profile \(err)")
                doesNotCompletion()
            }
            else if snap == nil || !snap!.exists {
                doesNotCompletion()
            }
        }
    }
}

