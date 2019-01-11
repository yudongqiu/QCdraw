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
                if let path = openpanel.url?.path {
                    var success = false
                    if (path as NSString).pathExtension == "dae" {
                        success = self.mySceneView.init_with_dae(url: openpanel.url)
                    }
                    else {
                        let input = file_parser(path: path)
                        if input.AtomList.count > 0 {
                            self.mySceneView.init_scene()
                            for eachatom in input.AtomList{
                                self.mySceneView.add_atom(thisatom: eachatom)
                            }
                            self.mySceneView.auto_add_bond()
                            self.mySceneView.adjust_focus()
                            success = true
                        }
                    }
                    if success {
                        self.info_bar.stringValue = "Left click to select atoms and click +Bond to add bond"
                    }
                    else {
                        self.info_bar.stringValue = "File not recognized"
                    }
                }
            }
        }
        // reset the VDW representation to CPK
        self.appdelegate.menu_vdw_representation.state = .off
    }
    
    @IBAction func rotate_molecule(sender: NSButton) {
        let windowController = NSApplication.shared.windows[0].windowController as! CustomWindowController
        if appdelegate.menu_rotate.state == .off {
            let animation = CABasicAnimation(keyPath: "rotation")
            let p_up = mySceneView.pointOfView!.convertVector(SCNVector3(0,1,0), to: nil)
            animation.fromValue = NSValue(scnVector4: SCNVector4(x: p_up.x, y: p_up.y, z: p_up.z, w: 0))
            animation.toValue = NSValue(scnVector4: SCNVector4(x: p_up.x, y: p_up.y, z: p_up.z, w: .pi*2))
            animation.duration = 10
            animation.repeatCount = .infinity //repeat forever
            mySceneView.moleculeNode.addAnimation(animation, forKey: "rot")
            appdelegate.menu_rotate.state = .on
            windowController.toolbar_rotate.image = NSImage(named: "rotating.png")
        }
        else {
            mySceneView.moleculeNode.removeAnimation(forKey: "rot", blendOutDuration: 2.0)
            appdelegate.menu_rotate.state = .off
            windowController.toolbar_rotate.image = NSImage(named: "rotate.png")
        }
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

