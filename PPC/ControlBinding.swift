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
            if value.scheme == "asset" {
                control.image = UIImage(named: value.host!)
            }
            else {
                control.kf.setImage(with: value)
            }
        }
        else if let control = self.control as? UIButton,
                let value = value as? URL
        {
            if value.scheme == "asset" {
                control.setImage(UIImage(named: value.host!), for: UIControl.State.normal)
                control.setImage(UIImage(named: value.host!), for: UIControl.State.disabled)
            }
            else {
                control.kf.setImage(with: value, for: UIControl.State.normal)
                control.kf.setImage(with: value, for: UIControl.State.disabled)
            }
        }
        else if let control = self.control as? UITableView {
            control.reloadData()
        }
    }
}

class ControlBindings {
    var bindings: [String:[ControlBinding]] = [:]
    var controls: [UIView:(String, ControlBinding)] = [:]
    
    func addBinding(forTopic:String, binding: ControlBinding) {
        if controls[binding.control] != nil {
            print("Control is already bound.")
            return
        }
        
        if bindings[forTopic] == nil {
            bindings[forTopic] = []
        }
        
        bindings[forTopic]!.append(binding)
        controls[binding.control] = (forTopic, binding)
    }
    
    func addBinding(forTopic:String, control:UIView, setter:((UIView, Any)-> Void)?) {
        let binding = ControlBinding(control, setter: setter)
        addBinding(forTopic: forTopic, binding: binding)
    }
    
    func addBinding(forTopic:String, control: UIView) {
        addBinding(forTopic:forTopic, control:control, setter:nil)
    }
    
    func removeBinding(_ control: UIView) {
        if let (forTopic, binding) = controls[control] {
            bindings[forTopic]!.removeAll(where: { $0 === binding })
            controls.removeValue(forKey: control)
        }
        else {
            print("Binding not found to remove")
        }
    }
    
    func set(_ forTopic:String, _ value:Any?) {
        if let bindings = self.bindings[forTopic] {
            for binding in bindings {
                binding.set(value)
            }
        }
    }
    
    func merge(controlBindings: ControlBindings) {
        controlBindings.bindings.forEach { (topicBinds) in
            let (topic, bindings) = topicBinds
            
            bindings.forEach({ (binding) in
                self.addBinding(forTopic: topic, binding: binding)
            })
        }
    }
}

