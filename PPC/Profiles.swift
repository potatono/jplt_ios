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
        if let profile = self.lookup[uid] {
            if profile.loaded {
                completion?(profile)
            }
            else if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
                    _ = self.get(uid, completion: completion)
                }
            }
            
            return profile
        }
        else {
            let profile = Profile(uid)
            self.lookup[uid] = profile
            profile.get(completion: completion)
            
            return profile
        }
    }

    static func get(_ uid:String) -> Profile {
        return Profiles.instance().get(uid)
    }
    
    static func me() -> Profile {
        return Profiles.instance().get(Auth.auth().currentUser!.uid, completion: nil)
    }
    
    static func me(completion: ((Profile) -> Void)?) -> Void {
        if let currentUser = Auth.auth().currentUser {
            _ = Profiles.instance().get(currentUser.uid, completion: completion)
        }
    }
}
