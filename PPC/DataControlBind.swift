//
//  Model.swift
//  PPC
//
//  Created by Justin Day on 2/15/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

class DataControlBind {
    var controls : [String: UIControl] = [:]
    var completions : [String: (UIControl) -> Void] = [:]

    func addControl(topic:String, control:UIControl, completion:((UIControl)->Void)?) {
        
    }
}
