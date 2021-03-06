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
    func distance(_ vector: SCNVector3) -> CGFloat {
        return (self - vector).length()
    }
    public var stringValue: String {
        return String(format: "(%.3f %.3f %.3f)", x, y, z)
    }
}

// extend String with convenient Python-like methods
let digitSet = CharacterSet.decimalDigits
let letterSet = CharacterSet.letters
extension String {
    func mysplit(_ delimiter: String.Element? = nil) -> [String] {
        if let sep = delimiter {
            let line_split_raw = self.split(separator: sep)
            return line_split_raw.map({String($0)})
        } else {
            var new = self
            // use the if statement here make the common case faster
            if new.contains("\t") {
                new = new.replacingOccurrences(of: "\t", with: " ")
            }
            if new.contains("\n") {
                new = new.replacingOccurrences(of: "\n", with: " ")
            }
            let line_split_raw = new.split(separator: " ")
            return line_split_raw.map({String($0)})
        }
    }
    // Update, below are new features of Swift 4.2, faster than NumberFormatter
    // However, the sting should be striped before calling them, i.e. Double(" 123") = nil
    var doubleValue:Double? {
        return Double(self)
        //return NumberFormatter().number(from: self)?.doubleValue
    }
    var floatValue:Float? {
        return Float(self)
        //return NumberFormatter().number(from: self)?.floatValue
    }
    var integerValue:Int? {
        return Int(self)
        //return NumberFormatter().number(from: self)?.intValue
    }
    func contains(_ find: String) -> Bool {
        return self.range(of: find) != nil
    }
    func containsIgnoringCase(_ find: String) -> Bool {
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    var pathExtension:String { get {
        return (self as NSString).pathExtension
    }}
    var lastPathComponent:String { get {
        return (self as NSString).lastPathComponent
    }}
    func strip() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    func slice(_ start: Int, _ end: Int) -> String {
        if start >= end || start >= self.count || end <= 0 {
            return ""
        }
        let _start = max(0, start)
        let _end = min(self.count, end)
        let _start_idx = self.index(self.startIndex, offsetBy: _start)
        let _end_idx = self.index(self.startIndex, offsetBy: _end)
        return String(self[_start_idx..<_end_idx])
    }
    func extractDigits() -> String {
        return String(self.unicodeScalars.filter({digitSet.contains($0)}))
    }
    func extractLetters() -> String {
        return String(self.unicodeScalars.filter({letterSet.contains($0)}))
    }
}
