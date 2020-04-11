//
//  Badge.swift
//  PPC
//
//  Created by Justin Day on 4/9/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation
import UIKit
 
extension UILabel {
    convenience init(badgeText: String, color: UIColor = UIColor.red, fontSize: CGFloat = UIFont.smallSystemFontSize) {
        self.init()
        text = badgeText
        textColor = UIColor.white
        backgroundColor = color
        font = UIFont.systemFont(ofSize: fontSize)
        textAlignment = .center
        layer.cornerRadius = 15
        clipsToBounds = true
        
        translatesAutoresizingMaskIntoConstraints = false
        
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30))
        addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30))
        //addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
}
