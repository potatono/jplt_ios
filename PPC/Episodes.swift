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

class Episodes {
    var dict: [String:Episode] = [:]
    var list: [Episode] = []
    
    func getCollection() -> CollectionReference {
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser!.uid
        let col = db.collection("podcasts").document(uid).collection("episodes")
        
        return col
    }
    
    func addListener(completion: @escaping ([Episode])->Void) {
        Episode.listener = completion
        let col = getCollection()
        
        col.addSnapshotListener { (snap, err) in
            if err != nil {
                print("Error getting documents \(err!)")
            }
            else {
                
                for doc in snap!.documents {
                    let data = doc.data()
                    let episode = Episode(doc.documentID)
                    
                    episode.update(data) { episode in
                        completion(self.list)
                    }
                    self.dict[doc.documentID] = episode
                }
                self.list = Array(self.dict.values)
                
                completion(self.list)
            }
        }
    }
    
}
