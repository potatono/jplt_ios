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
    
    var uid: String?
    var remoteImageURL: URL?
    var remoteThumbURL: URL?
    var username: String?
    var subscriptions: [String]

    init(_ uid: String) {
        self.uid = uid
        self.subscriptions = []
    }
    
    override init() {
        self.subscriptions = []
    }
    
    func getDocumentReference() -> DocumentReference {
        let db = Firestore.firestore()
        let doc = db.collection("profiles").document(uid!)
        return doc
    }
    
    deinit {
        if let listenerRegistration = self.listenerRegistration {
            listenerRegistration.remove()
        }
    }

    func get(completion: ((Profile) -> Void)? = nil) {
        if uid != nil && listenerRegistration == nil {
            let docRef = getDocumentReference()
            docRef.getDocument() { (snap, err) in
                if let err = err {
                    print("Error in listener for \(self): \(err)")
                }
                else if let data = snap?.data() {
                    self.restore(data)
                    
                    completion?(self)
                }
            }
        }
    }

    func listen() {
        if uid != nil && listenerRegistration == nil {
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

        if let subscriptions = data["subscriptions"] as? [String] {
            self.subscriptions = subscriptions
        }
        
        self.setBindings()
    }
    
    func save() {
        let docref = self.getDocumentReference()
        
        var doc: [String: Any] = [
            "uid": uid!,
            "username": username as Any,
            "subscriptions": subscriptions
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
    
    override func createRemotePath(_ filename:String) -> String {
        return "profiles/\(uid!)/\(filename)"
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
        if uid != nil {
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
    
    func joinPodcast(inviteURLString: String, completion: ((String)->Void)? = nil) {
        if !inviteURLString.starts(with: "https://jplt.com/join/") { return }
        guard let inviteURL = URL(string: inviteURLString) else { return}

        let pid = Podcast.decodePid(fromInviteURL: inviteURL)
        print("Joining podcast " + pid)

        if !self.subscriptions.contains(pid) {
            self.subscriptions.append(pid)
            self.save()
        }
        
        //Messaging.messaging().subscribe(toTopic: pid)

        var request = URLRequest(url: inviteURL)
        request.httpMethod = "POST"
        let postString = "uid=" + self.uid!
        print("HTTP POST to \(inviteURL) with \(postString)")
        request.httpBody = postString.data(using: String.Encoding.utf8);
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check for Error
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
         
                // Convert HTTP Response Data to a String
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response data string:\n \(dataString)")
                    completion?(pid)
                }
        }
        task.resume()
    }
    
    func removeSubscription(podcast: Podcast) {
        self.subscriptions.removeAll(where: { $0 == podcast.pid })
        self.save()
    }
    
    func leavePodcast(podcast: Podcast, completion: (()->Void)? = nil) {
        print("Leaving podcast " + podcast.pid)

        //Messaging.messaging().unsubscribe(fromTopic: podcast.pid)
        self.removeSubscription(podcast: podcast)

        let leaveURL = URL(string: "https://jplt.com/leave/" + podcast.inviteURL!.lastPathComponent)
        var request = URLRequest(url: leaveURL!)
        request.httpMethod = "POST"
        let postString = "uid=" + self.uid!
        request.httpBody = postString.data(using: String.Encoding.utf8);
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check for Error
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
         
                // Convert HTTP Response Data to a String
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response data string:\n \(dataString)")
                    completion?()
                }
        }
        task.resume()
    }
}

