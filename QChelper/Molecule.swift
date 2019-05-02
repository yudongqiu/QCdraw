//
//  FileParser.swift
//  QChelper
//
//  Created by Yudong Qiu on 9/22/15.
//  Copyright © 2015 QYD. All rights reserved.
//

import Foundation
import SceneKit

enum MoleculeError: Error {
    case fileNotRecognized
}

class Molecule {
    var atomlist : [Atom] = []
    let bohr_to_angstrom = 0.529177208
    var myDict: NSDictionary?
    
    var traj_length: Int { get {
        var res = 0
        if self.atomlist.count > 0 {
            res = self.atomlist[0].trajectory.count
        }
        return res
    }}
    
    init() {
        // Read Elements.plist for Elements Data
        if let dpath = Bundle.main.path(forResource: "Elements", ofType: "plist") {
            self.myDict = NSDictionary(contentsOfFile: dpath)
        }
    }
    
    init (path: String) throws {
        // Read Elements.plist for Elements Data
        if let dpath = Bundle.main.path(forResource: "Elements", ofType: "plist") {
            self.myDict = NSDictionary(contentsOfFile: dpath)
        }
        try self.load(path: path)
    }
    
    init (text: String, unit: String?) {
        // Read Elements.plist for Elements Data
        if let dpath = Bundle.main.path(forResource: "Elements", ofType: "plist") {
            self.myDict = NSDictionary(contentsOfFile: dpath)
        }
        self.read_text(text: text, unit: unit)
    }
    
    func load (path: String) throws {
        let file_format = self.determine_file_format(path: path)
        if file_format == "xyz" {
            self.read_xyz(path: path)
        } else if file_format == "pdb" {
            self.read_pdb(path: path)
        } else if file_format == "psi4" {
            self.read_psi4(path: path)
        } else if file_format == "molpro" {
            self.read_molpro(path: path)
        } else if file_format == "cfour" {
            self.read_cfour(path: path)
        } else {
            throw MoleculeError.fileNotRecognized
        }
    }
    
    func determine_file_format(path: String) -> String {
        var res: String = "unknown"
        let ext = path.pathExtension
        if ext == "xyz"{
            res = "xyz"
        } else if ext == "pdb" {
            res = "pdb"
        } else {
            if let aStreamReader = StreamReader(path: path) {
                defer {
                    aStreamReader.close()
                }
                for line in aStreamReader {
                    let s = line.lowercased()
                    if s.contains("psi4") {
                        res = "psi4"
                        break
                    }
                    else if s.contains("molpro") {
                        res = "molpro"
                        break
                    }
                    else if s.contains("cfour") {
                        res = "cfour"
                        break
                    }
                }
            }
        }
        return res
    }
    
    func add_new_atom(name: String, posx: Double, posy: Double, posz: Double, trajectory: [SCNVector3] = []) {
        var new_atom = Atom()
        new_atom.name = name.capitalized as NSString
        new_atom.pos = SCNVector3(posx, posy, posz)
        new_atom.radius = dict_atom_radius(name: new_atom.name)
        new_atom.color = dict_atom_color(name: new_atom.name)
        new_atom.trajectory = trajectory
        self.atomlist.append(new_atom)
    }
    
    func read_text(text: String, unit: String? = "angstrom") {
        self.atomlist = []
        let text_lines = text.split(delimiter: "\n")
        // convertion factor based on unit
        let conv = (unit == "bohr") ? bohr_to_angstrom : 1.0
        for line in text_lines {
            let inline = line.split()
            // if the line satisfy all conditions, continue
            if inline.count == 4 {
                if let posx = inline[1].doubleValue {
                    if let posy = inline[2].doubleValue {
                        if let posz = inline[3].doubleValue {
                            let name = inline[0]
                            let x = posx * conv
                            let y = posy * conv
                            let z = posz * conv
                            self.add_new_atom(name: name, posx: x, posy: y, posz: z)
                        }
                    }
                }
            }
            if inline.count == 5 {
                if let posx = inline[2].doubleValue {
                    if let posy = inline[3].doubleValue {
                        if let posz = inline[4].doubleValue {
                            var name: String = "X"
                            if inline[0].doubleValue == nil {
                                name = inline[0]
                            }
                            else if inline[1].doubleValue == nil {
                                name = inline[1]
                            }
                            let x = posx * conv
                            let y = posy * conv
                            let z = posz * conv
                            self.add_new_atom(name: name, posx: x, posy: y, posz: z)
                            continue
                        }
                    }
                }
            }
            if inline.count == 6 {
                if let posx = inline[3].doubleValue {
                    if let posy = inline[4].doubleValue {
                        if let posz = inline[5].doubleValue{
                            let name = inline[1]
                            let x = posx * conv
                            let y = posy * conv
                            let z = posz * conv
                            self.add_new_atom(name: name, posx: x, posy: y, posz: z)
                            continue
                        }
                    }
                }
            }
        }
    }
    
