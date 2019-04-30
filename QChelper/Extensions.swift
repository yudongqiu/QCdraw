//
//  Extensions.swift
//  QCdraw
//
//  Created by Yudong Qiu on 4/30/19.
//  Copyright © 2019 QYD. All rights reserved.
//

import SceneKit
import Foundation


// extend SCNVector 3 to have vectorized operations
extension SCNVector3
{
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    static func += (left: inout SCNVector3, right: SCNVector3) {
        left = left + right
    }
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    static func -= (left: inout SCNVector3, right: SCNVector3) {
        left = left - right
    }
    static func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
    }
    static func *= (left: inout SCNVector3, right: SCNVector3) {
        left = left * right
    }
    static func * (vector: SCNVector3, scalar: CGFloat) -> SCNVector3 {
        return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
    static func *= (vector: inout SCNVector3, scalar: CGFloat) {
        vector = vector * scalar
    }
    static func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
    }
    static func /= (left: inout SCNVector3, right: SCNVector3) {
        left = left / right
    }
    static func / (vector: SCNVector3, scalar: CGFloat) -> SCNVector3 {
        return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
    }
    static func /= (vector: inout SCNVector3, scalar: CGFloat) {
        vector = vector / scalar
    }
    static func ~= (left: SCNVector3, right: SCNVector3) -> Bool {
        let tolerance : CGFloat = 0.0001
        if abs(left.x - right.x) < tolerance && abs(left.y - right.y) < tolerance && abs(left.z - right.z) < tolerance {
            return true
        }
        else {
            return false
        }
    }
    func lengthSq() -> CGFloat {
        return x*x + y*y + z*z
    }
    func length() -> CGFloat {
        return sqrt(x*x + y*y + z*z)
    }
    func distance(vector: SCNVector3) -> CGFloat {
        return (self - vector).length()
    }
    public var stringValue: String {
        return String(format: "(%.3f %.3f %.3f)", x, y, z)
    }
}

// extend String with convenient Python-like methods

extension String {
    func split(delimiter: String = " ") -> [String] {
        let line_split_raw = self.components(separatedBy: delimiter)
        var line_split : [String] = []
        for item in line_split_raw {
            if item != "" && item != "\t" && item != " " {
                line_split.append(item)
            }
        }
        return(line_split)
    }
    var doubleValue:Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
    var floatValue:Float? {
        return NumberFormatter().number(from: self)?.floatValue
    }
    var integerValue:Int? {
        return NumberFormatter().number(from: self)?.intValue
    }
    func contains(_ find: String) -> Bool{
        return self.range(of: find) != nil
    }
    func containsIgnoringCase(_ find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    var pathExtension:String { get {
        return (self as NSString).pathExtension
    }}
    var lastPathComponent:String { get {
        return (self as NSString).lastPathComponent
    }}
}
