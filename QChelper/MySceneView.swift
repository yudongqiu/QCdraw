//
//  MySceneView.swift
//  QChelper
//
//  Created by Yudong Qiu on 7/10/15.
//  Copyright (c) 2015 QYD. All rights reserved.
//

import SceneKit
//import Foundation

class MySceneView: SCNView {

    var moleculeNode = SCNNode()
    var atomnodes = SCNNode()
    var normalatomnode = SCNNode()
    var selectedatomnode = SCNNode()
    var bondnodes = SCNNode()
    var normalbondnode = SCNNode()
    var selectedbondnode = SCNNode()
    
    var cameraNode = SCNNode()
    var lightNode = SCNNode()
    
    func init_scene() -> Bool {
        //clean old nodes
        self.moleculeNode = SCNNode()
        self.atomnodes = SCNNode()
        self.normalatomnode = SCNNode()
        self.selectedatomnode = SCNNode()
        self.bondnodes = SCNNode()
        self.normalbondnode = SCNNode()
        self.selectedbondnode = SCNNode()
        
        self.cameraNode = SCNNode()
        self.lightNode = SCNNode()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        self.cameraNode.name = "camera"
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera?.yFov = 37
        self.cameraNode.camera?.zNear = 0.5
        self.cameraNode.camera?.zFar = 1000
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        scene.rootNode.addChildNode(cameraNode)
        
//        // create and add a light to the scene  
        self.lightNode.light = SCNLight()
        self.lightNode.light!.type = SCNLightTypeDirectional
        self.lightNode.rotation = SCNVector4Make(1, 1, 0, -0.7)
        self.cameraNode.addChildNode(lightNode)
        
        
        // add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "ambientlght"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = NSColor(deviceWhite: 0.15, alpha: 1)
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        // setup nodes hierarchy
        scene.rootNode.addChildNode(self.moleculeNode)
        self.moleculeNode.addChildNode(self.atomnodes)
        self.moleculeNode.addChildNode(self.bondnodes)
        self.atomnodes.addChildNode(self.normalatomnode)
        self.atomnodes.addChildNode(self.selectedatomnode)
        self.bondnodes.addChildNode(self.normalbondnode)
        self.bondnodes.addChildNode(self.selectedbondnode)
        
        // try selected animation
//        let selected_animation = CABasicAnimation(keyPath: "transform")
//        let fromtrans = CATransform3DMakeScale(1.1, 1.1, 1.1)
//        let totrans = CATransform3DMakeScale(0.9, 0.9, 0.9)
//        selected_animation.fromValue = NSValue(CATransform3D: fromtrans)
//        selected_animation.toValue = NSValue(CATransform3D: totrans)
//        selected_animation.duration = 0.5
//        selected_animation.autoreverses = true
//        selected_animation.repeatCount = MAXFLOAT
//        selectednode.addAnimation(selected_animation, forKey: "select")
        
        self.scene = scene
        
        // reset the rotate button
        let windowController = NSApplication.sharedApplication().windows[0].windowController as! CustomWindowController
        let appdelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appdelegate.menu_rotate.state = NSOffState
        windowController.toolbar_rotate.image = NSImage(named: "rotate.png")
        
        return true
    }
    
