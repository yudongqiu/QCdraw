//
//  ViewController.swift
//  QChelper
//
//  Created by Yudong Qiu on 7/10/15.
//  Copyright (c) 2015 Bruce. All rights reserved.
//

import Cocoa
import SceneKit

class ViewController: NSViewController {

    @IBOutlet weak var mySceneView: MySceneView!
    @IBOutlet weak var info_bar: NSTextField!
    let appdelegate = NSApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // set background to transparent
        mySceneView.backgroundColor = NSColor.clear
        info_bar.stringValue = "Click Open or drag in file"
        mySceneView.registerForDraggedTypes([.fileURL])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func save_snapshot(sender: NSButton) {
        // deselect all selected items before taking snapshot
        self.mySceneView.reset_selection()
        // Set double resolution if desired
        let oldsize = self.mySceneView.frame.size // restore original size
        if self.appdelegate.menu_high_reso.state == .on {
            let newsize = NSMakeSize(oldsize.width*2,oldsize.height*2)
            self.mySceneView.frame.size = newsize
        }
        // save panel
        let newsavepanel = NSSavePanel()
        newsavepanel.title = "Save Graphic"
        let filetypes : [String] = ["png","PNG","pdf","PDF"]
        newsavepanel.allowedFileTypes = filetypes
        newsavepanel.begin {(result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = newsavepanel.url {
                    if self.mySceneView.save_file(url: url) {
                        // Set resolution back
                        self.mySceneView.frame.size = oldsize
                    }
                }
            }
        }
    }
    
    @IBAction func open_file(sender: AnyObject) {
        let openpanel = NSOpenPanel()
        openpanel.title = "Open File"
        openpanel.begin {(result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                self.mySceneView.open_file(url: openpanel.url)
            }
        }
        // reset the VDW representation to CPK
        self.appdelegate.menu_vdw_representation.state = .off
    }
    
    @IBAction func rotate_molecule(sender: NSButton) {
        let windowController = NSApplication.shared.windows[0].windowController as! CustomWindowController
        if appdelegate.menu_rotate.state == .off {
            appdelegate.menu_rotate.state = .on
            windowController.toolbar_rotate.image = NSImage(named: "rotating.png")
        }
        else {
            appdelegate.menu_rotate.state = .off
            windowController.toolbar_rotate.image = NSImage(named: "rotate.png")
        }
        mySceneView.toggleRotateAnimation()
    }
    
    @IBAction func add_bond(sender: NSButton) {
        mySceneView.add_bond()
        mySceneView.reset_selection()
    }
    
    @IBAction func remove_selected_node(sender: NSButton) {
        for eachnode in mySceneView.selectedatomnode.childNodes + mySceneView.selectedbondnode.childNodes {
            mySceneView.remove_node(thisnode: eachnode)
        }
    }

    @IBAction func selectAll(sender: AnyObject?) {
        mySceneView.select_all()
    }
    
    @IBAction func export_dae(sender: AnyObject?) {
        // deselect all selected items before taking snapshot
        self.mySceneView.reset_selection()
        // save panel
        let newsavepanel = NSSavePanel()
        newsavepanel.title = "Save 3D File"
        let filetypes : [String] = ["dae"]
        newsavepanel.allowedFileTypes = filetypes
        newsavepanel.begin {(result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = newsavepanel.url {
                    if !self.mySceneView.export_scene(fileurl: url) {
                        self.info_bar.stringValue = "Failed to export dae file"
                    }
                }
            }
        }
    }
    
    @IBAction func export_json(sender: AnyObject?) {
        // save panel
        let newsavepanel = NSSavePanel()
        newsavepanel.title = "Export Json File"
        let filetypes : [String] = ["json"]
        newsavepanel.allowedFileTypes = filetypes
        newsavepanel.begin {(result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = newsavepanel.url {
                    if !self.mySceneView.export_json_tungsten(fileurl: url) {
                        self.info_bar.stringValue = "Failed to export json"
                    }
                }
            }
        }
    }
    
    @IBAction func change_texture_none(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture(texture: "none")
    }
    
    @IBAction func change_texture_metal(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture(texture: "metal")
    }
    
    @IBAction func change_texture_marble(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture(texture: "marble")
    }
    
    @IBAction func change_texture_wood(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture(texture: "wood")
    }
    
    @IBAction func transparentize(sender: AnyObject?) {
        for eachnode in mySceneView.selectedatomnode.childNodes + mySceneView.selectedbondnode.childNodes {
            if eachnode.opacity == 1.0 {
                mySceneView.make_transparent(thisnode: eachnode)
            }
            else{
                mySceneView.reset_transparent(thisnode: eachnode)
            }
        }
    }
    
    @IBAction func switch_VdW_representation(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        if self.appdelegate.menu_vdw_representation.state == .on {
            self.appdelegate.menu_vdw_representation.state = .off
            self.mySceneView.change_to_cpk()
        }
        else {
            self.appdelegate.menu_vdw_representation.state = .on
            self.mySceneView.change_to_vdw()
        }
    }
    
    @IBAction func view_recenter(sender: AnyObject?) {
        self.mySceneView.recenter()
    }
    
    
    @IBAction func cast_shadows(sender: AnyObject?) {
        if let light = self.mySceneView.lightNode.light {
            if self.appdelegate.menu_cast_shadow.state == .off {
                light.castsShadow = true
                self.appdelegate.menu_cast_shadow.state = .on
            }
            else {
                self.appdelegate.menu_cast_shadow.state = .off
                light.castsShadow = false
            }
        }
    }
    
}

