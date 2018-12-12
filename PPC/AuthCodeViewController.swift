//
//  AuthCodeViewController.swift
//  PPC
//
//  Created by Justin Day on 12/7/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage

class AuthCodeViewController: UIViewController {
    
    @IBOutlet weak var codeTextField: UITextField!
    
    @IBAction func didSubmitCode(_ sender: Any) {
        let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
        authenticate(verificationID: verificationID!, verificationCode: codeTextField.text!)
    }
    
    func authenticate(verificationID: String, verificationCode:String) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID,
                                                                 verificationCode: verificationCode)

        Auth.auth().signInAndRetrieveData(with: credential) { authData, error in
            if ((error) != nil) {
                // Handles error
                print(error!)
                return
            }
            
            self.performSegue(withIdentifier: "unwindAuthSegue", sender: self)
        };
    }
}
