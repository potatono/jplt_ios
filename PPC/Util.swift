//
//  Util.swift
//  PPC
//
//  Created by Justin Day on 4/6/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation

class Util {
    static func httpPost(_ url:URL, data: String, completion: ((String)->Void)? = nil) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data.data(using: String.Encoding.utf8);
        
        print("HTTP POST to \(url.absoluteString) with \(data)")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Check for Error
            if let error = error {
                print("HTTP POST: Error took place \(error)")
                return
            }
     
            // Convert HTTP Response Data to a String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("HTTP POST: Response data string:\n \(dataString)")
                
                completion?(dataString)
            }
        }
        task.resume()
    }
}
