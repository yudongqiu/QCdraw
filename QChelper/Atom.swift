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
    var name : String = "N/A"
    var pos : SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
    var radius : CGFloat = 0.4
    var color : [CGFloat] = [0.8, 0.8, 0.8]
    var trajectory : [SCNVector3] = []
}

struct Bond: Hashable {
    var first: Int
    var second: Int
    
    init (_ a: Int, _ b: Int) {
        if a > b {
            self.first = b
            self.second = a
        } else {
            self.first = a
            self.second = b
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.first)
        hasher.combine(self.second)
    }
    
    static func == (lhs: Bond, rhs: Bond) -> Bool {
        return lhs.first == rhs.first && lhs.second == rhs.second
    }
    
    var hashValue: Int {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return hasher.finalize()
    }
}

// information about elements
let ElementsArray : [String] =  ["","h","he","li","be","b","c","n","o","f","ne","na","mg","al","si","p","s","cl","ar","k","ca","sc","ti","v","cr","mn","fe","co","ni","cu","zn","ga","ge","as","se","br","kr","rb","sr","y","zr","nb","mo","tc","ru","rh","pd","ag","cd","in","sn","sb","te","i","xe","cs","ba","la","ce","pr","nd","pm","sm","eu","gd","tb","dy","ho","er","tm","yb","lu","hf","ta","w","re","os","ir","pt","au","hg","tl","pb","bi","po","at","rn","fr","ra","ac","th","pa","u","np","pu","am","cm","bk","cf","es","fm","md","no","lr","rf","db","sg","bh","hs","mt","ds","rg","cn","nh","fl","mc","lv","ts","og"]

let ElementsIdxDict : [String: Int] = Dictionary(uniqueKeysWithValues: zip(ElementsArray, 0..<ElementsArray.count))
