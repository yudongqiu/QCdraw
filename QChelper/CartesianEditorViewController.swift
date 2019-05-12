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
        self.view_controller.mySceneView.load_from_text(text: textfield.string, unit: unit)
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
        var xyz_str = ""
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
            xyz_str += a.content + "\n"
        }
        textfield.string = xyz_str
    }
    
}


