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
            return year == 1 ? "a year ago" :
                "\(year)" + " " + "years ago"
        } else if let month = interval.month, month > 0 {
            return month == 1 ? "a month ago" :
                "\(month)" + " " + "months ago"
        } else if let day = interval.day, day > 0 {
            return day == 1 ? "Yesterday" :
                "\(day)" + " " + "days ago"
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? "an hour ago" :
                "\(hour)" + " " + "hours ago"
        } else if let minute = interval.minute, minute > 0 {
            return minute == 1 ? "a moment ago" :
                "\(minute)" + " " + "minutes ago"
        } else {
            return "a moment ago"
        }
    }
}

class ControlBinding {
    var control: NSObject
    var setter: ((NSObject, Any?) -> Void)?
    var options: [String: Any]
    
    init(_ control: NSObject, setter: ((NSObject, Any?) -> Void)?, options: [String: Any]? = nil) {
        self.control = control
        self.setter = setter
        self.options = options ?? [String: Any]()
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
            
            if self.options["resize"] != nil {
                control.sizeToFit()
            }
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
            if self.options["asText"] != nil {
                control.setTitle(value.absoluteString, for: UIControl.State.normal)
                control.setTitle(value.absoluteString, for: UIControl.State.disabled)
            }
            else if value.scheme == "asset" {
                control.setImage(UIImage(named: value.host!), for: UIControl.State.normal)
                control.setImage(UIImage(named: value.host!), for: UIControl.State.disabled)
            }
            else if self.options["crop"] != nil {
                let processor = CroppingImageProcessor(size: control.frame.size)
                
                control.kf.setImage(with: value, for: UIControl.State.normal, options: [ .processor(processor) ])
                control.kf.setImage(with: value, for: UIControl.State.disabled, options: [ .processor(processor) ])
            }
            else {
                control.kf.setImage(with: value, for: UIControl.State.normal)
                control.kf.setImage(with: value, for: UIControl.State.disabled)
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
        else if var control = self.control as? [String],
                let value = value as? [String]
        {
            control.removeAll()
            control.append(contentsOf: value)
            print(control)
        }
    }
}

class ControlBindings {
    var bindings: [String:[ControlBinding]] = [:]
    var controls: [NSObject:(String, ControlBinding)] = [:]
    
    func addBinding(forTopic:String, binding: ControlBinding) {
        if controls[binding.control] != nil {
            //print("Control \(binding.control) is already bound.")
            return
        }
        
        if bindings[forTopic] == nil {
            bindings[forTopic] = []
        }
        
        bindings[forTopic]!.append(binding)
        controls[binding.control] = (forTopic, binding)
    }
    
    func addBinding(forTopic:String, control:NSObject, setter:((NSObject, Any)-> Void)? = nil, options:[String: Any]? = nil) {
        let binding = ControlBinding(control, setter: setter, options: options)
        addBinding(forTopic: forTopic, binding: binding)
    }
    
//    func addBinding(forTopic:String, control: NSObject) {
//        addBinding(forTopic:forTopic, control:control, setter:nil, options:nil)
//    }
//
    func removeBinding(_ control: NSObject) {
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
    
    func merge(controlBindings: ControlBindings) {
        controlBindings.bindings.forEach { (topicBinds) in
            let (topic, bindings) = topicBinds
            
            bindings.forEach({ (binding) in
                self.addBinding(forTopic: topic, binding: binding)
            })
        }
    }
}

