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

class Episode : Model {
    static var listener: (([Episode]) -> Void)? = nil
    
    // MARK: Properties
    var id: String
    var owner: String
    var localURL: URL
    var remoteURL: URL?
    var title: String
    var remoteCoverURL: URL?
    var remoteThumbURL: URL?
    var createDate: Date
    var profile: Profile
    
    // MARK: Initialization
    init(id:String, title:String, owner:String, url:URL) {
        self.id = id
        self.title = title
        self.remoteURL = url
        self.owner = owner
        self.localURL = Episode.createLocalURL(self.id)
        self.createDate = Date()
        self.profile = Profile(self.owner)
    }
    
    init(_ id:String=UUID().uuidString) {
        self.id = id
        self.title = "New Episode"
        self.owner = Auth.auth().currentUser!.uid
        self.localURL = Episode.createLocalURL(self.id)
        self.createDate = Date()
        self.profile = Profile(self.owner)
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
        
        self.owner = data["owner"] as! String
        self.profile = Profiles.instance().get(self.owner) { (_) in
            if (completion != nil) {
                completion!(self)
            }
        }
        
        if data["remoteURL"] != nil {
            self.remoteURL = URL(string: data["remoteURL"] as! String)
        }
        
        if data["remoteCoverURL"] != nil {
            self.remoteCoverURL = URL(string: data["remoteCoverURL"] as! String)
        }
        
        if data["remoteThumbURL"] != nil {
            self.remoteThumbURL = URL(string: data["remoteThumbURL"] as! String)
        }
        
        if data["createDate"] != nil {
            let t = data["createDate"] as! Timestamp
            self.createDate = t.dateValue()
        }
        
        self.setBindings()
    }
    
    func createRemotePath(_ filename:String="sound.m4a") -> String {
        return "podcasts/\(owner)/episodes/\(id)/\(filename)"
    }

    func getPlaybackURL() -> URL? {
        if (try? localURL.checkResourceIsReachable()) ?? false { return localURL }
        
        return remoteURL
    }
    
    func canEdit() -> Bool {
        return self.owner == Auth.auth().currentUser!.uid
    }
    
    func save() {
        let db = Firestore.firestore()
        let pid = Episodes.PID
        let col = db.collection("podcasts").document(pid).collection("episodes")
        
        var doc: [String: Any] = [
            "id": id,
            "title": title,
            "owner": owner,
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
        
        let callback: ((Error?) -> Void) = { err in
            if err != nil {
                print ("Error writing document \(err!)")
            }
        }
        
        col.document(id).setData(doc, completion: callback)
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
    
//    func downloadCover(completion: ((Episode) -> Void)? = nil) {
//        let storage = Storage.storage()
//        let storageRef = storage.reference()
//        let fileRef = storageRef.child(self.createRemotePath("cover.jpg"))
//
//        fileRef.getData(maxSize: 1024 * 1024) { data, err in
//            if err != nil {
//                print("Error occured while downloading cover. \(err!)")
//            }
//            else {
//                self.cover = UIImage(data: data!)!
//
//                completion?(self)
//            }
//        }
//    }
    
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
