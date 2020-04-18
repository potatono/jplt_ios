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
    var inviteURL: URL?
    
    override init() {
        //pid = "newpodcast"
        pid = UUID.init().uuidString
        name = "New Podcast"
        owner = Auth.auth().currentUser!.uid
        subscribers = [owner!]
        super.init()

        inviteURL = URL(string: "https://jplt.com/join/" + generateInviteCode(pid: pid))
    }
    
    init(_ pid:String) {
        self.pid = pid
        self.subscribers = []
        super.init()
        inviteURL = URL(string: "https://jplt.com/join/" + generateInviteCode(pid: pid))
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
        
        if let inviteURL = data["inviteURL"] as? String {
            self.inviteURL = URL(string: inviteURL)
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
            data["remoteCoverURL"] = remoteCoverURL.absoluteString
        }
        
        if let remoteThumbURL = self.remoteThumbURL {
            data["remoteThumbURL"] = remoteThumbURL.absoluteString
        }
        
        if let inviteURL = self.inviteURL {
            data["inviteURL"] = inviteURL.absoluteString
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
            
            print("Writing subscribers collection")
            for pid in data["subscribers"] as! [String] {
                docRef.collection("subscribers").addDocument(data: [pid : []])
            }
            
            print("Done")
        }
    }
    
    override func createRemotePath(_ filename:String) -> String {
        return "podcasts/\(String(describing: owner!))/\(pid)/\(filename)"
    }

    func uploadCover(_ cover:UIImage, completion: (()->Void)? = nil) {
        var bothDone = false
        
        if let data = cover.jpegData(compressionQuality: 0.8) {
            print("Uploading cover..")
            
            upload(filename: "cover.jpg", data: data) { (url) in
                self.remoteCoverURL = url
                self.save()
                
                if bothDone {
                    completion?()
                }
                else {
                    bothDone = true
                }
            }
        }
        
        let thumb = cover.kf.resize(to: CGSize(width: 300, height: 300))
        if let data = thumb.pngData() {
            print("Uploading cover thumb..")
            
            self.upload(filename: "cover-thumb.png", data: data) { (url) in
                self.remoteThumbURL = url
                self.save()

                if bothDone {
                    completion?()
                }
                else {
                    bothDone = true
                }
            }
        }
    }
    
    func generateInviteCode(pid: String) -> String {
        guard let tempUuid = NSUUID(uuidString: pid) else {
            return pid
        }
        var tempUuidBytes: [UInt8] = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]
        tempUuid.getBytes(&tempUuidBytes)
        let data = Data(bytes: &tempUuidBytes, count: 16)
        let base64 = data.base64EncodedString(options: NSData.Base64EncodingOptions())
        return base64.replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    static func decodePid(fromInviteURL: URL)  -> String {
        if fromInviteURL.lastPathComponent.count == 22 {
            let base64 = fromInviteURL.lastPathComponent
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
                .appendingFormat("==")

            let data = Data(base64Encoded: base64)
            let uuidBytes = data?.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }
            let tempUuid = NSUUID(uuidBytes: uuidBytes)
            return tempUuid.uuidString
        }
        else {
            return fromInviteURL.lastPathComponent
        }
    }
    
    func delete() {
        let ref = self.getDocumentReference()
        ref.delete()
    }
}
