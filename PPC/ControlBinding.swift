//
//  ControlBinding.swift
//  PPC
//
//  Created by Justin Day on 2/15/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit

class ControlBinding {
    var control: UIView
    var setter: ((UIView, Any) -> Void)?
    
    init(_ control: UIView, setter: ((UIView, Any) -> Void)?) {
        self.control = control
        self.setter = setter
    }
    
    func set(_ value: Any?) {
        if let setter = self.setter,
           let value = value
        {
            setter(control, value)
        }
        else if let control = self.control as? UITextField,
                let value = value as? String
        {
            control.text = value
        }
        else if let control = self.control as? UILabel,
                let value = value as? String
        {
            control.text = value
        }
        else if let control = self.control as? UIImageView,
                let value = value as? URL
        {
            control.kf.setImage(with: value)
        }
        else if let control = self.control as? UIButton,
                let value = value as? URL
        {
            control.kf.setImage(with: value, for: UIControl.State.normal)
            control.kf.setImage(with: value, for: UIControl.State.disabled)
        }
    }
}

class ControlBindings {
    var bindings: [String:[ControlBinding]] = [:]
    var controls: [UIView:(String, ControlBinding)] = [:]
    
    func addBinding(forTopic:String, control:UIView, setter:((UIView, Any)-> Void)?) {
        if bindings[forTopic] == nil {
            bindings[forTopic] = []
        }
        
        let binding = ControlBinding(control, setter: setter)
        bindings[forTopic]!.append(binding)
        controls[control] = (forTopic, binding)
    }
    
    func addBinding(forTopic:String, control: UIView) {
        addBinding(forTopic:forTopic, control:control, setter:nil)
    }
    
    func removeBinding(_ control: UIView) {
        if let (forTopic, binding) = controls[control] {
            bindings[forTopic]!.removeAll(where: { $0 === binding })
            controls.removeValue(forKey: control)
        }
    }
    
    func set(_ forTopic:String, _ value:Any?) {
        if let bindings = self.bindings[forTopic] {
            for binding in bindings {
                binding.set(value)
            }
        }
    }
}

