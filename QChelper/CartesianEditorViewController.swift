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
        let unit = unit_selection.selectedItem!.title.lowercased()
        let molecule = Molecule(text: textfield.string, unit: unit)
        self.view_controller.mySceneView.init_scene()
        self.view_controller.reset()
        for (idx, eachatom) in molecule.atomlist.enumerated() {
            self.view_controller.mySceneView.add_atom(thisatom: eachatom, index: idx)
        }
        self.view_controller.mySceneView.update_traj_length(length: 0)
        self.view_controller.mySceneView.auto_add_bond()
        self.view_controller.mySceneView.adjust_focus()
        self.view.window?.close()
    }
    
    @IBOutlet var textfield: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        textfield.font = NSFont(name: "Menlo", size: 12)
        struct AtomStr {
            var index: Int
            var content: String
        }
        var atomlist: [AtomStr] = []
        for eachatom in self.view_controller.mySceneView.normalatomnode.childNodes + self.view_controller.mySceneView.selectedatomnode.childNodes {
            let name = String(format: "%2s", (eachatom.name! as NSString).utf8String!)
            let posx = String(format: "%17.6f", eachatom.position.x)
            let posy = String(format: "%17.6f", eachatom.position.y)
            let posz = String(format: "%17.6f", eachatom.position.z)
            let index = eachatom.value(forUndefinedKey: "atom_index") as! Int
            atomlist.append(AtomStr(index: index, content: name + posx + posy + posz))
        }
        atomlist.sort { $0.index < $1.index }
        for a in atomlist {
            textfield.string += a.content + "\n"
        }
    }
    
    func select_all () {
        textfield.selectAll(self)
    }
    
}


