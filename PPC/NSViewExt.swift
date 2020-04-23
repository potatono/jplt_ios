//
//  NSViewExt.swift
//  PPC
//
//  Created by Justin Day on 4/20/20.
//  Copyright © 2020 Justin Day. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func constraint(withIdentifier: String) -> NSLayoutConstraint? {
        return self.constraints.filter { $0.identifier == withIdentifier }.first
    }
}
