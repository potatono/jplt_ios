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
    
    public var description: String { return "\(id) \(title)" }
    
    // MARK: Initialization
    init(_ id:String) {
        self.id = id
        self.title = "New Episode"
        self.localURL = Episode.createLocalURL(self.id)
        self.createDate = Date()
        self.profile = Profile()
    }
    
    override init() {
        self.id = UUID().uuidString
        self.title = "New Episode"
        self.localURL = Episode.createLocalURL(self.id)
        self.createDate = Date()
        self.owner = Auth.auth().currentUser!.uid
        self.profile = Profiles.instance().get(self.owner!)
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
    
    func save() {
        var doc: [String: Any] = [
            "id": id,
            "title": title,
            "owner": owner!,
            "localURL": localURL.absoluteString,
            "createDate": Timestamp(date:createDate)
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
        
        self.getDocumentReference().setData(doc) { err in
            if let err = err {
                print("Error writing document \(err)")
            }
            else if self.listenerRegistration == nil {
                self.listen()
            }
        }
    }
    
    func uploadRecording() {
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
                }
            }
        }
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
        
        let thumb = cover.kf.resize(to: CGSize(width: 100, height: 100))
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
    
    func delete(completion: (() -> Void)? = nil) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let storageRef = storage.reference()

        let pid = Episodes.PID
        let col = db.collection("podcasts").document(pid).collection("episodes")
        let doc = col.document(id)
        
        print("Deleting episode document..")
        
        doc.delete { (_: Error?) in
            print("Deleting episode cover..")
            let coverRef = storageRef.child(self.createRemotePath("cover.jpg"))

            coverRef.delete(completion: { (_: Error?) in
                print("Deleting episode audio..")
                let episodeRef = storageRef.child(self.createRemotePath())

                episodeRef.delete(completion: { (_: Error?) in
                    print("Calling completion..")
                    if completion != nil { completion!(); }
                })
            })
        }
    }
}
