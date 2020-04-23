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
    
    static func shortenId(_ id: String) -> String {
        guard let tempUuid = NSUUID(uuidString: id) else {
            return id
        }
        var tempUuidBytes: [UInt8] = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0]
        tempUuid.getBytes(&tempUuidBytes)
        let data = Data(bytes: &tempUuidBytes, count: 16)
        let base64 = data.base64EncodedString(options: NSData.Base64EncodingOptions())
        return base64.replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    static func restoreId(_ code: String) -> String {
        if code.count == 22 {
            let base64 = code
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
                .appendingFormat("==")
            
            let data = Data(base64Encoded: base64)
            let uuidBytes = data?.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }
            let tempUuid = NSUUID(uuidBytes: uuidBytes)
            return tempUuid.uuidString
        }
        else {
            return code
        }
    }    
}
