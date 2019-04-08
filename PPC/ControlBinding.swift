//
//  ControlBinding.swift
//  PPC
//
//  Created by Justin Day on 2/15/19.
//  Copyright © 2019 Justin Day. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

extension Date {
    func getElapsedInterval() -> String {
        
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date())
        
        if let year = interval.year, year > 0 {
            return year == 1 ? "\(year)" + " " + "year" :
                "\(year)" + " " + "years ago"
        } else if let month = interval.month, month > 0 {
            return month == 1 ? "\(month)" + " " + "month" :
                "\(month)" + " " + "months ago"
        } else if let day = interval.day, day > 0 {
            return day == 1 ? "Yesterday" :
                "\(day)" + " " + "days ago"
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? "\(hour)" + " " + "hour" :
                "\(hour)" + " " + "hours ago"
        } else if let minute = interval.minute, minute > 0 {
            return minute == 1 ? "\(minute)" + " " + "minute" :
                "\(minute)" + " " + "minutes ago"
        } else if let second = interval.second, second > 0 {
            return second == 1 ? "\(second)" + " " + "second" :
                "\(second)" + " " + "seconds ago"
        } else {
            return "a moment ago"
        }
    }
}

class ControlBinding {
    var control: NSObject
    var setter: ((NSObject, Any?) -> Void)?
    
    init(_ control: NSObject, setter: ((NSObject, Any?) -> Void)?) {
        self.control = control
        self.setter = setter
    }
    
    func set(_ value: Any?) {
        if let setter = self.setter
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
        else if let control = self.control as? UILabel,
                let value = value as? Date
        {
            control.text = value.getElapsedInterval()
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
                let processor = CroppingImageProcessor(size: control.frame.size)
                
                control.kf.setImage(with: value, for: UIControl.State.normal, options: [ .processor(processor) ])
                control.kf.setImage(with: value, for: UIControl.State.disabled, options: [ .processor(processor) ])
            }
        }
        else if let control = self.control as? UITableView {
            control.reloadData()
        }
        else if let control = self.control as? UIViewController,
                let value = value as? String
        {
            control.title = value
        }
    }
}

class ControlBindings {
    var bindings: [String:[ControlBinding]] = [:]
    var controls: [NSObject:(String, ControlBinding)] = [:]
    
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
    
    func addBinding(forTopic:String, control:NSObject, setter:((NSObject, Any)-> Void)?) {
        let binding = ControlBinding(control, setter: setter)
        addBinding(forTopic: forTopic, binding: binding)
    }
    
    func addBinding(forTopic:String, control: NSObject) {
        addBinding(forTopic:forTopic, control:control, setter:nil)
    }
    
    func removeBinding(_ control: NSObject) {
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

