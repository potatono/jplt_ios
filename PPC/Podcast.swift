//
//  Podcast.swift
//  PPC
//
//  Created by Justin Day on 2/27/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation

import Firebase
import FirebaseAuth

class Podcast : Model {
    var listenerRegistration: ListenerRegistration?

    var pid: String
    var name: String?
    var owner: String?
    var subscribers: [String]
    var remoteCoverURL: URL?
    var remoteThumbURL: URL?
    
    override init() {
        pid = "newpodcast"
        name = "New Podcast"
        owner = Auth.auth().currentUser!.uid
        subscribers = [owner!]
    }
    
    init(_ pid:String) {
        self.pid = pid
        self.subscribers = []
    }
    
    func restore(_ data: [String: Any]) {
        name = data["name"] as? String
        owner = data["owner"] as? String
        subscribers = data["subscribers"] as! [String]

        if let remoteCoverURL = data["remoteCoverURL"] as? String {
            self.remoteCoverURL = URL(string: remoteCoverURL)
        }
        
        if let remoteThumbURL = data["remoteThumbURL"] as? String {
            self.remoteThumbURL = URL(string: remoteThumbURL)
        }
        
        self.setBindings()
    }
    
    func data() -> [String: Any] {
        var data: [String: Any] = [:]
        
        data["subscribers"] = self.subscribers
        
        if let name = self.name {
            data["name"] = name
        }
        
        if let owner = self.owner {
            data["owner"] = owner
        }

        if let remoteCoverURL = self.remoteCoverURL {
            data["removeCoverURL"] = remoteCoverURL
        }
        
        if let remoteThumbURL = self.remoteThumbURL {
            data["remoteThumbURL"] = remoteThumbURL
        }
        
        return data
    }
    
    func getDocumentReference() -> DocumentReference {
        let db = Firestore.firestore()
        let doc = db.collection("podcasts").document(pid)
        return doc
    }
    
    deinit {
        if let listenerRegistration = self.listenerRegistration {
            listenerRegistration.remove()
        }
    }
    
    func listen() {
        if listenerRegistration == nil {
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
    }

    func save() {
        let docRef = self.getDocumentReference()
        let data = self.data()
        
        docRef.setData(data) { err in
            if let err = err {
                print ("Error writing podcast \(err)")
            }
            else if self.listenerRegistration == nil {
                self.listen()
            }
        }
    }
    
    override func createRemotePath(_ filename:String) -> String {
        return "podcasts/\(String(describing: owner))/\(pid)/\(filename)"
    }

    func uploadCover(_ cover:UIImage) {
        if let data = cover.jpegData(compressionQuality: 0.8) {
            print("Uploading cover..")
            
            upload(filename: "cover.jpg",
                   data: data,
                   completion: { (url) in
                    self.remoteCoverURL = url
                    self.save()
            })
        }
        
        let thumb = cover.kf.resize(to: CGSize(width: 300, height: 300))
        if let data = thumb.pngData() {
            print("Uploading cover thumb..")
            
            self.upload(filename: "cover-thumb.png",
                        data: data,
                        completion: { (url) in
                            self.remoteThumbURL = url
                            self.save()
            })
        }
    }
    
}
