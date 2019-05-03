//
//  ViewController.swift
//  QChelper
//
//  Created by Yudong Qiu on 7/10/15.
//  Copyright (c) 2015 Bruce. All rights reserved.
//

import Foundation
import SceneKit

class ViewController: NSViewController {

    @IBOutlet weak var mySceneView: MySceneView!
    @IBOutlet weak var info_bar: NSTextField!
    @IBOutlet weak var slider: NSSliderCell!
    @IBOutlet weak var toolbox: NSBox!
    @IBOutlet weak var slider_text: NSTextField!
    @IBOutlet weak var play_button: NSButton!
    @IBOutlet weak var speed_slider: NSSlider!
    @IBOutlet weak var progress_box: NSBox!
    @IBOutlet weak var progress_indicator: NSProgressIndicator!
    @IBOutlet weak var progress_label: NSTextField!
    
    let appdelegate = NSApplication.shared.delegate as! AppDelegate
    var timer = Timer() // for play traj
    var to_show_progress = false // for delayed showing of progress bar
    // create a blur filter for progress box
    let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: 3])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // set background to transparent
        mySceneView.backgroundColor = NSColor.clear
        info_bar.stringValue = "Click Open or drag in file"
        mySceneView.registerForDraggedTypes([.fileURL])
        // create a blur filter for progress box
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
    
    @IBAction func save_snapshot(sender: NSButton) {
        // deselect all selected items before taking snapshot
        self.mySceneView.reset_selection()
        // save panel
        let newsavepanel = NSSavePanel()
        newsavepanel.title = "Save Graphic"
        let filetypes : [String] = ["png","PNG","pdf","PDF"]
        newsavepanel.allowedFileTypes = filetypes
        newsavepanel.begin {(result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = newsavepanel.url {
                    // Set double resolution if desired
                    let oldsize = self.mySceneView.bounds.size // restore original size
                    if self.appdelegate.menu_high_reso.state == .on {
                        let newsize = NSMakeSize(oldsize.width*2,oldsize.height*2)
                        self.mySceneView.setBoundsSize(newsize)
                    }
                    if !self.mySceneView.save_file(url: url) {
                        self.info_bar.stringValue = "Error saving " + url.path
                    }
                    // Set resolution back
                    self.mySceneView.setBoundsSize(oldsize)
                }
            }
        }
    }
    
    @IBAction func save_trajectory_snapshot(sender: NSButton) {
        // deselect all selected items before taking snapshot
        self.mySceneView.reset_selection()
        self.reset()
        // save panel
        let newsavepanel = NSSavePanel()
        newsavepanel.title = "Save Graphic for Trajectory"
        newsavepanel.begin {(result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = newsavepanel.url {
                    do {
                        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        self.info_bar.stringValue = "Failed to create folder " + url.path
                    }
                    let digits = max(Int(log10(Double(self.mySceneView.traj_length))), 2)
                    let fmt_str = "frame-%0" + String(digits) + "d.png"
                    DispatchQueue.global(qos: .utility).async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        for i_frame in 0 ..< self.mySceneView.traj_length {
                            DispatchQueue.main.sync {
                                self.show_progress(nFinished: i_frame, total: self.mySceneView.traj_length, title: "Saving Images")
                                self.mySceneView.choose_frame(frame: i_frame)
                            }
                            let frame_url = url.appendingPathComponent(String(format: fmt_str, i_frame))
                            if !self.mySceneView.save_file(url: frame_url) {
                                DispatchQueue.main.sync {
                                    self.info_bar.stringValue = "Error saving " + url.path
                                }
                                break
                            }
                        }
                        DispatchQueue.main.sync {
                            self.hide_progress()
                        }
                    }
                }
            }
        }
        
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
    
    @IBAction func export_trajectory_json(sender: AnyObject?) {
        // save panel
        let newsavepanel = NSSavePanel()
        newsavepanel.title = "Export Json File"
        newsavepanel.begin {(result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = newsavepanel.url {
                    do {
                        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        self.info_bar.stringValue = "Failed to create folder " + url.path
                        return
                    }
                    let digits = max(Int(log10(Double(self.mySceneView.traj_length))), 2)
                    let fmt_str = "frame-%0" + String(digits) + "d.json"
                    for i_frame in 0 ..< self.mySceneView.traj_length {
                        self.mySceneView.choose_frame(frame: i_frame)
                        let frame_url = url.appendingPathComponent(String(format: fmt_str, i_frame))
                        if !self.mySceneView.export_json_tungsten(fileurl: frame_url) {
                            self.info_bar.stringValue = "Failed to export json at " + frame_url.path
                        }
                    }
                }
            }
        }
    }
    
    func show_progress(nFinished: Int, total: Int, title: String = "Progress", delay: TimeInterval = 0.0) {
        if delay == 0.0 {
            // run without async
            if self.progress_box.isHidden {
                self.progress_box.isHidden = false
                if let blur_filter = self.blurFilter {
                    self.progress_box.backgroundFilters = [blur_filter]
                }
            }
            self.progress_indicator.doubleValue = Double(nFinished) / Double(total) * 100
            self.progress_label.stringValue = "\(nFinished) / \(total)"
            self.progress_box.title = title
        } else if delay > 0 {
            // run with async to delay the showing
            self.to_show_progress = true
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else {
                    return
                }
                // only run if we still want to show progress after the delay
                if self.to_show_progress {
                    if self.progress_box.isHidden {
                        self.progress_box.isHidden = false
                        if let blur_filter = self.blurFilter {
                            self.progress_box.backgroundFilters = [blur_filter]
                        }
                    }
                    self.progress_indicator.doubleValue = Double(nFinished) / Double(total) * 100
                    self.progress_label.stringValue = "\(nFinished) / \(total)"
                    self.progress_box.title = title
                }
            }
        }
    }
    
    func hide_progress() {
        self.to_show_progress = false // this cancel the delayed showing
        self.progress_box.isHidden = true
        self.progress_box.backgroundFilters = []
        self.progress_box.alphaValue = 1.0
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

    func select_all() {
        mySceneView.select_all()
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
    
    @IBAction func reset_bonds(sender: AnyObject?) {
        self.mySceneView.reset_bond_nodes()
    }
    
    
    @IBAction func cast_shadows(sender: AnyObject?) {
        let windowController = NSApplication.shared.windows[0].windowController as! CustomWindowController
        if self.appdelegate.menu_cast_shadow.state == .off {
            self.appdelegate.menu_cast_shadow.state = .on
            windowController.toolbar_shadow.image = NSImage(named: "atomShadowOn.png")
            if let light = self.mySceneView.lightNode.light {
                light.castsShadow = true
            }
        }
        else {
            self.appdelegate.menu_cast_shadow.state = .off
            windowController.toolbar_shadow.image = NSImage(named: "atomShadowOff.png")
            if let light = self.mySceneView.lightNode.light {
                light.castsShadow = false
            }
        }
    }
    
    @IBAction func move_slider(_ sender: NSSlider) {
        self.mySceneView.choose_frame(frame: sender.integerValue)
    }
    
    @IBAction func set_slider(_ sender: NSTextField) {
        self.mySceneView.choose_frame(frame: sender.integerValue)
    }
    
    @IBAction func toggle_play_traj(_ sender: NSButton) {
        self.timer.invalidate()
        if sender.state == .on {
            if self.mySceneView.traj_length > 1 {
                // limit the max speed to one loop per second
                let frame_per_second = min(pow(2.0, speed_slider.doubleValue), Double(self.mySceneView.traj_length))
                let time_interval = 1.0 / frame_per_second
                self.timer = Timer.scheduledTimer(timeInterval: time_interval, target: self, selector: #selector(fire_timer), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc func fire_timer() {
        self.mySceneView.next_frame()
    }
    
    @IBAction func set_speed_slider(_ sender: NSSlider) {
        if play_button.state == .on {
            if self.mySceneView.traj_length > 1 {
                self.timer.invalidate()
                let frame_per_second = min(pow(2.0, speed_slider.doubleValue), Double(self.mySceneView.traj_length))
                let time_interval = 1.0 / frame_per_second
                self.timer = Timer.scheduledTimer(timeInterval: time_interval, target: self, selector: #selector(fire_timer), userInfo: nil, repeats: true)
            }
        }
    }
    
    func reset() {
        self.timer.invalidate()
        self.play_button.state = .off
        self.slider.integerValue = 0
        self.slider_text.integerValue = 0
    }
    
}