    func read_xyz(path: String) {
        self.atomlist = []
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            var block_elem_list: [[String]] = []
            var block_geo_list: [[[Double]]] = []
            while true {
                if var line = aStreamReader.nextLine() {
                    line = line.strip()
                    let ls = line.split()
                    if ls.count == 1 {
                        if let noa = ls[0].integerValue {
                            // start a new geo block
                            var elems: [String] = []
                            var geo: [[Double]] = []
                            aStreamReader.skiplines(lineNumber: 1)
                            for _ in 0 ..< noa {
                                if let geoline = aStreamReader.nextLine() {
                                    let inline = geoline.split()
                                    if inline.count == 4 {
                                        if let posx = inline[1].doubleValue {
                                            if let posy = inline[2].doubleValue {
                                                if let posz = inline[3].doubleValue{
                                                    let xyz = [posx, posy, posz]
                                                    elems.append(inline[0])
                                                    geo.append(xyz)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    break
                                }
                            }
                            block_elem_list.append(elems)
                            block_geo_list.append(geo)
                        }
                    }
                } else {
                    break
                }
            }
            if block_elem_list.count >= 1 {
                let elems = block_elem_list[0]
                let init_geo = block_geo_list[0]
                for i in 0 ..< elems.count {
                    let name = elems[i]
                    let pos = init_geo[i]
                    var traj : [SCNVector3] = []
                    // only create trajectory if there are > 1 frames
                    if block_elem_list.count > 1 {
                        for geo in block_geo_list {
                            let atom_xyz = geo[i]
                            traj.append(SCNVector3(atom_xyz[0], atom_xyz[1], atom_xyz[2]))
                        }
                    }
                    self.add_new_atom(name: name, posx: pos[0], posy: pos[1], posz: pos[2], trajectory: traj)
                }
            }
        }
    }
    
    func read_psi4(path: String) {
        self.atomlist = []
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
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
                                self.add_new_atom(name: inline[0], posx: posx, posy: posy, posz: posz)
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
    
    func read_molpro(path: String) {
        self.atomlist = []
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
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
                                    let name = inline[1]
                                    let x = posx * bohr_to_angstrom
                                    let y = posy * bohr_to_angstrom
                                    let z = posz * bohr_to_angstrom
                                    self.add_new_atom(name: name, posx: x, posy: y, posz: z)
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
                                    self.add_new_atom(name: inline[0], posx: posx, posy: posy, posz: posz)
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
    
    func read_cfour(path: String) {
        self.atomlist = []
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
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
                                let name = inline[0]
                                let x = posx * bohr_to_angstrom
                                let y = posy * bohr_to_angstrom
                                let z = posz * bohr_to_angstrom
                                self.add_new_atom(name: name, posx: x, posy: y, posz: z)
                                continue
                            }
                        }
                    }
                }
                // else break
                break
            }
        }
    }
    
    func read_pdb(path: String) {
        """
        PDB is a strict format, I am following instructions here:
        http://deposit.rcsb.org/adit/docs/pdb_atom_format.html#ATOM
        COLUMNS        DATA TYPE       CONTENTS
        --------------------------------------------------------------------------------
        1 -  6         Record name     "ATOM  "
        7 - 11         Integer         Atom serial number.
        13 - 16        Atom            Atom name.
        17             Character       Alternate location indicator.
        18 - 20        Residue name    Residue name.
        22             Character       Chain identifier.
        23 - 26        Integer         Residue sequence number.
        27             AChar           Code for insertion of residues.
        31 - 38        Real(8.3)       Orthogonal coordinates for X in Angstroms.
        39 - 46        Real(8.3)       Orthogonal coordinates for Y in Angstroms.
        47 - 54        Real(8.3)       Orthogonal coordinates for Z in Angstroms.
        55 - 60        Real(6.2)       Occupancy.
        61 - 66        Real(6.2)       Temperature factor (Default = 0.0).
        73 - 76        LString(4)      Segment identifier, left-justified.
        77 - 78        LString(2)      Element symbol, right-justified.
        79 - 80        LString(2)      Charge on the atom.
        
        http://www.bmsc.washington.edu/CrystaLinks/man/pdb/part_69.html
        Record Format
        COLUMNS         DATA TYPE        FIELD           DEFINITION
        ---------------------------------------------------------------------------------
        1 -  6          Record name      "CONECT"
        7 - 11          Integer          serial          Atom serial number
        12 - 16         Integer          serial          Serial number of bonded atom
        17 - 21         Integer          serial          Serial number of bonded atom
        22 - 26         Integer          serial          Serial number of bonded atom
        27 - 31         Integer          serial          Serial number of bonded atom
        32 - 36         Integer          serial          Serial number of hydrogen bonded atom
        37 - 41         Integer          serial          Serial number of hydrogen bonded atom
        42 - 46         Integer          serial          Serial number of salt bridged atom
        47 - 51         Integer          serial          Serial number of hydrogen bonded atom
        52 - 56         Integer          serial          Serial number of hydrogen bonded atom
        57 - 61         Integer          serial          Serial number of salt bridged atom
        """
        self.atomlist = []
        // open the element radius dictionary
        let dict_element_radius = myDict!.object(forKey: "Element Radius") as! Dictionary<String,Any>
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            var found_geo = false
            for line in aStreamReader {
                if line.slice(0,6) == "ATOM  "{
                    // determine element
                    var element = "X"
                    if line.count >= 78 {
                        element = line.slice(76, 78).strip()
                    } else {
                        // use the first 2 character of "name" field if element symbol not provided
                        element = line.slice(12, 14).strip().capitalized
                        if dict_element_radius[element] == nil {
                            // use the first character of the "name" field is element not recognized
                            element = line.slice(12, 13)
                        }
                    }
                    // determine pos
                    if let x = line.slice(30, 38).doubleValue {
                        if let y = line.slice(38, 46).doubleValue {
                            if let z = line.slice(46, 54).doubleValue {
                                self.add_new_atom(name: element, posx: x, posy: y, posz: z)
                            }
                        }
                    }
                    found_geo = true
                }
                // else break
                else if found_geo {
                    break
                }
            }
        }
    }

    
    func recenter () {
        var average_pos = SCNVector3()
        for atom in self.atomlist {
            average_pos += atom.pos
        }
        let natoms = CGFloat(self.atomlist.count)
        average_pos /= natoms
        for i in 0..<Int(natoms) {
            self.atomlist[i].pos -= average_pos
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




