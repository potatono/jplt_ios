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
    static var PID : String = "testing"
    
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
        
        col.order(by: "createDate", descending: true).addSnapshotListener { (snap, err) in
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
                    else if (
                        diff.type == DocumentChangeType.added ||
                        self.dict.index(forKey:doc.documentID) == nil
                    ) {
                        let episode = Episode(doc.documentID)
                        self.dict[doc.documentID] = episode
                        episode.listen()
                        self.list.append(episode)
                        
                        self.list.insert(episode, at: Int(diff.newIndex))
                    }
                }

                self.bindings.set("reload", self.list)
            }
        }
    }
}
