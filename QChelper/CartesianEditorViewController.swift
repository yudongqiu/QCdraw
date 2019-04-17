//
//  CartesianEditorViewController.swift
//  QCdraw
//
//  Created by Yudong Qiu on 10/12/15.
//  Copyright © 2015 QYD. All rights reserved.
//

import Cocoa

class CartesianEditorViewController: NSViewController {
    
    let view_controller = NSApplication.shared.windows[0].contentViewController as! ViewController

    @IBAction func cancel(sender: AnyObject) {
        self.view.window?.close()
    }
    @IBOutlet weak var unit_selection: NSPopUpButton!
    
    @IBAction func ok(sender: AnyObject) {
        var AtomList : [atom] = []
        let text_lines = textfield.string.components(separatedBy: "\n")
        let fileparser = file_parser(path: "")
        for line in text_lines {
            let inline = line.split()
            // if the line satisfy all conditions, continue
            if inline.count == 4 {
                if let posx = inline[1].doubleValue {
                    if let posy = inline[2].doubleValue {
                        if let posz = inline[3].doubleValue {
                            var new_atom = atom()
                            new_atom.name = inline[0] as NSString
                            let bohr_to_angstrom = 0.529177208
                            if unit_selection.selectedItem?.title == "Angstrom" {
                                new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                            }
                            else if unit_selection.selectedItem?.title == "Bohr" {
                                new_atom.pos = [CGFloat(posx*bohr_to_angstrom),CGFloat(posy*bohr_to_angstrom),CGFloat(posz*bohr_to_angstrom)]
                            }
                            new_atom.radius = fileparser.dict_atom_radius(name: new_atom.name)
                            new_atom.color = fileparser.dict_atom_color(name: new_atom.name)
                            AtomList.append(new_atom)
                            continue
                        }
                    }
                }
            }
            if inline.count == 5 {
                if let posx = inline[2].doubleValue {
                    if let posy = inline[3].doubleValue {
                        if let posz = inline[4].doubleValue {
                            var new_atom = atom()
                            if inline[0].doubleValue == nil {
                                new_atom.name = inline[0] as NSString
                            }
                            else if inline[1].doubleValue == nil {
                                new_atom.name = inline[1] as NSString
                            }
                            let bohr_to_angstrom = 0.529177208
                            if unit_selection.selectedItem?.title == "Angstrom" {
                                new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                            }
                            else if unit_selection.selectedItem?.title == "Bohr" {
                                new_atom.pos = [CGFloat(posx*bohr_to_angstrom),CGFloat(posy*bohr_to_angstrom),CGFloat(posz*bohr_to_angstrom)]
                            }
                            new_atom.radius = fileparser.dict_atom_radius(name: new_atom.name)
                            new_atom.color = fileparser.dict_atom_color(name: new_atom.name)
                            AtomList.append(new_atom)
                            continue
                        }
                    }
                }
            }
            if inline.count == 6 {
                if let posx = inline[3].doubleValue {
                    if let posy = inline[4].doubleValue {
                        if let posz = inline[5].doubleValue{
                            var new_atom = atom()
                            new_atom.name = inline[1] as NSString
                            let bohr_to_angstrom = 0.529177208
                            if unit_selection.selectedItem?.title == "Angstrom" {
                                new_atom.pos = [CGFloat(posx),CGFloat(posy),CGFloat(posz)]
                            }
                            else if unit_selection.selectedItem?.title == "Bohr" {
                                new_atom.pos = [CGFloat(posx*bohr_to_angstrom),CGFloat(posy*bohr_to_angstrom),CGFloat(posz*bohr_to_angstrom)]
                            }
                            new_atom.radius = fileparser.dict_atom_radius(name: new_atom.name)
                            new_atom.color = fileparser.dict_atom_color(name: new_atom.name)
                            AtomList.append(new_atom)
                            continue
                        }
                    }
                }
            }
        }
        if AtomList.count > 0 {
            self.view_controller.mySceneView.init_scene()
            for (idx, eachatom) in AtomList.enumerated() {
                self.view_controller.mySceneView.add_atom(thisatom: eachatom, index: idx)
            }
            self.view_controller.mySceneView.auto_add_bond()
            self.view_controller.mySceneView.adjust_focus()
        }
        self.view.window?.close()
    }
    
    @IBOutlet var textfield: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        textfield.font = NSFont(name: "Menlo", size: 12)
        for eachatom in self.view_controller.mySceneView.normalatomnode.childNodes + self.view_controller.mySceneView.selectedatomnode.childNodes {
            let name = String(format: "%2s", (eachatom.name! as NSString).utf8String!)
            let posx = String(format: "%17.6f", eachatom.position.x)
            let posy = String(format: "%17.6f", eachatom.position.y)
            let posz = String(format: "%17.6f", eachatom.position.z)
            textfield.string += name + posx + posy + posz + "\n"
        }
    }
}


