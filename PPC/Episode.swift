//
//  Episode.swift
//  PPC
//
//  Created by Justin Day on 12/12/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import Foundation
import UIKit

import Firebase
import FirebaseAuth

class Episode : Model, CustomStringConvertible {
    static var listener: (([Episode]) -> Void)? = nil
    
    var listenerRegistration: ListenerRegistration?
    
    // MARK: Properties
    var id: String
    var owner: String?
    var localURL: URL
    var remoteURL: URL?
    var title: String
    var remoteCoverURL: URL?
    var remoteThumbURL: URL?
    var createDate: Date
    var profile: Profile
    var notified: Bool
    var published: Bool
    
    public var description: String { return "\(id) \(title)" }
    
    // MARK: Initialization
    init(_ id:String) {
        self.id = id
        self.title = "New Episode"
        self.localURL = Episode.createLocalURL(self.id)
        self.createDate = Date()
        self.profile = Profile()
        self.notified = false
        self.published = false
    }
    
    override init() {
        self.id = UUID().uuidString
        self.title = "New Episode"
        self.localURL = Episode.createLocalURL(self.id)
        self.createDate = Date()
        self.owner = Auth.auth().currentUser!.uid
        self.profile = Profiles.instance().get(self.owner!)
        self.notified = false
        self.published = false
    }
    
    deinit {
        if let listenerRegistration = self.listenerRegistration {
            listenerRegistration.remove()
        }
    }
    
    func getDocumentReference() -> DocumentReference {
        let db = Firestore.firestore()
        let pid = Episodes.PID
        let col = db.collection("podcasts").document(pid).collection("episodes")
        return col.document(self.id)
    }
    
    func getReactionsReference() -> CollectionReference {
        let doc = getDocumentReference()
        return doc.collection("reactions")
    }
    
    func thank() {
        let reactions = getReactionsReference()
        let doc: [String: Any] = [
            "type": "thank",
            "from": Profiles.me().uid!,
            "createDate": Timestamp(date:createDate)
        ]
        
        reactions.document("thank:\(Profiles.me().uid!)").setData(doc)
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
    
    func get(completion: (()->Void)? = nil) {
        let docRef = getDocumentReference()
        docRef.getDocument { (snap, err) in
            if let err = err {
                print("Error in listener for \(self): \(err)")
            }
            else if let data = snap?.data() {
                self.restore(data)
                completion?()
            }
        }
    }
    
    private class func createLocalURL(_ id:String, _ filename:String="sound.m4a") -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory
            .appendingPathComponent("episodes")
            .appendingPathComponent(id)
        
        do {
            try fileManager.createDirectory(at: soundURL, withIntermediateDirectories: true)
        }
        catch _ { print("Error creating directory") }
        
        return soundURL.appendingPathComponent(filename)
    }
    
    func restore(_ data: [String : Any], completion: ((Episode) -> Void)? = nil) {
        self.title = data["title"] as! String
        self.owner = data["owner"] as? String
        
        let bindings = self.profile.bindings
        self.profile = Profiles.instance().get(self.owner!)
        self.profile.uid = self.owner!
        profile.bindings.merge(controlBindings: bindings)
        
        if let remoteURL = data["remoteURL"] as? String {
            self.remoteURL = URL(string: remoteURL)
        }
        
        if let remoteCoverURL = data["remoteCoverURL"] as? String {
            self.remoteCoverURL = URL(string: remoteCoverURL)
        }
        else {
            self.remoteCoverURL = URL(string: "asset://cover")
        }
        
        if let remoteThumbURL = data["remoteThumbURL"] as? String {
            self.remoteThumbURL = URL(string: remoteThumbURL)
        }
        else if self.remoteCoverURL!.scheme != "asset" {
            self.remoteThumbURL = self.remoteCoverURL
        }
        else {
            self.remoteThumbURL = URL(string: "asset://cover_icon")
        }
        
        if data["createDate"] != nil {
            let t = data["createDate"] as! Timestamp
            self.createDate = t.dateValue()
        }
        
        if let notified = data["notified"] as? Bool {
            self.notified = notified
        }
        else if self.createDate < Date(timeIntervalSince1970: 1586963614) {
            self.notified = true
        }

        if let published = data["published"] as? Bool {
            self.published = published
        }
        else if self.createDate < Date(timeIntervalSince1970: 1586963614) {
            self.published = true
        }

        self.setBindings()
        self.profile.setBindings()
    }
    
    override func createRemotePath(_ filename:String="sound.m4a") -> String {
        return "podcasts/\(owner!)/episodes/\(id)/\(filename)"
    }

    func getPlaybackURL() -> URL? {
        if (try? localURL.checkResourceIsReachable()) ?? false { return localURL }
        
        return remoteURL
    }
    
    func canEdit() -> Bool {
        return self.owner == Auth.auth().currentUser!.uid
    }
    
