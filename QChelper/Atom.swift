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
    var element : String = ""
    var name : String = ""
    var index : Int = -1
    var pos : SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
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
let ElementsArray : [String] =  ["H","He","Li","Be","B","C","N","O","F","Ne","Na","Mg","Al","Si","P","S","Cl","Ar","K","Ca","Sc","Ti","V","Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr","Rb","Sr","Y","Zr","Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I","Xe","Cs","Ba","La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb","Lu","Hf","Ta","W","Re","Os","Ir","Pt","Au","Hg","Tl","Pb","Bi","Po","At","Rn","Fr","Ra","Ac","Th","Pa","U","Np","Pu","Am","Cm","Bk","Cf","Es","Fm","Md","No","Lr","Rf","Db","Sg","Bh","Hs","Mt","Ds","Rg","Cn","Nh","Fl","Mc","Lv","Ts","Og"]

let ElementsIdxDict : [String: Int] = Dictionary(uniqueKeysWithValues: zip(ElementsArray, 1...ElementsArray.count))
