//
//  FileParser.swift
//  QChelper
//
//  Created by Yudong Qiu on 9/22/15.
//  Copyright © 2015 QYD. All rights reserved.
//

import Foundation



class file_parser {    
    var AtomList : [atom] = []
    let bohr_to_angstrom = 0.529177208
    // Read Elements.plist for Elements Data
    var myDict: NSDictionary?
    init (path: String) {
        if let dpath = Bundle.main.path(forResource: "Elements", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: dpath)
        }
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            var data_source = "unknown"
            for line in aStreamReader {
                if line.contains("PSI4:") {
                    data_source = "psi4"
                    break
                }
                else if line.contains("MOLPRO") {
                    data_source = "molpro"
                    break
                }
                else if line.contains("CFOUR") {
                    data_source = "cfour"
                    break
                }
            }
            aStreamReader.rewind()
            if data_source == "psi4" {
                // find the last geometry section
                var geoline = 0
                var linecount = 0
                for line in aStreamReader {
                    if line.contains("Cartesian Geometry") {
                        geoline = linecount
                    }
                    linecount += 1
                }
                // go to the last geometry section
                aStreamReader.rewind()
                if geoline == 0 { // if optimization not found
                    for line in aStreamReader {
                        if line.contains("Geometry") {
                            break
                        }
                    }
                }
                else { // go to the last optimization point
                    aStreamReader.skiplines(lineNumber: geoline)
                }
                var geofound = false // Did we find the geometry?
                for line in aStreamReader {
                    let inline = line.split()
                    // if the line satisfy all conditions, continue
                    if inline.count == 4 {
                        if let posx = inline[1].doubleValue {
                            if let posy = inline[2].doubleValue {
                                if let posz = inline[3].doubleValue {
                                    var new_atom = atom()
                                    new_atom.name = inline[0] as NSString
                                    new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                                    new_atom.radius = dict_atom_radius(name: new_atom.name)
                                    new_atom.color = dict_atom_color(name: new_atom.name)
                                    AtomList.append(new_atom)
                                    geofound = true
                                    continue
                                }
                            }
                        }
                    }
                    // else break
                    if geofound { break }
                }
            }
            else if data_source == "molpro" {
                // find the last geometry section
                var geoline = 0
                var linecount = 0
                for line in aStreamReader {
                    if line.contains("Current geometry") {
                        geoline = linecount
                    }
                    linecount += 1
                }
                aStreamReader.rewind()
                // if not found, goto first Atomic Coordinates (in Bohr)
                if geoline == 0 {
                    for line in aStreamReader {
                        if line.contains("ATOMIC COORDINATES") {
                            break
                        }
                    }
                    var geofound = false // Did we find the geometry?
                    for line in aStreamReader {
                        let inline = line.split()
                        // if the line satisfy all conditions, continue
                        if inline.count == 6 {
                            if let posx = inline[3].doubleValue {
                                if let posy = inline[4].doubleValue {
                                    if let posz = inline[5].doubleValue{
                                        var new_atom = atom()
                                        new_atom.name = inline[1] as NSString
                                        new_atom.pos = [CGFloat(posx * bohr_to_angstrom),CGFloat(posy * bohr_to_angstrom),CGFloat(posz * bohr_to_angstrom)]
                                        new_atom.radius = dict_atom_radius(name: new_atom.name)
                                        new_atom.color = dict_atom_color(name: new_atom.name)
                                        AtomList.append(new_atom)
                                        geofound = true
                                        continue
                                    }
                                }
                            }
                        }
                        // else break
                        if geofound { break }
                    }
                }
                else { // if found Current geometry in opt jobs
                    // go to the last geometry section
                    aStreamReader.skiplines(lineNumber: geoline+1)
                    var geofound = false // Did we find the geometry?
                    for line in aStreamReader {
                        let inline = line.split()
                        // if the line satisfy all conditions, continue
                        if inline.count == 4 {
                            if let posx = inline[1].doubleValue {
                                if let posy = inline[2].doubleValue {
                                    if let posz = inline[3].doubleValue{
                                        var new_atom = atom()
                                        new_atom.name = inline[0] as NSString
                                        new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                                        new_atom.radius = dict_atom_radius(name: new_atom.name)
                                        new_atom.color = dict_atom_color(name: new_atom.name)
                                        AtomList.append(new_atom)
                                        geofound = true
                                        continue
                                    }
                                }
                            }
                        }
                        // else break
                        if geofound { break }
                    }
                }
            }
            else if data_source == "cfour" {
                // find the last geometry section
                var geoline = 0
                var linecount = 0
                for line in aStreamReader {
                    if line.contains("Coordinates") {
                        geoline = linecount
                    }
                    linecount += 1
                }
                // go to the last geometry section
                aStreamReader.rewind()
                aStreamReader.skiplines(lineNumber: geoline+3)
                
                for line in aStreamReader {
                    let inline = line.split()
                    if inline[0] == "X" { // check if it's a dummy atom
                        continue
                    }
                    // if the line satisfy all conditions, continue
                    if inline.count == 5 {
                        if let posx = inline[2].doubleValue {
                            if let posy = inline[3].doubleValue {
                                if let posz = inline[4].doubleValue{
                                    var new_atom = atom()
                                    new_atom.name = inline[0] as NSString
                                    new_atom.pos = [CGFloat(posx * bohr_to_angstrom),CGFloat(posy * bohr_to_angstrom),CGFloat(posz * bohr_to_angstrom)]
                                    new_atom.radius = dict_atom_radius(name: new_atom.name)
                                    new_atom.color = dict_atom_color(name: new_atom.name)
                                    AtomList.append(new_atom)
                                    continue
                                }
                            }
                        }
                    }
                    // else break
                    break
                }
            }
            else { // xyz file
                var geofound = false // Did we find the geometry?
                for line in aStreamReader {
                    let inline = line.split()
                    // if the line satisfy all conditions, continue
                    if inline.count == 4 {
                        if let posx = inline[1].doubleValue {
                            if let posy = inline[2].doubleValue {
                                if let posz = inline[3].doubleValue{
                                    var new_atom = atom()
                                    new_atom.name = inline[0] as NSString
                                    new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                                    new_atom.radius = dict_atom_radius(name: new_atom.name)
                                    new_atom.color = dict_atom_color(name: new_atom.name)
                                    AtomList.append(new_atom)
                                    geofound = true
                                    continue
                                }
                            }
                        }
                    }
                    // else break
                    if geofound { break }
                }
            }
        }
    }
    
    init() {}
    
    func recenter () {
        var sumx=0.0 as CGFloat, sumy=0.0 as CGFloat, sumz=0.0 as CGFloat
        for atom in self.AtomList {
            sumx += atom.pos[0]
            sumy += atom.pos[1]
            sumz += atom.pos[2]
        }
        let natoms = CGFloat(self.AtomList.count)
        let ave_x = sumx / natoms
        let ave_y = sumy / natoms
        let ave_z = sumz / natoms
        for i in 0..<Int(natoms) {
            self.AtomList[i].pos[0] -= ave_x
            self.AtomList[i].pos[1] -= ave_y
            self.AtomList[i].pos[2] -= ave_z
        }
    }
    
    func dict_atom_radius(name: NSString) -> CGFloat {
        var result : CGFloat = 0.5
        if let dict = myDict {
            if let element_radius = (dict.object(forKey: "Element Radius") as! NSDictionary).object(forKey: name) as? NSNumber {
                result = CGFloat(element_radius.floatValue)
            }
        }
        return result
    }
    
    func dict_atom_color(name: NSString) -> [CGFloat] {
        var result : [CGFloat] = [0.8, 0.8, 0.8]
        if let dict = myDict {
            let element_color = (dict.object(forKey: "Element Colors") as! NSDictionary).object(forKey: name) as? [NSNumber]
            if let color = element_color {
                if color.count == 3{
                    result[0] = CGFloat(color[0].floatValue/255)
                    result[1] = CGFloat(color[1].floatValue/255)
                    result[2] = CGFloat(color[2].floatValue/255)
                }
            }
        }
        return result
    }
}

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
    
}


