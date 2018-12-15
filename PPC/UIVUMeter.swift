//
//  VUMeter.swift
//  PPC
//
//  Created by Justin Day on 11/6/18.
//  Copyright © 2018 Justin Day. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class UIVUMeter: UIControl {

    let barWidth = 2
    let barMargin = 2
    
    var samples = [Float]()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let ctx = UIGraphicsGetCurrentContext()
        let width = Int(self.frame.width)
        let height = Int(self.frame.height)
        
        var i = samples.count - 1
        var x = width - barWidth

        ctx!.setFillColor(red: 176/256.0, green: 224/256.0, blue: 236/256.0, alpha: 1.0)
        while x >= 0 && i >= 0 {
            let h = Int(samples[i] * Float(height))
            ctx!.addRect(CGRect(x: x, y: height / 2 - h / 2, width: barWidth, height: h))
            x -= (barWidth + barMargin)
            i -= 1
        }
        
        ctx!.drawPath(using: CGPathDrawingMode.fill)
    }
    
    func addSample(sample:Float) {
        let adjustedSample = min(max(sample + 32.0, 0) / 32.0, 1.0)
        samples.append(adjustedSample)
        self.setNeedsDisplay()
    }
}
