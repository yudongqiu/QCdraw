//
//  Atoms.swift
//  QChelper
//
//  Created by Yudong Qiu on 9/22/15.
//  Copyright © 2015 QYD. All rights reserved.
//

import SceneKit
import Foundation

struct Atom {
    var name : NSString = "N/A"
    var pos : SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
    var radius : CGFloat = 0.4
    var color : [CGFloat] = [0.8, 0.8, 0.8]
    var trajectory : [SCNVector3] = []
}
