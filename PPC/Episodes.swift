//
//  Episodes.swift
//  PPC
//
//  Created by Justin Day on 12/15/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import Foundation

import Firebase
import FirebaseAuth

class Episodes : Model {
    static var PID : String = "prealpha"
    
    var listenerRegistration: ListenerRegistration?
    var dict: [String:Episode] = [:]
    var list: [Episode] = []
    
    deinit {
        if let listenerRegistration = listenerRegistration {
            listenerRegistration.remove()
        }
    }
    
    func getCollection() -> CollectionReference {
        let db = Firestore.firestore()
        let pid = Episodes.PID
        let col = db.collection("podcasts").document(pid).collection("episodes")
        
        return col
    }
    
    func listen() {
        let col = getCollection()
        
        if let listenerRegistration = listenerRegistration {
            listenerRegistration.remove()
        }
        
        listenerRegistration = col.order(by: "createDate", descending: true).addSnapshotListener { (snap, err) in
            if err != nil {
                print("Error getting documents \(err!)")
            }
            else {
                for diff in snap!.documentChanges {
                    let doc = diff.document
                    
                    if diff.type == DocumentChangeType.removed {
                        self.dict.removeValue(forKey: doc.documentID)
                        self.list.removeAll(where: { $0.id == doc.documentID })
                    }
                    else if (self.dict.index(forKey:doc.documentID) == nil) {
                        let episode = Episode(doc.documentID)
                        self.dict[doc.documentID] = episode
                        self.list.insert(episode, at: Int(diff.newIndex))
                        episode.listen()
                    }
                }
                
                self.bindings.set("reload", self.list)
            }
        }
    }
    
    func changePid(pid: String) {
        Episodes.PID = pid
        self.dict = [:]
        self.list = []
        self.listen()
    }
    
    static func changeToDefault(completion: ((String) -> Void)? = nil) {
        print("Episodes changeToDefault")
        if Auth.auth().currentUser != nil {
            _ = Profiles.me() { (profile) in
                if profile.subscriptions.count > 0 {
                    Episodes.PID = profile.subscriptions[0]
                }
                else if let username = profile.username {
                    print("Creating initial podcast..")
                    let podcast = Podcast()
                    podcast.name = username + "'s Podcast"
                    
                    
                    podcast.save()
                    profile.subscriptions.append(podcast.pid)
                    profile.save()
                    Episodes.PID = podcast.pid
                    
                    print("Adding help episode to new podcast..")
                    let episode = Episode()
                    episode.remoteURL = URL(string:"https://firebasestorage.googleapis.com/v0/b/personalpodcastapp.appspot.com/o/podcasts%2F77gRdgetwSO5QhQvBhPiWhNgG632%2Fepisodes%2F99CE14A6-BE3E-4111-9EA8-A6690FC802F5%2Fsound.m4a?alt=media&token=7c299293-fa3a-4dee-b48b-280254f2dabb")!
                    episode.owner = profile.uid
                    episode.title = "Welcome to JPLT"
                    episode.notified = true
                    episode.published = true
                    episode.save()
                    
                }
                
                completion?(Episodes.PID)
            }
        }
    }
}
