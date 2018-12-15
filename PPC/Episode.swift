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

class Episode {
    static var listener: (([Episode]) -> Void)? = nil
    
    // MARK: Properties
    var id: String
    var localURL: URL
    var remoteURL: URL?
    var title: String
    var cover: UIImage
    var remoteCoverURL: URL?
    
    // MARK: Initialization
    init(id:String, title:String, cover:UIImage, url:URL) {
        self.id = id
        self.title = title
        self.cover = cover
        self.remoteURL = url
        self.localURL = Episode.createLocalURL(self.id)
    }
    
    init(_ id:String=UUID().uuidString) {
        self.id = id
        self.title = "New Episode"
        self.cover = UIImage(named: "jplt_full")!
        self.localURL = Episode.createLocalURL(self.id)
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
    
    func update(_ data: [String : Any], completion: ((Episode) -> Void)? = nil) {
        self.title = data["title"] as! String
        
        if data["remoteURL"] != nil {
            self.remoteURL = URL(string: data["remoteURL"] as! String)
        }
        
        if data["remoteCoverURL"] != nil {
            self.remoteCoverURL = URL(string: data["remoteCoverURL"] as! String)
            self.downloadCover(completion: completion)
        }
    }
    
    func createRemotePath(_ filename:String="sound.m4a") -> String {
        let uid = Auth.auth().currentUser!.uid
        
        return "podcasts/\(uid)/episodes/\(id)/\(filename)"
    }

    func getPlaybackURL() -> URL? {
        if (try? localURL.checkResourceIsReachable()) ?? false { return localURL }
        
        return remoteURL
    }
    
    func save() {
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser!.uid
        let col = db.collection("podcasts").document(uid).collection("episodes")
        
        var doc: [String: Any] = [
            "id": id,
            "title": title,
            "localURL": localURL.absoluteString
        ]
        
        if remoteURL != nil {
            doc["remoteURL"] = remoteURL!.absoluteString
        }
        
        if remoteCoverURL != nil {
            doc["remoteCoverURL"] = remoteCoverURL!.absoluteString
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
        
    func uploadCover() {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child(self.createRemotePath("cover.jpg"))
        let data = cover.jpegData(compressionQuality:0.8)
        
        if data == nil {
            print("Could not get jpeg data for cover.")
            return
        }
        
        print("Uploading cover..")
        
        // TODO use the uploadTask returned by putFile to show progress
        fileRef.putData(data!, metadata: nil) { metadata, error in
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
                    self.remoteCoverURL = url!
                    self.save()
                }
            }
        }
    }
    
    func downloadCover(completion: ((Episode) -> Void)? = nil) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child(self.createRemotePath("cover.jpg"))

        fileRef.getData(maxSize: 1024 * 1024) { data, err in
            if err != nil {
                print("Error occured while downloading cover. \(err!)")
            }
            else {
                self.cover = UIImage(data: data!)!
                
                completion?(self)
            }
        }
    }
}
