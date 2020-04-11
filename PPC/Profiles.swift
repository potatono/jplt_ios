//
//  Profiles.swift
//  PPC
//
//  Created by Justin Day on 2/14/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation

import Firebase
import FirebaseAuth

class Profiles {
    static let _instance:Profiles = Profiles()
    
    var lookup:[String:Profile]
    
    private init() {
        self.lookup = [String:Profile]()
    }
    
    static func instance() -> Profiles {
        return _instance
    }
    
    func get(_ uid:String, completion: ((Profile) -> Void)? = nil) -> Profile {
        if self.lookup[uid] == nil {
            self.lookup[uid] = Profile(uid)
            self.lookup[uid]!.get(completion: completion)
        }
        else {
            completion?(self.lookup[uid]!)
        }
        
        return self.lookup[uid]!
    }

    static func get(_ uid:String) -> Profile {
        return Profiles.instance().get(uid)
    }
    
    static func me() -> Profile {
        return Profiles.instance().get(Auth.auth().currentUser!.uid, completion: nil)
    }
    
    static func me(completion: ((Profile) -> Void)?) -> Void {
        _ = Profiles.instance().get(Auth.auth().currentUser!.uid, completion: completion)
    }
    
    
}
