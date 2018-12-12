//
//  AuthNumberViewController.swift
//  PPC
//
//  Created by Justin Day on 12/7/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage

class AuthNumberViewController: UIViewController {
    @IBOutlet weak var phoneTextField: UITextField!

    @IBAction func didSubmitNumber(_ sender: Any) {
        let phoneNumber = transform(phoneNumber: phoneTextField.text!)
        requestAuthenticationCode(phoneNumber: phoneNumber);
        UserDefaults.standard.set(phoneNumber, forKey: "authPhoneNumber")
    }
    
    override func viewDidLoad() {
        if let phoneNumber = UserDefaults.standard.string(forKey: "authPhoneNumber") {
            phoneTextField.text = phoneNumber
        }
    }

    func transform(phoneNumber: String) -> String {
        let regex = try! NSRegularExpression(pattern: "(\\d+)")
        let matches = regex.matches(in: phoneNumber,
                                    range: NSRange(phoneNumber.startIndex...,
                                                   in: phoneNumber))
        
        let digits = matches.map {
            String(phoneNumber[Range($0.range, in: phoneNumber)!])
            }.joined()
        
        if (!digits.starts(with: "1")) {
            return "+1" + digits
        }
        else {
            return "+" + digits
        }
    }
    
    func requestAuthenticationCode(phoneNumber:String) {
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            } else if let result = result {
                print("Remote InstanceID token: \(result.token)")
            }
        }

        PhoneAuthProvider.provider().verifyPhoneNumber(
            phoneNumber, uiDelegate: nil)
        { (verificationID, error) in
        
            if let error = error {
                print("Got an error trying to verify the phone number.")
                print(error.localizedDescription)
                return
            }

            print("Verification is is \(verificationID!)")
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
        }        
    }
}