    func add_atom(thisatom: atom) -> Void {
        // draw a sphere
        let sphereGeometry = SCNSphere(radius: thisatom.radius)
        sphereGeometry.geodesic = true
        sphereGeometry.segmentCount = 200
        let color = NSColor(deviceRed: thisatom.color[0], green: thisatom.color[1], blue: thisatom.color[2], alpha: 1)
//        sphereGeometry.firstMaterial?.diffuse.contents = color
        sphereGeometry.firstMaterial?.multiply.contents = color
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.name = thisatom.name as String
//        let position = SCNVector3Make(thisatom.pos[1], thisatom.pos[2], thisatom.pos[3])
        sphereNode.position = SCNVector3(x: thisatom.pos[0], y: thisatom.pos[1], z: thisatom.pos[2])
        self.normalatomnode.addChildNode(sphereNode)
    }
    
    
    func add_bond() -> Void {
        // get bond thickness and color from Elements.plist
        let bond_thickness = dict_bond_thickness()
        let bond_color : NSColor = dict_bond_color()
        // add bond between every pair of atoms in selected atomnodes
        for var i = 0; i<self.selectedatomnode.childNodes.count; ++i {
            for var j = i+1; j<self.selectedatomnode.childNodes.count; ++j {
                let point_a = self.selectedatomnode.childNodes[i].position
                let point_b = self.selectedatomnode.childNodes[j].position
                // draw a cylinder
                let length = CGdistance(point_a, b: point_b)
                let bondGeometry = SCNCylinder(radius: bond_thickness, height: length)
                bondGeometry.firstMaterial?.multiply.contents = bond_color
                let bondNode = SCNNode(geometry: bondGeometry)
                let dx = point_b.x - point_a.x
                let dy = point_b.y - point_a.y
                let dz = point_b.z - point_a.z
                // the rotation axis (0,1,0)*(dx, dy, dz) = (dz, 0, dx)
                // the rotation angle θ = arccos( (0,1,0).(dx, dy, dz)/|(dx, dy, dz)|)
                bondNode.rotation = SCNVector4Make(dz, 0 , -dx, acos(dy/length))
                bondNode.position = SCNVector3Make(0.5*(point_a.x+point_b.x), 0.5*(point_a.y+point_b.y), 0.5*(point_a.z+point_b.z))
                // check if the bondNode already exists
                var exist = false
                for eachnode in self.normalbondnode.childNodes + self.selectedbondnode.childNodes {
                    if SCNVector3EqualToVector3(bondNode.position,eachnode.position) && SCNVector4EqualToVector4(bondNode.rotation,eachnode.rotation) {
                        exist = true
                    }
                }
                if exist == false {
                    add_bond_node(bondNode)
                }
            }
        }
    }
    
    func CGdistance(a: SCNVector3, b: SCNVector3) -> CGFloat {
        let sum = (a.x - b.x)*(a.x - b.x) + (a.y - b.y)*(a.y - b.y) + (a.z - b.z)*(a.z - b.z)
        return sqrt(sum)
    }

    
    func remove_node(thisnode: SCNNode) {
        if (self.normalatomnode.childNodes + self.selectedatomnode.childNodes).contains(thisnode) {
            undoManager?.registerUndoWithTarget(self, selector: Selector("add_atom_node:"), object: thisnode)
        }
        else if (self.normalbondnode.childNodes + self.selectedbondnode.childNodes).contains(thisnode) {
            undoManager?.registerUndoWithTarget(self, selector: Selector("add_bond_node:"), object: thisnode)
        }
        thisnode.geometry?.firstMaterial?.diffuse.intensity = 1
        thisnode.removeFromParentNode()
        // reset info bar
        let view_controller = NSApplication.sharedApplication().windows[0].contentViewController as! ViewController
        view_controller.info_bar.stringValue = ""
    }
    
    func add_atom_node(thisnode: SCNNode) {
        undoManager?.registerUndoWithTarget(self, selector: Selector("remove_node:"), object: thisnode)
        self.normalatomnode.addChildNode(thisnode)
    }
    
    func add_bond_node(thisnode: SCNNode) {
        undoManager?.registerUndoWithTarget(self, selector: Selector("remove_node:"), object: thisnode)
        self.normalbondnode.addChildNode(thisnode)
    }
    
    
    
    func save_file(filepath: String) -> Bool {
        var success = false
        if (filepath as NSString).pathExtension == "pdf" {
            let myView = NSImageView(frame: self.bounds)
            myView.image = self.snapshot()
            let pdfdata = myView.dataWithPDFInsideRect(self.bounds)
            success = pdfdata.writeToFile(filepath, atomically: true)
        }
        else if (filepath as NSString).pathExtension == "png" {
            let pngdata = NSBitmapImageRep(data: self.snapshot().TIFFRepresentation!)!.representationUsingType(.NSPNGFileType, properties: [:])!
            success = pngdata.writeToFile(filepath, atomically: true)
        }
        return success
    }
    
