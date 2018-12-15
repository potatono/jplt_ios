//
//  MainViewController.swift
//  PPC
//
//  Created by Justin Day on 12/12/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class MainViewController: UINavigationController {

    // MARK: Properties

    // MARK: Actions
    @IBAction func unwindAuth(unwindSegue: UIStoryboardSegue) {
        
    }
    
    // MARK: Overridden Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let img = UIImage(named: "jplt3")
        self.navigationBar.setBackgroundImage(img, for: UIBarMetrics.default)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        ensureUser()
    }
    
    // MARK: Private Methods
    func ensureUser() {
        if let user = Auth.auth().currentUser {
            print("[AUTH] User is", user.uid)
            print("[AUTH] User phone is", user.phoneNumber as Any)
        }
        else {
            print("[AUTH] No user")
            self.performSegue(withIdentifier: "authPhoneSegue", sender: self)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch _ { print("Sign Out Failed.") }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
