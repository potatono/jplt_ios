//
//  Model.swift
//  PPC
//
//  Created by Justin Day on 2/15/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

class Model {
    var bindings: ControlBindings = ControlBindings()
    
    func addBinding(forTopic: String, control: UIView, setter: ((UIView, Any) -> Void)?) {
        bindings.addBinding(forTopic: forTopic, control: control, setter: setter)
        setBindings()
    }
    
    func addBinding(forTopic: String, control: UIView) {
        addBinding(forTopic: forTopic, control: control, setter: nil)
    }
    
    func setBindings() {
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let label = child.label {
                if label != "bindings" {
                    bindings.set(label, child.value)
                }
            }
        }
    }
}
