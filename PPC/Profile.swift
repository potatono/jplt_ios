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
    
    func getDocument() -> DocumentReference {
        let db = Firestore.firestore()
        let doc = db.collection("profiles").document(uid)
        return doc
    }
    
    func read(completion: ((Profile) -> Void)? = nil) {
        print("Reading profile..")
        let doc = getDocument()
        doc.getDocument { (doc: DocumentSnapshot?, err: Error?) in
            if err != nil {
                print("Error getting profile \(err!)")
            }
            else if let data = doc!.data() {
                self.username = data["username"] as? String
                self.bindings.set("username", self.username)

                if (data["remoteImageURL"] != nil) {
                    self.remoteImageURL = URL(string: (data["remoteImageURL"] as? String)!)
                    self.bindings.set("remoteImageURL", self.remoteImageURL)
                }
                
                if (data["remoteThumbURL"] != nil) {
                    self.remoteThumbURL = URL(string: (data["remoteThumbURL"] as? String)!)
                    self.bindings.set("remoteThumbURL", self.remoteThumbURL)
                }
                
                if completion != nil {
                    print("Profile read completion..")
                    completion!(self)
                }
            }
        }
    }
    
    func save() {
        print("Saving profile..")
        
        let docref = self.getDocument()
        
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
        
        let callback: ((Error?) -> Void) = { err in
            if err != nil {
                print ("Error writing document \(err!)")
            }
        }
        
        docref.setData(doc, completion: callback)
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
}

