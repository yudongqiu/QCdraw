//
//  MySceneView.swift
//  QChelper
//
//  Created by Yudong Qiu on 7/10/15.
//  Copyright (c) 2015 QYD. All rights reserved.
//

import SceneKit

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
    
    let view_controller = NSApplication.shared.windows[0].contentViewController as! ViewController
    let appdelegate = NSApplication.shared.delegate as! AppDelegate
    let windowController = NSApplication.shared.windows[0].windowController as! CustomWindowController
    
    var click_location = NSPoint()
    var p_pov = SCNVector3Zero
    
    func init_scene() {
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
        self.cameraNode.camera?.fieldOfView = 40
        self.cameraNode.camera?.zNear = 0.5
        self.cameraNode.camera?.zFar = 1000
//        self.cameraNode.camera?.focalSize = 20.0
//        self.cameraNode.camera?.focalBlurRadius = 5.0
//        self.cameraNode.camera?.focalDistance = 1.0
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(self.cameraNode)
        
        // create and add a light to the scene
        self.lightNode.light = SCNLight()
        self.lightNode.light!.type = SCNLight.LightType.directional
        self.lightNode.light!.castsShadow = (appdelegate.menu_cast_shadow.state == .on)
        self.lightNode.rotation = SCNVector4Make(1, 1, 0, -0.7)
        self.cameraNode.addChildNode(self.lightNode)
        
        
        // add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "ambientlght"
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = NSColor(deviceWhite: 0.2, alpha: 1)
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
        appdelegate.menu_rotate.state = .off
        windowController.toolbar_rotate.image = NSImage(named: "rotate.png")
    }
    
    func add_atom(thisatom: atom) -> Void {
        // draw a sphere
        let sphereGeometry = SCNSphere(radius: thisatom.radius)
        sphereGeometry.isGeodesic = true
        sphereGeometry.segmentCount = 50
        let color = NSColor(red: thisatom.color[0], green: thisatom.color[1], blue: thisatom.color[2], alpha: 1)
        sphereGeometry.firstMaterial?.multiply.contents = color
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.name = thisatom.name as String
        sphereNode.position = SCNVector3(x: thisatom.pos[0], y: thisatom.pos[1], z: thisatom.pos[2])
        self.normalatomnode.addChildNode(sphereNode)
    }
    
    func add_bond() -> Void {
        // open Elements.plist
        let path = Bundle.main.path(forResource: "Elements", ofType: "plist")
        let myDict = NSDictionary(contentsOfFile: path!)
        // get bond thickness and color from Elements.plist
        let bond_thickness = dict_bond_thickness(myDict: myDict!)
        let bond_color : NSColor = dict_bond_color(myDict: myDict!)
        // add bond between every pair of atoms in selected atomnodes
        for i in 0 ..< self.selectedatomnode.childNodes.count {
            for j in i+1 ..< self.selectedatomnode.childNodes.count {
                let point_a = self.selectedatomnode.childNodes[i].position
                let point_b = self.selectedatomnode.childNodes[j].position
                // draw a cylinder
                let d = point_a - point_b
                let length = d.length()
                let bondGeometry = SCNCylinder(radius: bond_thickness, height: length)
                bondGeometry.firstMaterial?.multiply.contents = bond_color
                let bondNode = SCNNode(geometry: bondGeometry)
                // the rotation axis (0,1,0)*(dx, dy, dz) = (dz, 0, dx)
                // the rotation angle θ = arccos( (0,1,0).(dx, dy, dz)/|(dx, dy, dz)|)
                bondNode.rotation = SCNVector4Make(d.z, 0 , -d.x, acos(d.y/length))
                bondNode.position = (point_a + point_b) * 0.5
                // check if the bondNode already exists
                var exist = false
                for eachnode in self.normalbondnode.childNodes + self.selectedbondnode.childNodes {
                    if SCNVector3EqualToVector3(bondNode.position,eachnode.position) && SCNVector4EqualToVector4(bondNode.rotation,eachnode.rotation) {
                        exist = true
                        break
                    }
                }
                if exist == false {
                    add_bond_node(thisnode: bondNode)
                }
            }
        }
    }
    
    @objc func remove_node(thisnode: SCNNode) {
        if (self.normalatomnode.childNodes + self.selectedatomnode.childNodes).contains(thisnode) {
            undoManager?.registerUndo(withTarget: self, selector: #selector(MySceneView.add_atom_node), object: thisnode)
        }
        else if (self.normalbondnode.childNodes + self.selectedbondnode.childNodes).contains(thisnode) {
            undoManager?.registerUndo(withTarget: self, selector: #selector(MySceneView.add_bond_node), object: thisnode)
        }
        self.removeBlinkAnimation(node: thisnode)
        thisnode.removeFromParentNode()
        // reset info bar
        view_controller.info_bar.stringValue = ""
    }
    
    @objc func add_atom_node(thisnode: SCNNode) {
        undoManager?.registerUndo(withTarget: self, selector: #selector(MySceneView.remove_node), object: thisnode)
        self.normalatomnode.addChildNode(thisnode)
    }
    
    @objc func add_bond_node(thisnode: SCNNode) {
        undoManager?.registerUndo(withTarget: self, selector: #selector(MySceneView.remove_node), object: thisnode)
        self.normalbondnode.addChildNode(thisnode)
    }
    
    func save_file(url: URL) -> Bool {
        var success = false
        do {
            if (url as NSURL).pathExtension == "pdf" {
                let myView = NSImageView(frame: self.bounds)
                myView.image = self.snapshot()
                let pdfdata = myView.dataWithPDF(inside: self.bounds)
                try pdfdata.write(to: url, options: .atomic)

            }
            else if (url as NSURL).pathExtension == "png" {
                let pngdata = NSBitmapImageRep(data: self.snapshot().tiffRepresentation!)!.representation(using: .png, properties: [:])!
                try pngdata.write(to: url, options: .atomic)
            }
            success = true
        } catch _ {
            success = false
        }
        return success
    }
    
    func export_scene(fileurl: URL) -> Bool {
        var success = false
        if let scene = self.scene {
            // remove lightNode to reset default light
            self.lightNode.removeFromParentNode()
            // save scene to .dae file
            success = scene.write(to: fileurl, options: nil, delegate: nil, progressHandler: nil)
            // add lightNode back
            self.cameraNode.addChildNode(self.lightNode)
        }
        return success
    }
    
    func export_json_tungsten(fileurl: URL) -> Bool {
        var success = false
        // Prepare primitives containing each atom's position and radius
        var primitives: [NSDictionary] = []
        var bsdfs: [NSDictionary] = []
        var known_bsdfs = Set<String>()
        var lowest_y : CGFloat = CGFloat.greatestFiniteMagnitude
        var lowest_z : CGFloat = CGFloat.greatestFiniteMagnitude
        for eachatom in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
            var name = eachatom.name!
            if eachatom.opacity < 1.0 {
                name += "_trans"
            }
            let p = eachatom.position
            let radius = (eachatom.geometry as! SCNSphere).radius
            let primitive : NSDictionary = ["name": name, "transform": ["position": [p.x, p.y, p.z], "scale": radius], "type": "sphere", "bsdf": name]
            primitives.append(primitive)
            // Store the atom's color in bsdfs
            if !known_bsdfs.contains(name){
                known_bsdfs.insert(name)
                let color = eachatom.geometry!.firstMaterial?.multiply.contents as! NSColor
                let r = (1.0 - color.redComponent)
                let g = (1.0 - color.greenComponent)
                let b = (1.0 - color.blueComponent)
                if eachatom.opacity < 1.0 {
                    let bsdf : NSDictionary = ["name": name,
                                               "albedo": 1.0,
                                               "type": "thinsheet",
                                               "ior": 1.3,
                                               "thickness": 1.0,
                                               "sigma_a": [r*0.5, g*0.5, b*0.5]]
                    bsdfs.append(bsdf)
                }
                else {
                    let bsdf : NSDictionary = ["name": name,
                                               "albedo": 1.0,
                                               "type": "plastic",
                                               "ior": 1.3,
                                               "thickness": 1.0,
                                               "sigma_a": [r, g, b]]
                    bsdfs.append(bsdf)
                }
            }
            // record the lowest y
            let p_pov = self.pointOfView!.convertPosition(eachatom.position, from: nil)
            lowest_y = min(lowest_y, p_pov.y)
            lowest_z = min(lowest_z, p_pov.z)
        }
        // add the bonds
        if self.moleculeNode.childNodes.contains(self.bondnodes) {
            for eachbond in self.normalbondnode.childNodes + self.selectedbondnode.childNodes {
                let v1 = eachbond.boundingBox.min
                let v2 = eachbond.boundingBox.max
                let radius = abs(v2.x-v1.x)
                let length = abs(v2.y-v1.y)
                let p = eachbond.position
                let rotation = convert_tungsten_rotation(rotation: eachbond.eulerAngles)
                var name = "bond"
                if eachbond.opacity < 1.0 {
                    name += "_trans"
                }
                let prim_bond : NSDictionary = ["name": name,
                                                "transform": ["position": [p.x, p.y, p.z],
                                                              "scale": [radius, length, radius],
                                                              "rotation": rotation
                                                              ],
                                                "type": "cylinder",
                                                "bsdf": name]
                primitives.append(prim_bond)
            }
            let bond_bsdf : NSDictionary = ["name": "bond",
                                            "albedo": 1.0,
                                            "type": "rough_plastic",
                                            "ior": 1.3,
                                            "sigma_a" : 0.6,
                                            "roughness": 0.1]
            let bond_trans_bsdf : NSDictionary = ["name": "bond_trans",
                                            "albedo": 1.0,
                                            "type": "thinsheet",
                                            "ior": 1.3,
                                            "sigma_a" : 0.4
                                            ]
            bsdfs.append(bond_bsdf)
            bsdfs.append(bond_trans_bsdf)
        }
        
        // Set the camera
        let pov = self.pointOfView!
        let p = pov.position
        let p1 = pov.convertPosition(SCNVector3(0,0,-11), to: nil)
        let p_up = pov.convertPosition(SCNVector3(0,1,0), to: nil) - p
        let camera: NSDictionary = ["tonemap": "filmic",
                                    "resolution": [self.bounds.width*2, self.bounds.height*2],
                                    "reconstruction_filter": "tent",
                                    "transform": ["position": [p.x, p.y, p.z],
                                                  "look_at": [p1.x, p1.y, p1.z],
                                                  "up": [p_up.x, p_up.y, p_up.z]],
                                    "type": "pinhole",
                                    "fov": pov.camera!.fieldOfView+20]

        let integrator: NSDictionary = ["min_bounces": 0,
                                        "max_bounces": 64,
                                        "enable_consistency_checks": false,
                                        "enable_two_sided_shading": true,
                                        "type": "path_tracer",
                                        "enable_light_sampling": true,
                                        "enable_volume_light_sampling": true]
        
        let renderer: NSDictionary = ["overwrite_output_files": false,
                                      "adaptive_sampling": true,
                                      "enable_resume_render": false,
                                      "stratified_sampler": true,
                                      "scene_bvh": true,
                                      "spp": 32,
                                      "spp_step": 16,
                                      "timeout": "0",
                                      "output_file": "TungstenRender.png",
                                      "resume_render_file": "RenderState.dat"]
        
        // Add the envmap
        let envmap : NSDictionary = ["name": "Envmap",
                                     "transform": ["position": [0, 0, 0],
                                                   "up": [p_up.x, p_up.y, p_up.z]],
                                     "type": "infinite_sphere",
                                     "emission": "envmap.hdr",
                                     "sample": true]
        primitives.append(envmap)
        
        // Add the floor
        let pf = pov.convertPosition(SCNVector3(0, lowest_y-1, 0), to: nil)
        let floor : NSDictionary = ["name": "Floor",
                                    "transform": ["position" : [pf.x, pf.y, pf.z],
                                                  "up" : [p_up.x, p_up.y, p_up.z],
                                                  "scale": 200.0],
                                    "type": "quad",
                                    "bsdf": "Floor"
                                    ]
        primitives.append(floor)
        let bsdf_floor : NSDictionary = ["name": "Floor",
                                         "albedo": 0.1,
                                         "type": "lambert"
                                        ]
        bsdfs.append(bsdf_floor)
        
        // Add backwall
        let p_wall = pov.convertPosition(SCNVector3(0,0,lowest_z-5), to: nil)
        let w1 = pov.convertPosition(SCNVector3(0,0,1), to: nil) - p
        let wall : NSDictionary = [ "name": "Wall",
                                    "transform": ["position" : [p_wall.x, p_wall.y, p_wall.z],
                                                  "up" : [w1.x, w1.y, w1.z],
                                                  "scale": 100.0],
                                    "type": "quad",
                                    "bsdf": "Floor"]
        
        primitives.append(wall)
        // Add a spotlight directed from top to bottom
        let plight = pov.convertPosition(SCNVector3(0,50,0), to: nil) - p
        let spotlight: NSDictionary = ["name": "SpotLight",
                                       "transform": ["position": [plight.x, plight.y, plight.z],
                                                     "up": [-p_up.x, -p_up.y, -p_up.z],
                                                     "scale": 3],
                                       "type": "disk",
                                       "emission": 40,
                                       "bsdf": ["albedo": 1.0, "type": "null"]
                                      ]
        primitives.append(spotlight)
        let dictonary :  NSDictionary = ["media": [], "bsdfs": bsdfs, "primitives": primitives, "camera": camera,
                                         "integrator": integrator, "renderer": renderer]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictonary, options: .prettyPrinted)
            try jsonData.write(to: fileurl, options: .atomic)
            success = true
        } catch {
            NSLog("Error creating JSON object")
        }
        return success
    }
    
    func convert_tungsten_rotation(rotation: SCNVector3) -> [CGFloat] {
        let rotx = rotation.x
        let roty = rotation.y
        let rotz = rotation.z
        let a23 = cos(rotx)*sin(rotz)*sin(roty) - cos(rotz)*sin(rotx)
        var theta : CGFloat, phi : CGFloat, psi : CGFloat
        if a23 <= -1.0 {
            theta = -0.5 * .pi
            let a31 = -sin(roty)
            let a32 = cos(roty) * sin(rotx)
            phi = atan2(a31, a32)
            psi = 0.0
        }
        else if a23 >= 1.0 {
            theta = 0.5 * .pi
            let a31 = -sin(roty)
            let a32 = cos(roty) * sin(rotx)
            phi = atan2(-a31, -a32)
            psi = 0.0
        }
        else {
            theta = -asin(a23)
            let a21 = cos(roty)*sin(rotz)
            let a22 = cos(rotz)*cos(rotx) + sin(rotz)*sin(roty)*sin(rotx)
            let a13 = sin(rotz)*sin(rotx) + cos(rotz)*cos(rotx)*sin(roty)
            let a33 = cos(roty)*cos(rotx)
            phi = atan2(a21, a22)
            psi = -atan2(a13, a33)
        }
        return [theta * 180.0 / .pi,
                psi   * 180.0 / .pi,
                phi   * 180.0 / .pi]
    }
    
    
    override func mouseDown(with theEvent: NSEvent) {
        let hitResults = hitTest(theEvent.locationInWindow, options: nil)
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let hitnode = hitResults[0].node
            if self.normalatomnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                self.addBlinkAnimation(node: hitnode)
                self.selectedatomnode.addChildNode(hitnode)
            }
            else if self.selectedatomnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                self.removeBlinkAnimation(node: hitnode)
                self.selectedatomnode.addChildNode(hitnode)
            }
            else if self.normalbondnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                self.addBlinkAnimation(node: hitnode)
                self.selectedbondnode.addChildNode(hitnode)
            }
            else if self.selectedbondnode.childNodes.contains(hitnode) {
                hitnode.removeFromParentNode()
                self.removeBlinkAnimation(node: hitnode)
                self.normalbondnode.addChildNode(hitnode)
            }
        }
        super.mouseDown(with: theEvent)
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

    override func mouseDragged(with theEvent: NSEvent) {
        // set lightnode as childnode of cameranode, and set cameranode to follow the pointofview
        if let current_transform = self.pointOfView?.transform {
            self.cameraNode.transform = current_transform
        }
        super.mouseDragged(with: theEvent)
    }
    
    
    override func mouseUp(with theEvent: NSEvent) {
        // print info bar
        // print atom name (only one)
        if self.selectedatomnode.childNodes.count == 1 && self.selectedbondnode.childNodes.count == 0 {
            let node = self.selectedatomnode.childNodes[0]
            view_controller.info_bar.stringValue = String(format: "Atom : %@ %@", node.name!, node.position.stringValue)
        }
        // print bond length (only one)
        else if self.selectedbondnode.childNodes.count == 1 && self.selectedatomnode.childNodes.count == 0 {
            let geometry = self.selectedbondnode.childNodes[0].geometry as! SCNCylinder
            view_controller.info_bar.stringValue = String(format: "R = %.5f \u{212B}", geometry.height)
        }
        // print bond angles (if two connected bonds are selected)
        else if self.selectedbondnode.childNodes.count == 2 {
            let bond_a = self.selectedbondnode.childNodes[0]
            let bond_b = self.selectedbondnode.childNodes[1]
            // compute the starting and ending point of the bonds
            let (a_start, a_end) = compute_bond_ends(bondnode: bond_a)
            let a_vector : float3 = float3(a_start - a_end)
            let (b_start, b_end) = compute_bond_ends(bondnode: bond_b)
            let b_vector : float3 = float3(b_start - b_end)
            let a_length = (bond_a.geometry as! SCNCylinder).height
            let b_length = (bond_b.geometry as! SCNCylinder).height
            let theta = acos(dot(a_vector,b_vector)/Float(a_length * b_length)) / .pi * 180.0
            if a_start ~= b_start || a_end ~= b_end {
                view_controller.info_bar.stringValue = "\u{03F4} = " + theta.description + "\u{00B0}"
            }
            else if a_start ~= b_end || a_end ~= b_start {
                view_controller.info_bar.stringValue = "\u{03F4} = " + (180.0-theta).description + "\u{00B0}"
            }
            else {
                view_controller.info_bar.stringValue = "Right click to deselect all"
            }
        }
        // print dihedral angle ( if three connected bonds are selected)
        else if self.selectedbondnode.childNodes.count == 3 {
            // put the nodes ends into an array
            var bond_ends : [(SCNVector3, SCNVector3)] = []
            for thisbond in self.selectedbondnode.childNodes {
                bond_ends.append(compute_bond_ends(bondnode: thisbond))
            }
            // find out the connection between bonds
            var mid = -1
            for i in 0...2 { // find out the center bond first
                var same_start = false
                var same_end = false
                let (i_start, i_end) = bond_ends[i]
                for j in 0...2 {
                    if j != i {
                        let (j_start, j_end) = bond_ends[j]
                        if i_start ~= j_start || i_start ~= j_end {
                            same_start = true
                        }
                        else if i_end ~= j_start || i_end ~= j_end {
                            same_end = true
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
                point2 = bond_ends[mid].0
                point3 = bond_ends[mid].1
                // find point1 and point4
                for i in 0...2 {
                    if i != mid {
                        if bond_ends[i].0 ~= point2 {
                            point1 = bond_ends[i].1
                        }
                        else if bond_ends[i].1 ~= point2 {
                            point1 = bond_ends[i].0
                        }
                        else if bond_ends[i].0 ~= point3 {
                            point4 = bond_ends[i].1
                        }
                        else if bond_ends[i].1 ~= point3 {
                            point4 = bond_ends[i].0
                        }
                    }
                }
                // compute the dihedral angle between point 1 -- 4
                let a_vector : float3 = float3(point1 - point2)
                let b_vector : float3 = float3(point2 - point3)
                let c_vector : float3 = float3(point3 - point4)
                let Uab = cross(a_vector, b_vector)
                let Ubc = cross(b_vector, c_vector)
                let gamma = acos(dot(Uab,Ubc)/(length(Uab)*length(Ubc))) / .pi * 180.0
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
        super.mouseUp(with: theEvent)
    }
    
    func compute_bond_ends(bondnode : SCNNode) -> (start: SCNVector3, end:SCNVector3) {
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
        let dx = r * sin(w) * (-z / sqrt(z*z+x*x))
        let dy = r * cos(w)
        let dz = r * sin(w) * (x / sqrt(z*z+x*x))
        let dr = SCNVector3Make(dx, dy, dz)
        let starting_point = center + dr
        let ending_point = center - dr
        return (starting_point, ending_point)
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        // record the click location for drag        
        reset_selection()
        click_location = theEvent.locationInWindow
        p_pov = self.pointOfView!.position
        super.rightMouseDown(with: theEvent)
    }
    
    override func rightMouseDragged(with theEvent: NSEvent) {
        // allows rightmouse drag the view
        //super.scrollWheel(with: theEvent)
        let point = theEvent.locationInWindow
        let dx = point.x - click_location.x
        let dy = point.y - click_location.y
        let shift = self.pointOfView!.convertVector(SCNVector3(dx * 0.02, dy * 0.02, 0), to: nil)
        self.pointOfView!.position = p_pov - shift
        super.rightMouseDragged(with: theEvent)
    }
    
    func reset_selection() {
        for eachnode in self.selectedatomnode.childNodes {
            eachnode.removeFromParentNode()
            self.removeBlinkAnimation(node: eachnode)
            self.normalatomnode.addChildNode(eachnode)
        }
        for eachnode in self.selectedbondnode.childNodes {
            eachnode.removeFromParentNode()
            self.removeBlinkAnimation(node: eachnode)
            self.normalbondnode.addChildNode(eachnode)
        }
        view_controller.info_bar.stringValue = ""
    }
    
    func select_all() {
        for eachnode in self.normalatomnode.childNodes {
            eachnode.removeFromParentNode()
            self.addBlinkAnimation(node: eachnode)
            self.selectedatomnode.addChildNode(eachnode)
        }
        for eachnode in self.normalbondnode.childNodes {
            eachnode.removeFromParentNode()
            self.addBlinkAnimation(node: eachnode)
            self.selectedbondnode.addChildNode(eachnode)
        }
    }
    
    func addBlinkAnimation(node: SCNNode) {
        let material = node.geometry!.firstMaterial!
        let animation = CABasicAnimation(keyPath: "intensity")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 1.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        material.diffuse.addAnimation(animation, forKey: "blink")
    }
    
    func removeBlinkAnimation(node: SCNNode) {
        let material = node.geometry!.firstMaterial!
        material.removeAnimation(forKey: "blink")
    }
    
    func auto_add_bond() {
        // open Elements.plist
        let path = Bundle.main.path(forResource: "Elements", ofType: "plist")
        let myDict = NSDictionary(contentsOfFile: path!)
        // get bond thickness and color from Elements.plist
        let bond_thickness = dict_bond_thickness(myDict: myDict!)
        let bond_color : NSColor = dict_bond_color(myDict: myDict!)
        // check every pair of atoms to determine if a bond need to be added
        for i in 0 ..< self.normalatomnode.childNodes.count {
            for j in i+1 ..< self.normalatomnode.childNodes.count {
                let atom_a = self.normalatomnode.childNodes[i]
                let atom_b = self.normalatomnode.childNodes[j]
                let point_a = atom_a.position
                let point_b = atom_b.position
                let dx = abs(point_a.x - point_b.x)
                if dx > 3.0 { continue }
                let dy = abs(point_a.y - point_b.y)
                if dy > 3.0 { continue }
                let dz = abs(point_a.z - point_b.z)
                if dz > 3.0 { continue }
                let lengthSq = dx*dx + dy*dy + dz*dz
                // get atom names
                let name_a = atom_a.name! as NSString
                let name_b = atom_b.name! as NSString
                // get max bond length between the atoms
                let max_bond_length = dict_atom_max_bond_length(myDict: myDict!, name_a: name_a, name_b: name_b)
//                let lengthSq = (point_a - point_b).lengthSq()
                if lengthSq < max_bond_length * max_bond_length {
                    let length = sqrt(lengthSq)
                    let bondGeometry = SCNCylinder(radius: bond_thickness, height: length)
                    bondGeometry.firstMaterial?.multiply.contents = bond_color
                    let bondNode = SCNNode(geometry: bondGeometry)
                    let d = point_b - point_a
                    // the rotation axis (0,1,0)*(dx, dy, dz) = (dz, 0, dx)
                    // the rotation angle θ = arccos( (0,1,0).(dx, dy, dz)/|(dx, dy, dz)|)
                    bondNode.rotation = SCNVector4Make(d.z, 0 , -d.x, acos(d.y/length))
                    bondNode.position = (point_a + point_b) * 0.5
                    self.normalbondnode.addChildNode(bondNode)
                }
            }
        }
    }
    
    func dict_atom_max_bond_length(myDict: NSDictionary, name_a: NSString, name_b: NSString) -> CGFloat {
        // default max bond length if not found
        let result : CGFloat = 1.6
        if let bond_length_dict = myDict.object(forKey: "Element Max Bond Length") as? NSDictionary {
            if let a_max = bond_length_dict.object(forKey: name_a) as? NSDictionary {
                if let max_bond_length = a_max.object(forKey: name_b) as? NSNumber {
                    return CGFloat(max_bond_length.floatValue)
                }
            }
            if let b_max = bond_length_dict.object(forKey: name_b) as? NSDictionary {
                if let max_bond_length = b_max.object(forKey: name_a) as? NSNumber {
                    return CGFloat(max_bond_length.floatValue)
                }
            }
        }
        return result
    }
    
    func dict_bond_thickness(myDict: NSDictionary) -> CGFloat {
        // default value if no entry found in dict
        var result: CGFloat = 0.08
        if let bond_thickness = myDict.object(forKey: "Bond Thickness") as? NSNumber {
            result = CGFloat(bond_thickness.floatValue)
        }
        return result
    }
    
    func dict_bond_color(myDict: NSDictionary) -> NSColor {
        // default value if no entry found in dict
        var result = NSColor(deviceRed: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        if let color = myDict.object(forKey: "Bond Color") as? [NSNumber] {
            if color.count == 3{
                let red = CGFloat(color[0].floatValue/255)
                let green = CGFloat(color[1].floatValue/255)
                let blue = CGFloat(color[2].floatValue/255)
                result = NSColor(red: red, green: green, blue: blue, alpha: 1)
            }
        }
        return result
    }
    
    func open_file(url: URL?) {
        if let path = url?.path {
            var success = false
            if (path as NSString).pathExtension == "dae" {
                success = self.init_with_dae(url: url)
            }
            else {
                let input = file_parser(path: path)
                if input.AtomList.count > 0 {
                    self.init_scene()
                    for eachatom in input.AtomList{
                        self.add_atom(thisatom: eachatom)
                    }
                    self.auto_add_bond()
                    self.adjust_focus()
                    success = true
                }
            }
            if success {
                view_controller.info_bar.stringValue = "Left click to select atoms and click +Bond to add bond"
            }
            else {
                view_controller.info_bar.stringValue = "File not recognized"
            }
        }
    }
    
    func init_with_dae(url: URL?) -> Bool {
        do {
            let load_scene = try SCNScene(url: url!, options: nil)
            self.scene = load_scene
            // restore the node hierarchy
            self.cameraNode = load_scene.rootNode.childNodes[0]
            // add a new lightNode as childnode of cameraNode
            self.lightNode = SCNNode()
            self.lightNode.light = SCNLight()
            self.lightNode.light!.type = SCNLight.LightType.directional
            self.lightNode.rotation = SCNVector4Make(1, 1, 0, -0.7)
            self.cameraNode.addChildNode(self.lightNode)
            self.moleculeNode = load_scene.rootNode.childNodes[2]
            self.atomnodes = self.moleculeNode.childNodes[0]
            self.bondnodes = self.moleculeNode.childNodes[1]
            self.normalatomnode = self.atomnodes.childNodes[0]
            self.selectedatomnode = self.atomnodes.childNodes[1] // this should be empty
            self.normalbondnode = self.bondnodes.childNodes[0]
            self.selectedbondnode = self.bondnodes.childNodes[1] // this should be empty
            // reset all the atomnodes to prevent cast error from SCNgeometry to SCNSphere
            for eachatom in self.normalatomnode.childNodes {
                var radius : CGFloat = 0.0
                var center = SCNVector3()
                eachatom.__getBoundingSphereCenter(&center, radius: &radius)
                // draw a new sphere
                let sphereGeometry = SCNSphere(radius: radius)
                sphereGeometry.isGeodesic = true
                sphereGeometry.segmentCount = 200
                sphereGeometry.firstMaterial?.multiply.contents = eachatom.geometry!.firstMaterial?.multiply.contents
                eachatom.geometry = sphereGeometry
            }
            // reset all the bondnodes to prevent cast error from SCNgeometry to SCNcylinder
            for eachbond in (self.normalbondnode.childNodes + self.selectedbondnode.childNodes) {
                let v1 = eachbond.boundingBox.min
                let v2 = eachbond.boundingBox.max
                let new_geometry = SCNCylinder(radius: abs(v2.x-v1.x)/2, height: abs(v2.y-v1.y))
                new_geometry.firstMaterial?.multiply.contents = eachbond.geometry!.firstMaterial?.multiply.contents
                eachbond.geometry = new_geometry
            }
            // reset the rotate button
            appdelegate.menu_rotate.state = .off
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
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation
    {
        return NSDragOperation.copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var success = false
        if let board = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray {
            if let path = board[0] as? String {
                let url = URL(string: path)
                self.open_file(url: url)
                success = true
            }
        }
        return success
    }
    
    
    @objc func make_transparent(thisnode: SCNNode) {
        undoManager?.registerUndo(withTarget: self, selector: #selector(MySceneView.reset_transparent), object: thisnode)
        thisnode.opacity = 0.7
    }
    
    @objc func reset_transparent(thisnode: SCNNode) {
        undoManager?.registerUndo(withTarget: self, selector: #selector(MySceneView.make_transparent), object: thisnode)
        thisnode.opacity = 1.0
    }
    
    func adjust_focus() {
        let total_number_of_atoms = self.normalatomnode.childNodes.count + self.selectedatomnode.childNodes.count
        if total_number_of_atoms > 0{
            var sumx=0.0 as CGFloat, sumy=0.0 as CGFloat
            var maxz=0.0 as CGFloat
            // get average and standard deviation of all atoms' position
            for eachnode in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
                sumx += eachnode.position.x
                sumy += eachnode.position.y
                maxz = max(maxz, eachnode.position.z)
            }
            let ave_x = sumx / CGFloat(total_number_of_atoms)
            let ave_y = sumy / CGFloat(total_number_of_atoms)
            // adjust camara position
            self.pointOfView!.position = SCNVector3(x: ave_x, y: ave_y, z: maxz+11)
            self.pointOfView!.eulerAngles = SCNVector3(0, 0, 0)
        }
    }
    
    func change_to_vdw() {
        self.bondnodes.removeFromParentNode()
        for eachatom in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
            let geom = eachatom.geometry as! SCNSphere
            geom.radius *= 2.4
        }
    }
    
    func change_to_cpk() {
        self.moleculeNode.addChildNode(self.bondnodes)
        for eachatom in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
            let geom = eachatom.geometry as! SCNSphere
            geom.radius /= 2.4
        }
    }
    
    func recenter() {
        self.reset_selection()
        var shift = SCNVector3Zero
        for eachatom in self.normalatomnode.childNodes{
            shift += eachatom.position
        }
        let n = self.normalatomnode.childNodes.count + self.selectedatomnode.childNodes.count
        shift /= CGFloat(n)
        for eachnode in self.normalatomnode.childNodes + self.normalbondnode.childNodes {
            eachnode.position -= shift
        }
        self.adjust_focus()
    }
    
    func toggleRotateAnimation() {
        if self.moleculeNode.action(forKey: "rot") != nil {
            self.moleculeNode.removeAction(forKey: "rot")
        } else {
            if let pov = self.pointOfView {
                let p_up = pov.convertVector(SCNVector3(0,1,0), to: nil)
                let rotateAction = SCNAction.rotate(by: .pi*2, around: p_up, duration: 10)
                let repeatAction = SCNAction.repeatForever(rotateAction)
                self.moleculeNode.runAction(repeatAction, forKey: "rot")
            }
        }
    }
    
    
} // end of class


extension SCNVector3
{
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    static func += (left: inout SCNVector3, right: SCNVector3) {
        left = left + right
    }
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    static func -= (left: inout SCNVector3, right: SCNVector3) {
        left = left - right
    }
    static func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
    }
    static func *= (left: inout SCNVector3, right: SCNVector3) {
        left = left * right
    }
    static func * (vector: SCNVector3, scalar: CGFloat) -> SCNVector3 {
        return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
    static func *= (vector: inout SCNVector3, scalar: CGFloat) {
        vector = vector * scalar
    }
    static func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
    }
    static func /= (left: inout SCNVector3, right: SCNVector3) {
        left = left / right
    }
    static func / (vector: SCNVector3, scalar: CGFloat) -> SCNVector3 {
        return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
    }
    static func /= (vector: inout SCNVector3, scalar: CGFloat) {
        vector = vector / scalar
    }
    static func ~= (left: SCNVector3, right: SCNVector3) -> Bool {
        let tolerance : CGFloat = 0.0001
        if abs(left.x - right.x) < tolerance && abs(left.y - right.y) < tolerance && abs(left.z - right.z) < tolerance {
            return true
        }
        else {
            return false
        }
    }
    func lengthSq() -> CGFloat {
        return x*x + y*y + z*z
    }
    func length() -> CGFloat {
        return sqrt(x*x + y*y + z*z)
    }
    func distance(vector: SCNVector3) -> CGFloat {
        return (self - vector).length()
    }
    public var stringValue: String {
        return String(format: "(%.3f %.3f %.3f)", x, y, z)
    }
}