    func export_scene(fileurl: NSURL) -> Bool {
        var success = false
        if let scene = self.scene {
            // remove lightNode to reset default light
            self.lightNode.removeFromParentNode()
            // save scene to .dae file
            success = scene.writeToURL(fileurl, options: nil, delegate: nil, progressHandler: nil)
            // add lightNode back
            self.cameraNode.addChildNode(lightNode)
        }
        return success
    }
    
    
    override func mouseDown(theEvent: NSEvent) {
        let hitResults = hitTest(theEvent.locationInWindow, options: nil)
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let hitnode = hitResults[0].node
            let material = hitnode.geometry!.firstMaterial!
            if self.normalatomnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                material.diffuse.intensity = 0.5
                self.selectedatomnode.addChildNode(hitnode)
            }
            else if self.selectedatomnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                material.diffuse.intensity = 1
                self.normalatomnode.addChildNode(hitnode)
            }
            else if self.normalbondnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                material.diffuse.intensity = 0.5
                self.selectedbondnode.addChildNode(hitnode)
            }
            else if self.selectedbondnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                material.diffuse.intensity = 1
                self.normalbondnode.addChildNode(hitnode)
            }
            
        }
        super.mouseDown(theEvent)
    }
    
    
    
    // mouse drag to rotate the molecule