    func canView() -> Bool {
        return self.published || self.canEdit()
    }
    
    func getData() -> [String: Any] {
        var doc: [String: Any] = [
              "id": id,
              "title": title,
              "owner": owner!,
              "localURL": localURL.absoluteString,
              "createDate": Timestamp(date:createDate),
              "notified": notified,
              "published": published
          ]
          
          if remoteURL != nil {
              doc["remoteURL"] = remoteURL!.absoluteString
          }
          
          if remoteCoverURL != nil {
              doc["remoteCoverURL"] = remoteCoverURL!.absoluteString
          }
          
          if remoteThumbURL != nil {
              doc["remoteThumbURL"] = remoteThumbURL!.absoluteString
          }
          
        return doc
    }
    
    func save() {
        let doc = self.getData()
        
        self.getDocumentReference().setData(doc) { err in
            if let err = err {
                print("Error writing document \(err)")
            }
            else if self.listenerRegistration == nil {
                self.listen()
            }            
        }
    }
    
    func uploadRecording(completion: @escaping () -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child(self.createRemotePath())
        
        print("Uploading file..")
        
        // TODO use the uploadTask returned by putFile to show progress
        fileRef.putFile(from: localURL, metadata: nil) { metadata, error in
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
                    self.remoteURL = url!
                    self.save()
                    completion()
                }
            }
        }
    }

    func uploadImage(_ image:UIImage, as filename:String, size: CGSize? = nil, completion: @escaping (URL) -> Void) {
        var resized: UIImage = image
        
        if let size = size {
            resized = image.kf.resize(to: size)
        }
        
        if let data = resized.jpegData(compressionQuality: 0.8) {
            print("Uploading \(filename)..")

            upload(filename: filename, data: data, completion: completion)
        }
    }
    
    func uploadCover(_ cover:UIImage, completion: @escaping () -> Void) {
        var countDone = 0
        
        uploadImage(cover, as: "cover-original.jpg") { (url) in
            countDone += 1
            if countDone == 3 { completion() }
        }
        
        uploadImage(cover, as: "cover.jpg", size: CGSize(width: 600, height: 600)) { (url) in
            self.remoteCoverURL = url
            self.save()
            countDone += 1
            if countDone == 3 { completion() }
        }
        
        uploadImage(cover, as: "cover-thumb.jpg", size: CGSize(width: 100, height: 100)) { (url) in
            self.remoteThumbURL = url
            self.save()
            countDone += 1
            if countDone == 3 { completion() }
        }
    }
    
    func delete(completion: (() -> Void)? = nil) {
        let db = Firestore.firestore()
        //let storage = Storage.storage()
        //let storageRef = storage.reference()

        let pid = Episodes.PID
        let col = db.collection("podcasts").document(pid).collection("episodes")
        let doc = col.document(id)
        
        print("Deleting episode document..")
        
        doc.delete { (_: Error?) in
            completion?()
            
            // TODO FIXME - Incrment counter on crosspost, deinc here, and delete on zero
            
//            print("Deleting episode cover..")
//            let coverRef = storageRef.child(self.createRemotePath("cover.jpg"))
//
//            coverRef.delete(completion: { (_: Error?) in
//                print("Deleting episode audio..")
//                let episodeRef = storageRef.child(self.createRemotePath())
//
//                episodeRef.delete(completion: { (_: Error?) in
//                    print("Calling completion..")
//                    if completion != nil { completion!(); }
//                })
//            })
        }
    }
    
    func shouldSendNotifications() -> Bool {
        return (Auth.auth().currentUser?.uid == self.owner &&
            !self.notified &&
            self.title != "New Episode" &&
            self.remoteURL != nil &&
            self.remoteCoverURL != nil
        )
    }
    
    func publish(podcast: Podcast) {
        print("Publishing to \(podcast.pid)")

        self.published = true
        
        if self.shouldSendNotifications() {
            self.notified = true
            Notifications.send(episode: self, podcast: podcast)
        }
        
        self.save()
    }
    
    func crosspost(podcast: Podcast, completion: (() -> Void)? = nil) {
        let db = Firestore.firestore()
        let col = db.collection("podcasts").document(podcast.pid).collection("episodes")
        let docRef = col.document(self.id)
        
        docRef.getDocument() { doc, err in
            if err != nil {
                print(err!)
                completion?()
            }
            else if !doc!.exists {
                docRef.setData(self.getData()) { _ in
                    if self.shouldSendNotifications() {
                        Notifications.send(episode: self, podcast: podcast)
                        self.notified = true
                        self.save()
                    }
                    
                    completion?()
                }
            }
            else {
                if self.shouldSendNotifications() {
                    Notifications.send(episode: self, podcast: podcast)
                    self.notified = true
                    self.save()
                }
                
                completion?()
            }
        }
    }
}
