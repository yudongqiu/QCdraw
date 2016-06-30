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
    let appdelegate = NSApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // set background to transparent
        mySceneView.backgroundColor = NSColor.clearColor()
        info_bar.stringValue = "Click Open or drag in file"
        mySceneView.registerForDraggedTypes([NSFilenamesPboardType])

    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func save_snapshot(sender: NSButton) {
        // deselect all selected items before taking snapshot
        self.mySceneView.reset_selection()
        // Set double resolution if desired
        let oldsize = self.mySceneView.frame.size // restore original size
        if self.appdelegate.menu_high_reso.state == NSOnState {
            let newsize = NSMakeSize(oldsize.width*2,oldsize.height*2)
            //self.mySceneView.setFrameSize(newsize)
            self.mySceneView.frame.size = newsize
        }
        // save panel
        let newsavepanel = NSSavePanel()
        newsavepanel.title = "Save Graphic"
        let filetypes : [String] = ["png","PNG","pdf","PDF"]
        newsavepanel.allowedFileTypes = filetypes
        newsavepanel.beginWithCompletionHandler {(result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let path = newsavepanel.URL?.path {
                    if self.mySceneView.save_file(path) {
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
        openpanel.beginWithCompletionHandler {(result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let path = openpanel.URL?.path {
                    var success = false
                    if (path as NSString).pathExtension == "dae" {
                        success = self.mySceneView.init_with_dae(openpanel.URL)
                    }
                    else {
                        let input = file_parser(path: path)
                        if input.AtomList.count > 0 {
                            self.mySceneView.init_scene()
                            for eachatom in input.AtomList{
                                self.mySceneView.add_atom(eachatom)
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
    }
    
    @IBAction func rotate_molecule(sender: NSButton) {
        let windowController = NSApplication.sharedApplication().windows[0].windowController as! CustomWindowController
        if mySceneView.moleculeNode.animationForKey("rot") == nil {
            // setup rotate animation
            let animation = CABasicAnimation(keyPath: "rotation")
            animation.toValue = NSValue(SCNVector4: SCNVector4(x: CGFloat(0), y: CGFloat(1), z: CGFloat(0), w: CGFloat(M_PI)*2))
            animation.duration = 9
            animation.repeatCount = MAXFLOAT //repeat forever
            mySceneView.moleculeNode.addAnimation(animation, forKey: "rot")
            appdelegate.menu_rotate.state = NSOnState
            windowController.toolbar_rotate.image = NSImage(named: "rotating.png")
        }
        else {
            if appdelegate.menu_rotate.state == NSOffState {
                mySceneView.moleculeNode.resumeAnimationForKey("rot")
                appdelegate.menu_rotate.state = NSOnState
                windowController.toolbar_rotate.image = NSImage(named: "rotating.png")
            }
            else if appdelegate.menu_rotate.state == NSOnState {
                mySceneView.moleculeNode.pauseAnimationForKey("rot")
                appdelegate.menu_rotate.state = NSOffState
                windowController.toolbar_rotate.image = NSImage(named: "rotate.png")

            }
        }
    }
    
    @IBAction func add_bond(sender: NSButton) {
        mySceneView.add_bond()
        mySceneView.reset_selection()
    }
    
    @IBAction func remove_selected_node(sender: NSButton) {
        for eachnode in mySceneView.selectedatomnode.childNodes + mySceneView.selectedbondnode.childNodes {
            mySceneView.remove_node(eachnode)
        }
    }
    
    @IBAction override func selectAll(sender: AnyObject?) {
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
        newsavepanel.beginWithCompletionHandler {(result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let url = newsavepanel.URL {
                    self.mySceneView.export_scene(url)
                }
            }
        }
    }
    
    @IBAction func change_texture_none(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture("none")
    }
    
    @IBAction func change_texture_metal(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture("metal")
    }
    
    @IBAction func change_texture_marble(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture("marble")
    }
    
    @IBAction func change_texture_wood(sender: AnyObject?) {
        self.mySceneView.reset_selection()
        self.mySceneView.change_texture("wood")
    }
    
    @IBAction func transparentize(sender: AnyObject?) {
        for eachnode in mySceneView.selectedatomnode.childNodes + mySceneView.selectedbondnode.childNodes {
            mySceneView.make_transparent(eachnode)
        }
    }

    


}

