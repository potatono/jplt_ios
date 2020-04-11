//
//  Notifications.swift
//  PPC
//
//  Created by Justin Day on 4/6/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth


class Notifications : Model {
    private static var instance: Notifications? = nil
    
    var listenerRegistration: ListenerRegistration?
    
    var uid: String
    var fcmTokens: [String]
    var unread: Int
    var unreads: [String: Int]

    private init(uid: String) {
        self.uid = uid
        self.fcmTokens = []
        self.unread = 0
        self.unreads = [:]
    }
    
    static func me() -> Notifications {
        return getInstance(uid: Auth.auth().currentUser!.uid)
    }
    
    static func getInstance(uid: String) -> Notifications {
        Notifications.instance = Notifications.instance ?? Notifications(uid: uid)
        
        return Notifications.instance!
    }
    
    func getDocumentReference() -> DocumentReference {
        let db = Firestore.firestore()
        let doc = db.collection("notifications").document(uid)
        return doc
    }
    
    deinit {
        if let listenerRegistration = self.listenerRegistration {
            listenerRegistration.remove()
        }
    }
    
    func listen(completion: ((Notifications) -> Void)? = nil) {
        if listenerRegistration == nil {
            let docRef = getDocumentReference()
            listenerRegistration = docRef.addSnapshotListener { (snap, err) in
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
    
    func restore(_ data: [String:Any]) {
        if let fcmTokens = data["fcmTokens"] as? [String] {
            self.fcmTokens = fcmTokens
        }
        
        if let unread = data["unread"] as? Int {
            self.unread = unread
        }
        
        if let unreads = data["unreads"] as? [String:Int] {
            self.unreads = unreads
        }
        
        self.setBindings()
    }
    
    func save() {
        let docref = self.getDocumentReference()
        
        let doc: [String: Any] = [
            "uid": uid,
            "fcmTokens": fcmTokens,
            "unread": unread,
            "unreads": unreads
        ]
        
        docref.setData(doc) { err in
            if let err = err {
                print ("Error writing profile \(err)")
            }
            else if self.listenerRegistration == nil {
                self.listen()
            }
        }
    }
    
    func updateFcmTokens() {
         InstanceID.instanceID().instanceID { (result, error) in
             if let error = error {
                print("Error fetching remote instance ID: \(error)")
             }
             else if let result = result {
                print("Remote instance ID token: \(result.token)")

                let doc = self.getDocumentReference()
                doc.getDocument() { snap, err in
                    if err != nil {
                        print("Error fetching Notifications: \(err!)")
                    }
                    if snap?.exists ?? false {
                        print("exists? \(snap!.exists)")
                        print("Updating existing fcmTokens..")
                        doc.updateData(["fcmTokens": FieldValue.arrayUnion([ result.token ])])
                        
                        if let data = snap?.data() {
                            self.restore(data)
                            print("unread=\(self.unread) unreads=\(self.unreads)")
                        }
                    }
                    else {
                        print("Saving new Notifications.")
                        self.fcmTokens.append(result.token)
                        self.save()
                    }
                }
             }
         }
     }
    
    static func send(episode: Episode, podcast: Podcast) {
        var n = 0
        
        for uid in podcast.subscribers {
            if uid == podcast.owner { continue }
            
            print("Sending notification to " + uid)
            let name = podcast.name!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            var data = "pid=" + podcast.pid
            data += "&uid=" + uid
            data += "&eid=" + episode.id
            data += "&name=" + name
            
            let url = URL(string: "https://jplt.com/notify")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(n)) {
                Util.httpPost(url!, data:data)
            }
            
            n += 250
        }
        
        episode.notified = true
        episode.save()
    }
    
    func clearUnread(pid: String) {
        let n = unreads[pid] ?? 0
        let doc = self.getDocumentReference()
        
        unreads[pid] = 0
        unread -= n
        
        if (n > 0) {
            let data:[String:Any] = [
                "unreads": FieldValue.arrayRemove([pid]),
                "unread": FieldValue.increment(Int64(-n))
            ]
            
            doc.updateData(data)
            UIApplication.shared.applicationIconBadgeNumber = unread
        }
    }
    
    func housekeeping() {
        var totalUnread = 0
        Profiles.me() { profile in
            for (pid, unread) in self.unreads {
                if !profile.subscriptions.contains(pid) {
                    self.clearUnread(pid: pid)
                }
                else {
                    totalUnread += unread
                }
            }
            
            UIApplication.shared.applicationIconBadgeNumber = totalUnread
        }
    }
}