//    override func mouseDragged(theEvent: NSEvent) {
//        let point = theEvent.locationInWindow
//        let dx = point.x - click_location.x
//        let dy = point.y - click_location.y
//        
//        let rotX = CATransform3DMakeRotation(dy * 0.003, -1, 0, 0);
//        let rotY = CATransform3DMakeRotation(dx * 0.003, 0, 1, 0);
//        let rotation = CATransform3DConcat(rotY, rotX);
//        moleculeNode.transform = CATransform3DConcat(initialTransform, rotation)
//    }
    
    override func mouseDragged(theEvent: NSEvent) {
        // set lightnode as childnode of cameranode, and set cameranode to follow the pointofview
        if let current_transform = self.pointOfView?.transform {
            self.cameraNode.transform = current_transform
        }
        super.mouseDragged(theEvent)
    }
    
    
    override func mouseUp(theEvent: NSEvent) {
        // print info bar
        let view_controller = NSApplication.sharedApplication().windows[0].contentViewController as! ViewController
        // print atom name (only one)
        if self.selectedatomnode.childNodes.count == 1 && self.selectedbondnode.childNodes.count == 0 {
            view_controller.info_bar.stringValue = "Atom : " + self.selectedatomnode.childNodes[0].name!
        }
        // print bond length (only one)
        else if self.selectedbondnode.childNodes.count == 1 && self.selectedatomnode.childNodes.count == 0 {
            let geometry = self.selectedbondnode.childNodes[0].geometry as! SCNCylinder
            view_controller.info_bar.stringValue = "R = " + geometry.height.description + " \u{212B}"
        }
        // print bond angles (if two connected bonds are selected)
        else if self.selectedbondnode.childNodes.count == 2 {
            let bond_a = self.selectedbondnode.childNodes[0]
            let bond_b = self.selectedbondnode.childNodes[1]
            // compute the starting and ending point of the bonds
            let a_start = compute_bond_ends(bond_a)[0]
            let a_end = compute_bond_ends(bond_a)[1]
            let a_vector : float3 = [Float(a_start.x-a_end.x),Float(a_start.y-a_end.y),Float(a_start.z-a_end.z)]
            let b_start = compute_bond_ends(bond_b)[0]
            let b_end = compute_bond_ends(bond_b)[1]
            let b_vector : float3 = [Float(b_start.x-b_end.x),Float(b_start.y-b_end.y),Float(b_start.z-b_end.z)]
            let a_length = (bond_a.geometry as! SCNCylinder).height
            let b_length = (bond_b.geometry as! SCNCylinder).height
            let theta = acos(dot(a_vector,b_vector)/Float(a_length * b_length)) / Float(M_PI) * 180.0
            if check_same_point(a_start, point2: b_start) || check_same_point(a_end, point2: b_end) {
                view_controller.info_bar.stringValue = "\u{03F4} = " + theta.description + "\u{00B0}"
            }
            else if check_same_point(a_start, point2: b_end) || check_same_point(a_end, point2: b_start) {
                view_controller.info_bar.stringValue = "\u{03F4} = " + (180.0-theta).description + "\u{00B0}"
            }
            else {
                view_controller.info_bar.stringValue = "Right click to deselect all"
            }
        }
        // print dihedral angle ( if three connected bonds are selected)
        else if self.selectedbondnode.childNodes.count == 3 {
            // put the nodes ends into an array
            var bond_ends : [[SCNVector3]] = []
            for thisbond in self.selectedbondnode.childNodes {
                bond_ends.append(compute_bond_ends(thisbond))
            }
            // find out the connection between bonds
            var mid = -1
            for i in 0...2 { // find out the center bond first
                var same_start = false
                var same_end = false
                let i_start = bond_ends[i][0]
                let i_end = bond_ends[i][1]
                for j in 0...2 {
                    if j != i {
                        for end_j in bond_ends[j] {
                            if check_same_point(i_start, point2: end_j) { same_start = true }
                            if check_same_point(i_end, point2: end_j) { same_end = true }
                        }
                    }
                }
                if same_start && same_end {
                    mid = i
                }
            }
            // if center bond found, setup the correct point in order 1--4
            if mid >= 0 {
                var point1 = SCNVector3()
                var point2 = SCNVector3()
                var point3 = SCNVector3()
                var point4 = SCNVector3()
                // set the center bond as 2 and 3 first
                point2 = bond_ends[mid][0]
                point3 = bond_ends[mid][1]
                // find point1 and point4
                for i in 0...2 {
                    if i != mid {
                        for start_or_end in 0...1 {
                            // point1 is connected to point2
                            if check_same_point(bond_ends[i][start_or_end], point2: point2) {
                                point1 = bond_ends[i][1 - start_or_end]
                            }
                            // point4 is connected to point3
                            if check_same_point(bond_ends[i][start_or_end], point2: point3) {
                                point4 = bond_ends[i][1 - start_or_end]
                            }
                        }
                    }
                }
                // compute the dihedral angel between point 1 -- 4
                let a_vector : float3 = [Float(point1.x - point2.x),Float(point1.y - point2.y),Float(point1.z - point2.z)]
                let b_vector : float3 = [Float(point2.x - point3.x),Float(point2.y - point3.y),Float(point2.z - point3.z)]
                let c_vector : float3 = [Float(point3.x - point4.x),Float(point3.y - point4.y),Float(point3.z - point4.z)]
                let Uab = cross(a_vector, b_vector)
                let Ubc = cross(b_vector, c_vector)
                let gamma = acos(dot(Uab,Ubc)/(length(Uab)*length(Ubc))) / Float(M_PI) * 180.0
                view_controller.info_bar.stringValue = "\u{0393} = " + gamma.description + "\u{00B0}"
            } // end of print dihedral
            else {
                view_controller.info_bar.stringValue = "Right click to deselect all"
            }
        }
        else if self.selectedatomnode.childNodes.count + self.selectedbondnode.childNodes.count > 1 {
            view_controller.info_bar.stringValue = "Right click to deselect all"
        }
        else {
            view_controller.info_bar.stringValue = ""
        }
        super.mouseUp(theEvent)
    }
    
    func compute_bond_ends(bondnode : SCNNode) -> [SCNVector3] {
        var result : [SCNVector3] = []
        
        // read cylinder infomation from bondnode
        let center = bondnode.position
        let x = bondnode.rotation.x
        let z = bondnode.rotation.z
        let w = bondnode.rotation.w
        
        // get the half vector length
        let cylinder = bondnode.geometry as! SCNCylinder
        let r = cylinder.height * 0.5

        // start compute bond vector
        // explaination: the half bond vector bv was rotated from (0,1,0), along (x,0,z) axis by w angle
        // bv project on y axis = r * cos(w)
        // bv project on the xz plain has length r * sin(w)
        // bv project on xz plain has angle of (x,0,z) axis rotated by 90 degree clockwise ->  (-z,x)
        var starting_point = SCNVector3()
        starting_point.x = center.x + r * sin(w) * (-z / sqrt(z*z+x*x))
        starting_point.y = center.y + r * cos(w)
        starting_point.z = center.z + r * sin(w) * (x / sqrt(z*z+x*x))
        var ending_point = SCNVector3()
        ending_point.x = center.x - r * sin(w) * (-z / sqrt(z*z+x*x))
        ending_point.y = center.y - r * cos(w)
        ending_point.z = center.z - r * sin(w) * (x / sqrt(z*z+x*x))
        
        result.append(starting_point)
        result.append(ending_point)
        return result
    }
    
    func check_same_point(point1: SCNVector3, point2: SCNVector3) -> Bool {
        let tolerance : CGFloat = 0.000001
        var result : Bool
        if abs(point1.x - point2.x) + abs(point1.y - point2.y) + abs(point1.z - point2.z) < tolerance {
            result = true
        }
        else {
            result = false
        }
        return result
    }
    
    override func rightMouseDown(theEvent: NSEvent) {
        // record the click location for drag        
        reset_selection()
        super.rightMouseDown(theEvent)
    }
    
    override func rightMouseDragged(theEvent: NSEvent) {
        // allows rightmouse drag the view
        super.scrollWheel(theEvent)
    }

    
    func reset_selection() {
        for eachnode in self.selectedatomnode.childNodes {
            eachnode.removeFromParentNode()
            eachnode.geometry!.firstMaterial!.diffuse.intensity = 1
            self.normalatomnode.addChildNode(eachnode)
        }
        for eachnode in self.selectedbondnode.childNodes {
            eachnode.removeFromParentNode()
            eachnode.geometry!.firstMaterial!.diffuse.intensity = 1
            self.normalbondnode.addChildNode(eachnode)
        }
        let view_controller = NSApplication.sharedApplication().windows[0].contentViewController as! ViewController
        view_controller.info_bar.stringValue = ""
    }
    
    func select_all() {
        for eachnode in self.normalatomnode.childNodes {
            eachnode.removeFromParentNode()
            eachnode.geometry!.firstMaterial!.diffuse.intensity = 0.5
            self.selectedatomnode.addChildNode(eachnode)
        }
        for eachnode in self.normalbondnode.childNodes {
            eachnode.removeFromParentNode()
            eachnode.geometry!.firstMaterial!.diffuse.intensity = 0.5
            self.selectedbondnode.addChildNode(eachnode)
        }
    }
    
    func auto_add_bond() {
        // get bond thickness and color from Elements.plist
        let bond_thickness = dict_bond_thickness()
        let bond_color : NSColor = dict_bond_color()
        // check every pair of atoms to determine if a bond need to be added
        for var i = 0; i<self.normalatomnode.childNodes.count; ++i {
            for var j = i+1; j<self.normalatomnode.childNodes.count; ++j {
                let atom_a = self.normalatomnode.childNodes[i]
                let atom_b = self.normalatomnode.childNodes[j]
                let point_a = atom_a.position
                let point_b = atom_b.position
                // get atom names
                let name_a = atom_a.name
                let name_b = atom_b.name
                // get max bond length between the atoms
                let max_bond_length = dict_atom_max_bond_length(name_a!, name_b: name_b!)
                let length = CGdistance(point_a, b: point_b)
                if length < max_bond_length {
                    let bondGeometry = SCNCylinder(radius: bond_thickness, height: length)
                    bondGeometry.firstMaterial?.multiply.contents = bond_color
                    let bondNode = SCNNode(geometry: bondGeometry)
                    let dx = point_b.x - point_a.x
                    let dy = point_b.y - point_a.y
                    let dz = point_b.z - point_a.z
                    // the rotation axis (0,1,0)*(dx, dy, dz) = (dz, 0, dx)
                    // the rotation angle θ = arccos( (0,1,0).(dx, dy, dz)/|(dx, dy, dz)|)
                    bondNode.rotation = SCNVector4Make(dz, 0 , -dx, acos(dy/length))
                    bondNode.position = SCNVector3Make(0.5*(point_a.x+point_b.x), 0.5*(point_a.y+point_b.y), 0.5*(point_a.z+point_b.z))
                    self.normalbondnode.addChildNode(bondNode)
                }
            }
        }
    }
    
    func dict_atom_max_bond_length(name_a: NSString, name_b: NSString) -> CGFloat {
        // default max bond length if not found
        var result : CGFloat = 1.6
        // open Elements.plist
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Elements", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            if let a_max = dict.objectForKey("Element Max Bond Length")?.objectForKey(name_a) {
                if let max_bond_length = a_max.objectForKey(name_b) {
                    result = CGFloat(max_bond_length.floatValue)
                }
            }
            else if let b_max = dict.objectForKey("Element Max Bond Length")?.objectForKey(name_b) {
                if let max_bond_length = b_max.objectForKey(name_a) {
                    result = CGFloat(max_bond_length.floatValue)
                }
            }
        }
        return result
    }
    
    func dict_bond_thickness() -> CGFloat {
        // default value if no entry found in dict
        var result : CGFloat = 0.08
        // open Elements.plist
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Elements", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            if let bond_thickness = dict.objectForKey("Bond Thickness") {
                result = CGFloat(bond_thickness.floatValue)
                }
        }
        return result
    }
    
    func dict_bond_color() -> NSColor {
        // default value if no entry found in dict
        var result = NSColor(deviceRed: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Elements", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            if let color = dict.objectForKey("Bond Color") {
                if color.count == 3{
                    let red = CGFloat(color[0].floatValue/255)
                    let green = CGFloat(color[1].floatValue/255)
                    let blue = CGFloat(color[2].floatValue/255)
                    result = NSColor(deviceRed: red, green: green, blue: blue, alpha: 1)
                }
            }
        }
        return result
    }
    
    func init_with_dae(url: NSURL?) -> Bool {
        do {
            let load_scene = try SCNScene(URL: url!, options: nil)
            self.scene = load_scene
            // restore the node hierarchy
            self.cameraNode = load_scene.rootNode.childNodes[0]
            // add a new lightNode as childnode of cameraNode
            self.lightNode = SCNNode()
            self.lightNode.light = SCNLight()
            self.lightNode.light!.type = SCNLightTypeDirectional
            self.lightNode.rotation = SCNVector4Make(1, 1, 0, -0.7)
            self.cameraNode.addChildNode(self.lightNode)
            self.moleculeNode = load_scene.rootNode.childNodes[2]
            self.atomnodes = self.moleculeNode.childNodes[0]
            self.bondnodes = self.moleculeNode.childNodes[1]
            self.normalatomnode = self.atomnodes.childNodes[0]
            self.selectedatomnode = self.atomnodes.childNodes[1] // this should be empty
            self.normalbondnode = self.bondnodes.childNodes[0]
            self.selectedbondnode = self.bondnodes.childNodes[1] // this should be empty
            // reset all the bondnodes to prevent cast error from SCNgeometry to SCNcylinder
            for each_bond in (self.normalbondnode.childNodes + self.selectedbondnode.childNodes) {
                var v1 = SCNVector3()
                var v2 = SCNVector3()
                each_bond.getBoundingBoxMin(&v1, max: &v2)
                let new_geometry = SCNCylinder(radius: abs(v2.x-v1.x)/2, height: abs(v2.y-v1.y))
                new_geometry.firstMaterial?.multiply.contents = each_bond.geometry!.firstMaterial?.multiply.contents
                each_bond.geometry = new_geometry
            }
            // reset the rotate button
            let windowController = NSApplication.sharedApplication().windows[0].windowController as! CustomWindowController
            let appdelegate = NSApplication.sharedApplication().delegate as! AppDelegate
            appdelegate.menu_rotate.state = NSOffState
            windowController.toolbar_rotate.image = NSImage(named: "rotate.png")

            return true
        }
        catch {
            NSLog("Can't open file")
            return false
        }
    }
    
    func change_texture(texture: String) {
        for eachatom in self.normalatomnode.childNodes + self.normalbondnode.childNodes {
            if let material = eachatom.geometry?.firstMaterial {
                if texture == "none" { // reset all texture
                    material.diffuse.contents = nil
                    material.normal.contents = nil
                    material.specular.contents = nil
                    material.reflective.contents = nil
                }
                if texture == "metal" {
                    material.diffuse.contents = NSImage(named: "diffuse-metal.jpg")
                    material.normal.contents = NSImage(named: "normal-metal.jpg")
                    material.specular.contents = nil
                    material.reflective.contents = nil
                }
                if texture == "marble" {
                    material.diffuse.contents = NSImage(named: "diffuse-marble.jpg")
                    material.normal.contents = NSImage(named: "normal-marble.jpg")
                    material.specular.contents = nil
                    material.reflective.contents = nil
                }
                if texture == "wood" {
                    material.diffuse.contents = NSImage(named: "diffuse-wood.jpg")
                    material.normal.contents = NSImage(named: "normal-wood.png")
                    material.specular.contents = nil
                    material.reflective.contents = nil
                }
            }
        }
    }

    // provide drag-in opening files feature
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation
    {
        return NSDragOperation.Copy
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? NSArray {
            if let path = board[0] as? String {
                var success = false
                if (path as NSString).pathExtension == "dae" {
                    let fileUrl = NSURL(fileURLWithPath: path)
                    success = self.init_with_dae(fileUrl)
                }
                else {
                    let input = file_parser(path: path)
                    if input.AtomList.count > 0 {
                        self.init_scene()
                        for eachatom in input.AtomList{
                            self.add_atom(eachatom)
                        }
                        self.auto_add_bond()
                        success = true
                    }
                }
                let view_controller = NSApplication.sharedApplication().windows[0].contentViewController as! ViewController
                if success {
                    view_controller.info_bar.stringValue = "Left click to select atoms and click +Bond to add bond"
                    return true
                }
                else {
                    view_controller.info_bar.stringValue = "File not recognized"
                }
            }
        }
        return false
    }
    
    
    func make_transparent(thisnode: SCNNode) {
        undoManager?.registerUndoWithTarget(self, selector: Selector("reset_transparent:"), object: thisnode)
        thisnode.opacity = 0.7
    }
    
    func reset_transparent(thisnode: SCNNode) {
        undoManager?.registerUndoWithTarget(self, selector: Selector("make_transparent:"), object: thisnode)
        thisnode.opacity = 1.0
    }
    
    func adjust_focus() {
        let total_number_of_atoms = self.normalatomnode.childNodes.count + self.selectedatomnode.childNodes.count
        if total_number_of_atoms > 0{
            var sumx=0.0 as CGFloat, sumy=0.0 as CGFloat, sumz=0.0 as CGFloat
            var maxz=0.0 as CGFloat
            // get average and standard deviation of all atoms' position
            for eachnode in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
                sumx += eachnode.position.x
                sumy += eachnode.position.y
                sumz += eachnode.position.z
                if maxz < eachnode.position.z {
                    maxz = eachnode.position.z
                }
            }
            let ave_x = sumx / CGFloat(total_number_of_atoms)
            let ave_y = sumy / CGFloat(total_number_of_atoms)
            let ave_z = sumz / CGFloat(total_number_of_atoms)
            // adjust camara position
            self.cameraNode.position.x = ave_x
            self.cameraNode.position.y = ave_y
            self.cameraNode.position.z = maxz + 11
            // adjust camara height
//            self.cameraNode.position = SCNVector3(x: 0, y: 0, z: maxz - ave_z)
        }
    }
    
    
} // end of class
