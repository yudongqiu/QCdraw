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
    init (path: String) {
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            var data_source = "unknown"
            for line in aStreamReader {
                if line.containsString("PSI4:") {
                    data_source = "psi4"
                    break
                }
                else if line.containsString("MOLPRO") {
                    data_source = "molpro"
                    break
                }
                else if line.containsString("CFOUR") {
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
                    if line.containsString("Cartesian Geometry") {
                        geoline = linecount
                    }
                    linecount++
                }
                // go to the last geometry section
                aStreamReader.rewind()
                if geoline == 0 { // if optimization not found
                    for line in aStreamReader {
                        if line.containsString("Geometry") {
                            break
                        }
                    }
                }
                else { // go to the last optimization point
                    for _ in 0..<geoline {
                        aStreamReader.nextLine()
                    }
                }
                var geofound = false // Did we find the geometry?
                for line in aStreamReader {
                    let inline = line.split()
                    // if the line satisfy all conditions, continue
                    if inline.count == 4 {
                        if let posx = inline[1].doubleValue {
                            if let posy = inline[2].doubleValue {
                                if let posz = inline[3].doubleValue{
                                    var new_atom = atom()
                                    new_atom.name = inline[0]
                                    new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                                    new_atom.radius = dict_atom_radius(new_atom.name)
                                    new_atom.color = dict_atom_color(new_atom.name)
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
                    if line.containsString("Current geometry") {
                        geoline = linecount
                    }
                    linecount++
                }
                aStreamReader.rewind()
                // if not found, goto first Atomic Coordinates (in Bohr)
                if geoline == 0 {
                    for line in aStreamReader {
                        if line.containsString("ATOMIC COORDINATES") {
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
                                        new_atom.name = inline[1]
                                        new_atom.pos = [CGFloat(posx * bohr_to_angstrom),CGFloat(posy * bohr_to_angstrom),CGFloat(posz * bohr_to_angstrom)]
                                        new_atom.radius = dict_atom_radius(new_atom.name)
                                        new_atom.color = dict_atom_color(new_atom.name)
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
                    for _ in 0...geoline {
                        aStreamReader.nextLine()
                    }
                    var geofound = false // Did we find the geometry?
                    for line in aStreamReader {
                        let inline = line.split()
                        // if the line satisfy all conditions, continue
                        if inline.count == 4 {
                            if let posx = inline[1].doubleValue {
                                if let posy = inline[2].doubleValue {
                                    if let posz = inline[3].doubleValue{
                                        var new_atom = atom()
                                        new_atom.name = inline[0]
                                        new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                                        new_atom.radius = dict_atom_radius(new_atom.name)
                                        new_atom.color = dict_atom_color(new_atom.name)
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
                    if line.containsString("Coordinates") {
                        geoline = linecount
                    }
                    linecount++
                }
                // go to the last geometry section
                aStreamReader.rewind()
                for _ in 0...geoline+2 {
                    aStreamReader.nextLine()
                }
                
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
                                    new_atom.name = inline[0]
                                    new_atom.pos = [CGFloat(posx * bohr_to_angstrom),CGFloat(posy * bohr_to_angstrom),CGFloat(posz * bohr_to_angstrom)]
                                    new_atom.radius = dict_atom_radius(new_atom.name)
                                    new_atom.color = dict_atom_color(new_atom.name)
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
                                    new_atom.name = inline[0]
                                    new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                                    new_atom.radius = dict_atom_radius(new_atom.name)
                                    new_atom.color = dict_atom_color(new_atom.name)
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
    
    func dict_atom_radius(name: NSString) -> CGFloat {
        var result : CGFloat = 0.5
        // Read Elements.plist for Elements Data
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Elements", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            let element_radius = dict.objectForKey("Element Radius")?.objectForKey(name)
            if let radius = element_radius?.floatValue {
                result = CGFloat(radius)
            }
        }
        return result
    }
    
    func dict_atom_color(name: NSString) -> [CGFloat] {
        var result : [CGFloat] = [0.8, 0.8, 0.8]
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Elements", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            let element_color = dict.objectForKey("Element Colors")?.objectForKey(name)
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
        let line_split_raw = self.componentsSeparatedByString(delimiter)
        var line_split : [String] = []
        for item in line_split_raw {
            if item != "" && item != "\t" && item != " " {
                line_split.append(item)
            }
        }
        return(line_split)
    }
    struct NumberFormatter {
        static let instance = NSNumberFormatter()
    }
    var doubleValue:Double? {
        return NumberFormatter.instance.numberFromString(self)?.doubleValue
    }
    var floatValue:Float? {
        return NumberFormatter.instance.numberFromString(self)?.floatValue
    }
    var integerValue:Int? {
        return NumberFormatter.instance.numberFromString(self)?.integerValue
    }
}


