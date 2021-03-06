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
    var ambientLightNode = SCNNode()
    
    let view_controller = NSApplication.shared.windows[0].contentViewController as! ViewController
    let appdelegate = NSApplication.shared.delegate as! AppDelegate
    let windowController = NSApplication.shared.windows[0].windowController as! CustomWindowController
    
    var click_location = NSPoint()
    var p_pov = SCNVector3Zero
    var renderSegmentCount = 50 // for determine quality of rendering
    
    var traj_length = 0 // length of trajectory
    var current_frame = 0
    
    // center of the atoms in molecule
    var mol_center_pos = SCNVector3(0,0,0)
    var camera_distance : CGFloat = 1.0
    
    var current_texture: Texture = defaultTexture
    
    var advancedRendering: Bool = false
    
    // the following attibutes are read from Elements.plist, by calling self.read_elements.plist()
    var dict_bond_thickness : CGFloat = 0.08
    var dict_bond_color : NSColor = NSColor(deviceRed: 0.25, green: 0.25, blue: 0.25, alpha: 1)
    var dict_element_max_distance : Dictionary<Bond, CGFloat> = [:]
    var dict_elem_color : Dictionary<String, NSColor> = [:]
    var dict_elem_radius : Dictionary<String, CGFloat> = [:]
    
    // max allowed bond lengh for building boxes in compute_bonds
    var max_bond_length: CGFloat = 3.0
    // cache for getting bond length
    var known_bond_length: [String: CGFloat] = [:]
    
    func finish_view_load() {
        // custom init function that only run onces after program starts
        self.read_elements_plist()
    }
    
    func read_elements_plist() {
        if let dpath = Bundle.main.path(forResource: "Elements", ofType: "plist") {
            if let myDict = NSDictionary(contentsOfFile: dpath) {
                // read bond thickness
                if let bond_thickness = myDict.object(forKey: "Bond Thickness") as? NSNumber {
                    self.dict_bond_thickness = CGFloat(bond_thickness.floatValue)
                }
                // read bond color
                if let color = myDict.object(forKey: "Bond Color") as? [NSNumber] {
                    if color.count == 3{
                        let red = CGFloat(color[0].floatValue/255)
                        let green = CGFloat(color[1].floatValue/255)
                        let blue = CGFloat(color[2].floatValue/255)
                        self.dict_bond_color = NSColor(red: red, green: green, blue: blue, alpha: 1)
                    }
                }
                // read max bond length
                if let bond_length_dict = myDict.object(forKey: "Element Max Bond Length") as? NSDictionary {
                    for (elem_a, dict_a) in bond_length_dict {
                        if let e_a = elem_a as? String {
                            if let elem_a_idx = ElementsIdxDict[e_a] {
                                if let d = dict_a as? NSDictionary {
                                    for (elem_b, bond_length) in d {
                                        if let e_b = elem_b as? String, let value = bond_length as? CGFloat {
                                            if let elem_b_idx = ElementsIdxDict[e_b] {
                                                self.dict_element_max_distance[Bond(elem_a_idx, elem_b_idx)] = value
                                                self.max_bond_length = max(self.max_bond_length, value)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // read elem colors
                if let element_color_dict = myDict.object(forKey: "Element Colors") as? NSDictionary {
                    for (elem_str, color_rgb_array) in element_color_dict {
                        if let element = elem_str as? String {
                            if let color_rgb = color_rgb_array as? Array<NSNumber> {
                                let red = CGFloat(color_rgb[0].floatValue / 255)
                                let green = CGFloat(color_rgb[1].floatValue / 255)
                                let blue = CGFloat(color_rgb[2].floatValue / 255)
                                let color = NSColor(red: red, green: green, blue: blue, alpha: 1)
                                self.dict_elem_color[element] = color
                            }
                        }
                    }
                }
                // read atom radius
                if let element_radius_dict = myDict.object(forKey: "Element Radius") as? NSDictionary {
                    for (elem_str, radius_input) in element_radius_dict {
                        if let element = elem_str as? String {
                            if let radius = radius_input as? NSNumber {
                                self.dict_elem_radius[element] = CGFloat(radius.floatValue)
                            }
                        }
                    }
                }
                // end of reading
            }
        }
    }
    
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
        self.ambientLightNode = SCNNode()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        self.cameraNode.name = "cameraNode"
        let camera = SCNCamera()
        camera.fieldOfView = 40
        camera.zNear = 0.5
        camera.zFar = 1000
//        camera.wantsDepthOfField = true
//        camera.focalBlurSampleCount = 10
//        camera.apertureBladeCount = 6
//        camera.focusDistance = 10
//        camera.fStop = 0.01
        self.cameraNode.camera = camera
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(self.cameraNode)
        
        // create and add a light to the scene
        self.lightNode.light = SCNLight()
        self.lightNode.light!.type = SCNLight.LightType.directional
        self.lightNode.light!.castsShadow = (appdelegate.menu_cast_shadow.state == .on)
        self.lightNode.rotation = SCNVector4Make(1, 1, 0, -0.7)
        self.cameraNode.addChildNode(self.lightNode)
        
        // add an ambient light to the scene
        
        self.ambientLightNode.name = "ambientlight"
        self.ambientLightNode.light = SCNLight()
        self.ambientLightNode.light!.type = .ambient
        self.ambientLightNode.light!.color = NSColor(deviceWhite: 1.0, alpha: 1.0)
        self.ambientLightNode.light!.intensity = 300
        scene.rootNode.addChildNode(self.ambientLightNode)
        
        // setup nodes hierarchy
        scene.rootNode.addChildNode(self.moleculeNode)
        self.moleculeNode.addChildNode(self.atomnodes)
        self.moleculeNode.addChildNode(self.bondnodes)
        self.atomnodes.addChildNode(self.normalatomnode)
        self.atomnodes.addChildNode(self.selectedatomnode)
        self.bondnodes.addChildNode(self.normalbondnode)
        self.bondnodes.addChildNode(self.selectedbondnode)
        
        // the deallocation of the previous scene happens here
        // It might be slow if the previous scene is heavy
        // I tried to move the deallocation to a background thread but was not successfull
        // Another option is to keep a strong reference to the previous scene, i.e. self.old_scene = self.scene
        // This will help the slow dealloc issue, but keeps using more memory
        self.scene = scene
        
        // length of the trajectory
        self.traj_length = 0
        self.current_frame = 0
        
        // reset the rotate button
        appdelegate.menu_rotate.state = .off
        windowController.toolbar_rotate.image = NSImage(named: "rotate.png")
        
        // reset view_controller elements
        view_controller.reset()
        
        // enable advanced rendering
        self.advancedRendering = false
        if appdelegate.menu_adv_render.state == .on {
            self.toggleAdvancedRendering(enable: true)
        }
        
        // show background based on menu state
        if appdelegate.menu_background_image.state == .on {
            self.toggleBackgroundImage(show: true)
        }
    }
    
    func init_with_dae(url: URL) -> Bool {
        do {
            let load_scene = try SCNScene(url: url, options: nil)
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
            // length of the trajectory
            self.traj_length = 0
            self.current_frame = 0
            // reset the rotate button
            appdelegate.menu_rotate.state = .off
            windowController.toolbar_rotate.image = NSImage(named: "rotate.png")
            // reset view_controller
            view_controller.reset()
            // enable advanced rendering
            self.advancedRendering = false
            if appdelegate.menu_adv_render.state == .on {
                self.toggleAdvancedRendering(enable: true)
            }
            // show background based on menu state
            if appdelegate.menu_background_image.state == .on {
                self.toggleBackgroundImage(show: true)
            }
            return true
        }
        catch {
            return false
        }
    }
    
    func add_atom(_ atom: Atom) {
        // Get element
        let elem = atom.element
        let index = atom.index
        // Determine the color and radius
        let color = self.dict_elem_color[elem] ?? NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        let radius = self.dict_elem_radius[elem] ?? 0.6
        // draw a sphere
        let sphereGeometry = SCNSphere(radius: radius)
        sphereGeometry.isGeodesic = true
        sphereGeometry.segmentCount = self.renderSegmentCount
        sphereGeometry.firstMaterial?.multiply.contents = color
        let sphereNode = SCNNode(geometry: sphereGeometry)
        self.apply_texture(sphereNode, self.current_texture)
        sphereNode.name = atom.element
        sphereNode.position = atom.pos
        sphereNode.setValue(index, forUndefinedKey: "atom_index")
        sphereNode.setValue(atom.name, forUndefinedKey: "atom_name")
        sphereNode.setValue(atom.trajectory, forUndefinedKey: "trajectory")
        self.normalatomnode.addChildNode(sphereNode)
        // note: SCNGeometry.SCNLevelOfDetail may be able to improve render performance
    }
    
    func add_bond() -> Void {
        // add bond between every pair of atoms in selected atomnodes
        for i in 0 ..< self.selectedatomnode.childNodes.count {
            for j in i+1 ..< self.selectedatomnode.childNodes.count {
                let atom_a = self.selectedatomnode.childNodes[i]
                let point_a = atom_a.position
                let atom_b = self.selectedatomnode.childNodes[j]
                let point_b = atom_b.position
                // draw a cylinder
                let d = point_a - point_b
                let length = d.length()
                let bondGeometry = SCNCylinder(radius: self.dict_bond_thickness, height: length)
                bondGeometry.radialSegmentCount = self.renderSegmentCount
                bondGeometry.firstMaterial?.multiply.contents = self.dict_bond_color
                let bondNode = SCNNode(geometry: bondGeometry)
                self.apply_texture(bondNode, self.current_texture)
                // the rotation axis (0,1,0)*(dx, dy, dz) = (dz, 0, dx)
                // the rotation angle θ = arccos( (0,1,0).(dx, dy, dz)/|(dx, dy, dz)|)
                bondNode.rotation = SCNVector4Make(d.z, 0 , -d.x, acos(d.y/length))
                bondNode.position = (point_a + point_b) * 0.5
                bondNode.setValue(atom_a, forUndefinedKey: "atom_a")
                bondNode.setValue(atom_b, forUndefinedKey: "atom_b")
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
            if url.pathExtension == "pdf" {
                let myView = NSImageView(frame: self.bounds)
                myView.image = self.snapshot()
                let pdfdata = myView.dataWithPDF(inside: self.bounds)
                try pdfdata.write(to: url, options: .atomic)

            }
            else if url.pathExtension == "png" {
                let pngdata = NSBitmapImageRep(data: self.snapshot().tiffRepresentation!)!.representation(using: .png, properties: [:])!
                try pngdata.write(to: url, options: .atomic)
            }
            success = true
        } catch {
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
        if let pov = self.pointOfView {
            for eachatom in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
                let name = eachatom.name!
                let p = pov.convertPosition(eachatom.position, from: nil)
                let radius = (eachatom.geometry as! SCNSphere).radius
                var texture_name = "Default"
                if let node_texture_name = eachatom.geometry!.firstMaterial?.value(forUndefinedKey: "texture_name") as? String {
                    texture_name = node_texture_name
                }
                var bsdf_name = name + "-" + texture_name
                // Store the atom's color in bsdfs
                if !known_bsdfs.contains(bsdf_name){
                    known_bsdfs.insert(bsdf_name)
                    let color = eachatom.geometry!.firstMaterial?.multiply.contents as! NSColor
                    let r = color.redComponent
                    let g = color.greenComponent
                    let b = color.blueComponent
                    var bsdf = NSDictionary()
                    if texture_name == "Metal" {
                        bsdf = [
                            "name": bsdf_name,
                            "albedo": [r, g, b],
                            "type": "rough_conductor",
                            "material": "Al",
                        ]
                    } else if texture_name == "Mirror" {
                        bsdf = [
                            "name": bsdf_name,
                            "albedo": [r, g, b],
                            "type": "mirror",
                        ]
                    } else {
                        // default texture
                        bsdf = [
                            "name": bsdf_name,
                            "albedo": 1.0,
                            "type": "plastic",
                            "ior": 1.3,
                            "thickness": 1.0,
                            "sigma_a": [1-r, 1-g, 1-b],
                        ]
                    }
                    bsdfs.append(bsdf)
                }
                // create new bsdf for transparent atoms
                if eachatom.opacity < 1.0 {
                    let new_bsdf_name = bsdf_name + "_trans"
                    if !known_bsdfs.contains(new_bsdf_name) {
                        known_bsdfs.insert(new_bsdf_name)
                        let bsdf_trans : NSDictionary = [
                            "name": new_bsdf_name,
                            "albedo": 1.0,
                            "type": "transparency",
                            "base": bsdf_name,
                            "alpha": 0.5
                        ]
                        bsdfs.append(bsdf_trans)
                    }
                    // replace the bsdf_name so it's used later in primitives
                    bsdf_name = new_bsdf_name
                }
                let primitive : NSDictionary = [
                    "name": name,
                    "transform": [
                        "position": [p.x, p.y, p.z],
                        "scale": radius
                    ],
                    "type": "sphere",
                    "bsdf": bsdf_name
                ]
                primitives.append(primitive)
                // record the lowest y
                lowest_y = min(lowest_y, p.y)
                lowest_z = min(lowest_z, p.z)
            }
            // add the bonds
            if self.moleculeNode.childNodes.contains(self.bondnodes) {
                for eachbond in self.normalbondnode.childNodes + self.selectedbondnode.childNodes {
                    let v1 = eachbond.boundingBox.min
                    let v2 = eachbond.boundingBox.max
                    let radius = abs(v2.x-v1.x)
                    let length = abs(v2.y-v1.y)
                    let p = pov.convertPosition(eachbond.position, from: nil)
                    let name = "bond"
                    let bond_up = pov.convertVector(SCNVector3(0, 1, 0), from: eachbond)
                    // old way of defining rotation
                    // let rotation = convert_tungsten_rotation(rotation: eachbond.eulerAngles)
                    // add bsdf (texture)
                    var texture_name = "Default"
                    if let node_texture_name = eachbond.geometry!.firstMaterial?.value(forUndefinedKey: "texture_name") as? String {
                        texture_name = node_texture_name
                    }
                    var bsdf_name = name + "-" + texture_name
                    if !known_bsdfs.contains(bsdf_name){
                        known_bsdfs.insert(bsdf_name)
                        let color = eachbond.geometry!.firstMaterial?.multiply.contents as! NSColor
                        let r = color.redComponent
                        let g = color.greenComponent
                        let b = color.blueComponent
                        var bsdf = NSDictionary()
                        if texture_name == "Metal" {
                            bsdf = [
                                "name": bsdf_name,
                                "albedo": [r, g, b],
                                "type": "rough_conductor",
                                "material": "Al",
                            ]
                        } else if texture_name == "Mirror" {
                            bsdf = [
                                "name": bsdf_name,
                                "albedo": [r, g, b],
                                "type": "mirror",
                            ]
                        } else {
                            // default bond texture
                            bsdf = [
                                "name": bsdf_name,
                                "albedo": 1.0,
                                "type": "rough_plastic",
                                "ior": 1.3,
                                "thickness": 1.0,
                                "sigma_a": 0.7,
                                "roughness": 0.1
                            ]
                        }
                        bsdfs.append(bsdf)
                    }
                    // create new bsdf for transparent atoms
                    if eachbond.opacity < 1.0 {
                        let new_bsdf_name = bsdf_name + "_trans"
                        if !known_bsdfs.contains(new_bsdf_name) {
                            known_bsdfs.insert(new_bsdf_name)
                            let bsdf_trans : NSDictionary = [
                                "name": new_bsdf_name,
                                "albedo": 1.0,
                                "type": "transparency",
                                "base": bsdf_name,
                                "alpha": 0.5
                            ]
                            bsdfs.append(bsdf_trans)
                        }
                        // replace the bsdf_name so it's used later in primitives
                        bsdf_name = new_bsdf_name
                    }
                    // add primitive for bond
                    let prim_bond : NSDictionary = [
                        "name": name,
                        "transform": [
                            "position": [p.x, p.y, p.z],
                            "scale": [radius, length, radius],
                            "up": [bond_up.x, bond_up.y, bond_up.z],
                        ],
                        "type": "cylinder",
                        "bsdf": bsdf_name
                    ]
                    primitives.append(prim_bond)
                }
            }
            
            // Set the camera
            let p = SCNVector3(0,0,0)
            let p1 = SCNVector3(0,0,-11)
            let p_up = SCNVector3(0,1,0)
            let res_w = self.appdelegate.menu_high_reso.state == .on ? self.bounds.width * 2 : self.bounds.width
            let res_h = self.appdelegate.menu_high_reso.state == .on ? self.bounds.height * 2 : self.bounds.height
            let camera: NSDictionary = ["tonemap": "filmic",
                                        "resolution": [res_w, res_h],
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
                                         "emission": 0.5,
                                         "sample": true]
            primitives.append(envmap)
            
            // Add the floor
            let pf = SCNVector3(0, lowest_y-1, 0)
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
            let p_wall = SCNVector3(0, 0, lowest_z-5)
            let w_up = SCNVector3(0, 0, 1)
            let wall : NSDictionary = [ "name": "Wall",
                                        "transform": ["position" : [p_wall.x, p_wall.y, p_wall.z],
                                                      "up" : [w_up.x, w_up.y, w_up.z],
                                                      "scale": 100.0],
                                        "type": "quad",
                                        "bsdf": "Floor"]
            
            primitives.append(wall)
            // Add a spotlight directed from top to bottom
            let plight = SCNVector3(0, 50, 0)
            let spotlight: NSDictionary = ["name": "SpotLight",
                                           "transform": ["position": [plight.x, plight.y, plight.z],
                                                         "scale": 5],
                                           "type": "sphere",
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
        if theEvent.clickCount == 1 {
            self.selectNodes(with: theEvent)
        } else if theEvent.clickCount == 2 {
            self.reset_selection()
            self.selectNodes(with: theEvent)
            self.select_all_bonded()
        }
        super.mouseDown(with: theEvent)
    }
    
    func selectNodes(with theEvent: NSEvent) {
        let hitResults = hitTest(theEvent.locationInWindow, options: nil)
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let hitnode = hitResults[0].node
            if let parentNode = hitnode.parent {
                if parentNode == self.normalatomnode {
                    hitnode.removeFromParentNode()
                    self.addBlinkAnimation(node: hitnode)
                    self.selectedatomnode.addChildNode(hitnode)
                }
                else if parentNode == self.selectedatomnode {
                    hitnode.removeFromParentNode()
                    self.removeBlinkAnimation(node: hitnode)
                    self.normalatomnode.addChildNode(hitnode)
                }
                else if parentNode == self.normalbondnode {
                    hitnode.removeFromParentNode()
                    self.addBlinkAnimation(node: hitnode)
                    self.selectedbondnode.addChildNode(hitnode)
                }
                else if parentNode == self.selectedbondnode {
                    hitnode.removeFromParentNode()
                    self.removeBlinkAnimation(node: hitnode)
                    self.normalbondnode.addChildNode(hitnode)
                }
            }
        }
        // make sure the control angle is consistent with view angle
        // putting the below function in mouseUp() will cause the pov jump a little
        if let pov = self.pointOfView {
            self.defaultCameraController.worldUp = pov.worldUp
        }
    }
    
    
    override func mouseDragged(with theEvent: NSEvent) {
        // set lightnode as childnode of cameranode, and set cameranode to follow the pointofview
        if let current_transform = self.pointOfView?.transform {
            self.cameraNode.transform = current_transform
        }
        super.mouseDragged(with: theEvent)
    }
    
    
    override func mouseUp(with theEvent: NSEvent) {
        // print info bar
        self.update_info_bar()
        super.mouseUp(with: theEvent)
    }
    
    func update_info_bar() {
        var info_str : String = ""
        // print atom name (only one)
        if self.selectedatomnode.childNodes.count == 1 && self.selectedbondnode.childNodes.count == 0 {
            let node = self.selectedatomnode.childNodes[0]
            let index = node.value(forUndefinedKey: "atom_index") as! Int
            let elem = node.name!
            let name = node.value(forUndefinedKey: "atom_name") as! String
            let indexStr = index >= 0 ? String(index) : ""
            info_str = String(format: "Atom %@ %@: %@ %@", indexStr, name, elem, node.position.stringValue)
        }
        // print bond length (only one)
        else if self.selectedbondnode.childNodes.count == 1 && self.selectedatomnode.childNodes.count == 0 {
            let bond_node = self.selectedbondnode.childNodes[0]
            let atom_a = bond_node.value(forUndefinedKey: "atom_a") as! SCNNode
            let atom_b = bond_node.value(forUndefinedKey: "atom_b") as! SCNNode
            let a_start = atom_a.position
            let a_end = atom_b.position
            let length = a_start.distance(a_end)
            info_str = String(format: "Bond %@-%@: R = %.5f Å", atom_a.name!, atom_b.name!, length)
        }
        // print bond angles (if two connected bonds are selected)
        else if self.selectedbondnode.childNodes.count == 2 {
            let bond_a = self.selectedbondnode.childNodes[0]
            let bond_b = self.selectedbondnode.childNodes[1]
            // compute the starting and ending point of the bonds
            let a_start = (bond_a.value(forUndefinedKey: "atom_a") as! SCNNode).position
            let a_end = (bond_a.value(forUndefinedKey: "atom_b") as! SCNNode).position
            let b_start = (bond_b.value(forUndefinedKey: "atom_a") as! SCNNode).position
            let b_end = (bond_b.value(forUndefinedKey: "atom_b") as! SCNNode).position
            let a_vector : float3 = float3(a_start - a_end)
            let b_vector : float3 = float3(b_start - b_end)
            let a_length = a_start.distance(a_end)
            let b_length = b_start.distance(b_end)
            let theta = acos(dot(a_vector,b_vector)/Float(a_length * b_length)) / .pi * 180.0
            if a_start ~= b_start || a_end ~= b_end {
                info_str = String(format: "θ = %.4f°", theta)
            }
            else if a_start ~= b_end || a_end ~= b_start {
                info_str = String(format: "θ = %.4f°", 180-theta)
            }
            else {
                info_str = "Right click to deselect all"
            }
        }
        // print dihedral angle ( if three connected bonds are selected)
        else if self.selectedbondnode.childNodes.count == 3 {
            // put the nodes ends into an array
            var bond_ends : [(SCNVector3, SCNVector3)] = []
            for thisbond in self.selectedbondnode.childNodes {
                let start = (thisbond.value(forUndefinedKey: "atom_a") as! SCNNode).position
                let end = (thisbond.value(forUndefinedKey: "atom_b") as! SCNNode).position
                bond_ends.append((start, end))
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
                //let gamma = acos(dot(Uab,Ubc)/(length(Uab)*length(Ubc))) / .pi * 180.0
                // better formula from https://en.wikipedia.org/wiki/Dihedral_angle
                let gamma = atan2(dot(cross(Uab, Ubc), b_vector) / length(b_vector), dot(Uab, Ubc)) / .pi * 180.0
                info_str = String(format: "Γ = %.4f°", gamma)
            } // end of print dihedral
            else {
                info_str = "Right click to deselect all"
            }
        // print distance between to atoms even if not bonded
        } else if self.selectedbondnode.childNodes.count == 0 && self.selectedatomnode.childNodes.count == 2 {
            let atom_a = self.selectedatomnode.childNodes[0]
            let atom_b = self.selectedatomnode.childNodes[1]
            let a_start = atom_a.position
            let a_end = atom_b.position
            let length = a_start.distance(a_end)
            info_str = String(format: "Distance %@-%@: R = %.5f Å", atom_a.name!, atom_b.name!, length)
        }
        else if self.selectedatomnode.childNodes.count + self.selectedbondnode.childNodes.count > 1 {
            info_str = "Right click to deselect all"
        }
        if info_str != "" {
            self.view_controller.info_bar.stringValue = info_str
        }
    }
    
    // This function is not used any more, because we now store the bond start and end nodes explicitly
//    func compute_bond_ends(bondnode : SCNNode) -> (start: SCNVector3, end:SCNVector3) {
//        // read cylinder infomation from bondnode
//        let center = bondnode.position
//        let x = bondnode.rotation.x
//        let z = bondnode.rotation.z
//        let w = bondnode.rotation.w
//        // get the half vector length
//        let cylinder = bondnode.geometry as! SCNCylinder
//        let r = cylinder.height * 0.5
//        // start compute bond vector
//        // explaination: the half bond vector bv was rotated from (0,1,0), along (x,0,z) axis by w angle
//        // bv project on y axis = r * cos(w)
//        // bv project on the xz plain has length r * sin(w)
//        // bv project on xz plain has angle of (x,0,z) axis rotated by 90 degree clockwise ->  (-z,x)
//        let dx = r * sin(w) * (-z / sqrt(z*z+x*x))
//        let dy = r * cos(w)
//        let dz = r * sin(w) * (x / sqrt(z*z+x*x))
//        let dr = SCNVector3Make(dx, dy, dz)
//        let starting_point = center + dr
//        let ending_point = center - dr
//        return (starting_point, ending_point)
//    }
    
    override func scrollWheel(with event: NSEvent) {
        // this is the only way I found to detect if it's a mouse
        if event.deviceID > 0 {
            super.scrollWheel(with: event)
        } else if let pov = self.pointOfView {
            let rel_pos = pov.convertPosition(self.mol_center_pos, from: nil)
            self.camera_distance = abs(rel_pos.z)
            let speed = max(0.2, self.camera_distance * 0.05)
            pov.position += pov.convertVector(SCNVector3(0, 0, speed * event.deltaY), to: nil)
        }
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        self.reset_selection()
        self.click_location = theEvent.locationInWindow
        if let pov = self.pointOfView {
            // record the click location for drag
            self.p_pov = pov.position
            // compute the distance of camera (for adjusting shift speed)
            let rel_pos = pov.convertPosition(self.mol_center_pos, from: nil)
            self.camera_distance = abs(rel_pos.z)
        }
        super.rightMouseDown(with: theEvent)
    }
    
    override func rightMouseDragged(with theEvent: NSEvent) {
        // allows rightmouse drag the view
        //super.scrollWheel(with: theEvent)
        let point = theEvent.locationInWindow
        let dx = point.x - click_location.x
        let dy = point.y - click_location.y
        if let pov = self.pointOfView {
            let move_speed = 0.001 * max(2.0, self.camera_distance)
            let shift = pov.convertVector(SCNVector3(dx * move_speed, dy * move_speed, 0), to: nil)
            pov.position = self.p_pov - shift
        }
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
    
    /** select all atoms and bonds that are bonded to the selected nodes */
    func select_all_bonded() {
        // counts
        let n_normal_atoms = self.normalatomnode.childNodes.count
        let n_selected_atoms = self.selectedatomnode.childNodes.count
        let n_atoms = n_normal_atoms + n_selected_atoms
        let n_normal_bonds = self.normalbondnode.childNodes.count
        let n_selected_bonds = self.selectedbondnode.childNodes.count
        let n_bonds = n_normal_bonds + n_selected_bonds
        // return if no nodes are selected
        if n_selected_atoms == 0 && n_selected_bonds == 0 {
            return
        }
        // build an index map between atoms and bonds
        let all_atom_nodes = self.normalatomnode.childNodes + self.selectedatomnode.childNodes
        let all_bond_nodes = self.normalbondnode.childNodes + self.selectedbondnode.childNodes
        var atoms_for_bond: [Bond] = []
        var bonds_for_atom : [[Int]] = Array(repeating: [], count: n_atoms)
        for (i_bond, bond_node) in all_bond_nodes.enumerated() {
            let atom_a = bond_node.value(forUndefinedKey: "atom_a") as! SCNNode
            let atom_b = bond_node.value(forUndefinedKey: "atom_b") as! SCNNode
            if let idx_a = all_atom_nodes.firstIndex(of: atom_a), let idx_b = all_atom_nodes.firstIndex(of: atom_b) {
                atoms_for_bond.append(Bond(idx_a, idx_b))
                bonds_for_atom[idx_a].append(i_bond)
                bonds_for_atom[idx_b].append(i_bond)
            // dangling bonds may only have one atom connected
            } else if let idx_a = all_atom_nodes.firstIndex(of: atom_a) {
                atoms_for_bond.append(Bond(idx_a, -1))
                bonds_for_atom[idx_a].append(i_bond)
            } else if let idx_b = all_atom_nodes.firstIndex(of: atom_b) {
                atoms_for_bond.append(Bond(idx_b, -1))
                bonds_for_atom[idx_b].append(i_bond)
            } else {
                // add a fake atom index of no atoms are bonded
                atoms_for_bond.append(Bond(-1, -1))
            }
        }
        // list of selected atoms and selected bonds
        var selected_atom_idxs: Set<Int> = Set(n_normal_atoms ..< n_atoms)
        var selected_bond_idxs: Set<Int> = Set(n_normal_bonds ..< n_bonds)
        // keep track of newly selected atoms and bonds
        var new_atoms = selected_atom_idxs
        var new_bonds = selected_bond_idxs
        while new_atoms.count > 0 || new_bonds.count > 0 {
            var next_new_atoms = Set<Int>()
            var next_new_bonds = Set<Int>()
            // select all bonds connected to new atoms
            for atom_idx in new_atoms {
                for bond_idx in bonds_for_atom[atom_idx] {
                    if !selected_bond_idxs.contains(bond_idx) {
                        next_new_bonds.insert(bond_idx)
                    }
                }
            }
            // select all atoms connectes to new bonds
            for bond_idx in new_bonds {
                let bond = atoms_for_bond[bond_idx]
                if bond.first >= 0 && !selected_atom_idxs.contains(bond.first) {
                    next_new_atoms.insert(bond.first)
                }
                if bond.second >= 0 && !selected_atom_idxs.contains(bond.second) {
                    next_new_atoms.insert(bond.second)
                }
            }
            new_atoms = next_new_atoms
            new_bonds = next_new_bonds
            // add the new selected
            selected_atom_idxs.formUnion(next_new_atoms)
            selected_bond_idxs.formUnion(next_new_bonds)
        }
        // remove current selected
        self.reset_selection()
        // select new atoms and bonds
        for atom_idx in selected_atom_idxs {
            let atom_node = all_atom_nodes[atom_idx]
            atom_node.removeFromParentNode()
            self.addBlinkAnimation(node: atom_node)
            self.selectedatomnode.addChildNode(atom_node)
        }
        for bond_idx in selected_bond_idxs {
            let bond_node = all_bond_nodes[bond_idx]
            bond_node.removeFromParentNode()
            self.addBlinkAnimation(node: bond_node)
            self.selectedbondnode.addChildNode(bond_node)
        }
    }
    
    func addBlinkAnimation(node: SCNNode) {
        let material = node.geometry!.firstMaterial!
        let animation = CABasicAnimation(keyPath: "intensity")
        animation.fromValue = 0.0
        animation.toValue = 2.0
        animation.duration = 1.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        material.diffuse.addAnimation(animation, forKey: "blink")
    }
    
    func removeBlinkAnimation(node: SCNNode) {
        let material = node.geometry!.firstMaterial!
        material.removeAnimation(forKey: "blink")
    }
    
    func auto_add_bond(bonds: [Bond]? = nil) {
        // check every pair of atoms to determine if a bond need to be added
        let all_atom_nodes = self.normalatomnode.childNodes + self.selectedatomnode.childNodes
        var bonds_to_use : [Bond] = []
        if let input_bonds = bonds {
            // use input bonds
            bonds_to_use = input_bonds
        } else {
            // check every pair of atoms to determine if a bond need to be added
            bonds_to_use = self.compute_bonds(nodes: all_atom_nodes)
        }
        for bond in bonds_to_use {
            let i = bond.first, j = bond.second
            let atom_a = all_atom_nodes[i]
            let atom_b = all_atom_nodes[j]
            // build cylinder nodes for bonds
            let bond_length = atom_a.position.distance(atom_b.position)
            let bondGeometry = SCNCylinder(radius: self.dict_bond_thickness, height: bond_length)
            bondGeometry.radialSegmentCount = self.renderSegmentCount
            bondGeometry.firstMaterial?.multiply.contents = self.dict_bond_color
            let bondNode = SCNNode(geometry: bondGeometry)
            self.apply_texture(bondNode, self.current_texture)
            bondNode.setValue(atom_a, forUndefinedKey: "atom_a")
            bondNode.setValue(atom_b, forUndefinedKey: "atom_b")
            self.normalbondnode.addChildNode(bondNode)
        }
        // The locations of the bond nodes are adjusted here
        self.update_bond_nodes()
    }
    
    func update_bond_nodes() {
        for node in self.normalbondnode.childNodes + self.selectedbondnode.childNodes {
            if let atom_a = node.value(forUndefinedKey: "atom_a") as? SCNNode {
                if let atom_b = node.value(forUndefinedKey: "atom_b") as? SCNNode {
                    let point_a = atom_a.position
                    let point_b = atom_b.position
                    let d = point_b - point_a
                    let length = d.length()
                    let geometry = node.geometry as! SCNCylinder
                    // this step is expensive in rendering, so we try to avoid it
                    if abs(geometry.height - length) > 0.3 {
                        geometry.height = length
                    }
                    // the rotation axis (0,1,0)*(dx, dy, dz) = (dz, 0, dx)
                    // the rotation angle θ = arccos( (0,1,0).(dx, dy, dz)/|(dx, dy, dz)|)
                    node.rotation = SCNVector4Make(d.z, 0 , -d.x, acos(d.y/length))
                    node.position = (point_a + point_b) * 0.5
                }
            }
        }
    }
    
    func compute_bonds(nodes: [SCNNode]) -> [Bond]{
        if nodes.count < 2 {
            return []
        }
        let maxDist = max(self.max_bond_length, 5.0) as CGFloat
        // collect the min and max of all coords
        var minX = CGFloat.greatestFiniteMagnitude, minY = CGFloat.greatestFiniteMagnitude, minZ = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude, maxY = -CGFloat.greatestFiniteMagnitude, maxZ = -CGFloat.greatestFiniteMagnitude
        for i in 0 ..< nodes.count {
            let pos = nodes[i].position
            minX = min(minX, pos.x)
            minY = min(minY, pos.y)
            minZ = min(minZ, pos.z)
            maxX = max(maxX, pos.x)
            maxY = max(maxY, pos.y)
            maxZ = max(maxZ, pos.z)
        }
        // create a 3D grid box
        let dimX = Int((maxX - minX) / maxDist) + 1
        let dimY = Int((maxY - minY) / maxDist) + 1
        let dimZ = Int((maxZ - minZ) / maxDist) + 1
        var box3D = Array(repeating: Array(repeating: Array(repeating: [Int](), count: dimZ), count: dimY), count: dimX)
        // put atom node's index into box
        for i in 0 ..< nodes.count {
            let pos = nodes[i].position
            let idX = Int((pos.x - minX) / maxDist)
            let idY = Int((pos.y - minY) / maxDist)
            let idZ = Int((pos.z - minZ) / maxDist)
            box3D[idX][idY][idZ].append(i)
        }
        // loop over box and add bonds for atoms in same and neighboring boxes
        var bonds = [Bond]()
        for bx in 0 ..< dimX {
            for by in 0 ..< dimY {
                for bz in 0 ..< dimZ {
                    let nodeIdxs = box3D[bx][by][bz]
                    // build bonds inside box
                    for i in 0 ..< nodeIdxs.count {
                        let idx_I = nodeIdxs[i]
                        let atom_I = nodes[idx_I]
                        let name_I = atom_I.name!
                        let pos_I = atom_I.position
                        for j in i+1 ..< nodeIdxs.count {
                            let idx_J = nodeIdxs[j]
                            let atom_J = nodes[idx_J]
                            let name_J = atom_J.name!
                            let pos_J = atom_J.position
                            let lenSq = (pos_I - pos_J).lengthSq()
                            let max_bond_length = self.get_max_bond_length(name_I, name_J)
                            if lenSq < max_bond_length * max_bond_length {
                                let bond = Bond(idx_I, idx_J)
                                bonds.append(bond)
                            }
                        }
                    }
                    // build bonds between box
                    var neighbors = [(Int, Int, Int)]()
                    for dx in 0 ... 1 {
                        let nx = bx + dx
                        if nx >= 0 && nx < dimX {
                            for dy in -1 ... 1 {
                                let ny = by + dy
                                if ny >= 0 && ny < dimY {
                                    for dz in -1 ... 1 {
                                        let nz = bz + dz
                                        if nz >= 0 && nz < dimZ {
                                            let ngbor = (nx, ny, nz)
                                            if ngbor > (bx, by, bz) {
                                                neighbors.append(ngbor)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    for i in 0 ..< nodeIdxs.count {
                        let idx_I = nodeIdxs[i]
                        let atom_I = nodes[idx_I]
                        let name_I = atom_I.name!
                        let pos_I = atom_I.position
                        for (nx, ny, nz) in neighbors{
                            let neiborNodeIdxs = box3D[nx][ny][nz]
                            for j in 0 ..< neiborNodeIdxs.count {
                                let idx_J = neiborNodeIdxs[j]
                                let atom_J = nodes[idx_J]
                                let name_J = atom_J.name!
                                let pos_J = atom_J.position
                                let lenSq = (pos_I - pos_J).lengthSq()
                                let max_bond_length = self.get_max_bond_length(name_I, name_J)
                                if lenSq < max_bond_length * max_bond_length {
                                    let bond = Bond(idx_I, idx_J)
                                    bonds.append(bond)
                                }
                            }
                        }
                    }
                }
            }
        }
        return bonds
    }
    
    func reset_bond_nodes() {
        // original implementation:
        // remove all existing bonds
//        for node in self.normalbondnode.childNodes + self.selectedbondnode.childNodes {
//            node.removeFromParentNode()
//        }
//        self.auto_add_bond()
        // Improved implementation, be smart at which bond to delete and insert
        let all_atom_nodes = self.normalatomnode.childNodes + self.selectedatomnode.childNodes
        var atom_idx_map: [SCNNode: Int] = [:]
        for (index, node) in all_atom_nodes.enumerated() {
            atom_idx_map[node] = index
        }
        
        // compute new bonds
        let bonds = self.compute_bonds(nodes: all_atom_nodes)
        var new_bonds_set: Set<Bond> = Set(bonds)
        // check to remove old bonds
        for bond_node in self.normalbondnode.childNodes + self.selectedbondnode.childNodes {
            let atom_a = bond_node.value(forUndefinedKey: "atom_a") as! SCNNode
            let atom_b = bond_node.value(forUndefinedKey: "atom_b") as! SCNNode
            var keep_bond = false
            if let bond_i = atom_idx_map[atom_a] {
                if let bond_j = atom_idx_map[atom_b] {
                    let bond = Bond(bond_i, bond_j)
                    if new_bonds_set.contains(bond) {
                        new_bonds_set.remove(bond)
                        keep_bond = true
                    }
                }
            }
            if !keep_bond {
                bond_node.removeFromParentNode()
            }
        }
        // add new bonds
        for bond in new_bonds_set {
            let i = bond.first, j = bond.second
            let atom_a = all_atom_nodes[i]
            let atom_b = all_atom_nodes[j]
            // build cylinder nodes for bonds
            let bond_length = atom_a.position.distance(atom_b.position)
            let bondGeometry = SCNCylinder(radius: self.dict_bond_thickness, height: bond_length)
            bondGeometry.radialSegmentCount = self.renderSegmentCount
            bondGeometry.firstMaterial?.multiply.contents = self.dict_bond_color
            let bondNode = SCNNode(geometry: bondGeometry)
            self.apply_texture(bondNode, self.current_texture)
            bondNode.setValue(atom_a, forUndefinedKey: "atom_a")
            bondNode.setValue(atom_b, forUndefinedKey: "atom_b")
            self.normalbondnode.addChildNode(bondNode)
        }
        self.update_bond_nodes()
    }
    
    func get_max_bond_length(_ elem_a: String, _ elem_b: String) -> CGFloat {
        // cache the results to improve the performance a little bit
        let cache_key = elem_a + "_" + elem_b
        if let res = self.known_bond_length[cache_key] {
            return res
        }
        // default max bond length if not found
        var result : CGFloat = 2.0
        if let elem_a_idx = ElementsIdxDict[elem_a], let elem_b_idx = ElementsIdxDict[elem_b] {
            if let value = self.dict_element_max_distance[Bond(elem_a_idx, elem_b_idx)] {
                result = value
            }
        }
        self.known_bond_length[cache_key] = result
        return result
    }
    
    func open_file(url: URL?) {
        if let path = url?.path {
            if path.pathExtension == "dae" {
                let success = self.init_with_dae(url: url!)
                if success {
                    self.view_controller.info_bar.stringValue = path.lastPathComponent
                    // Add the succesfully opened file to "Open Recent" menu
                    NSDocumentController.shared.noteNewRecentDocumentURL(url!)
                    self.update_traj_length(length: 0)
                }
                else {
                    self.view_controller.info_bar.stringValue = "File " + path + " not recognized"
                }
            }
            else {
                var input = Molecule()
                self.view_controller.show_progress(nFinished: 0, total: 1, title: "Reading File", delay: 0.2)
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    var success = false
                    do {
                        input = try Molecule(path: path)
                    } catch {
                        success = false
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        if input.atomlist.count > 0 {
                            self.init_scene()
                            self.renderSegmentCount = max(20, Int(50-input.atomlist.count/30))
                            for atom in input.atomlist {
                                self.add_atom(atom)
                            }
                            // set the trajectory length
                            self.update_traj_length(length: input.traj_length)
                            self.auto_add_bond(bonds: input.bonds)
                            self.adjust_focus()
                            success = true
                        }
                        if success {
                            self.view_controller.info_bar.stringValue = path.lastPathComponent
                            // Add the succesfully opened file to "Open Recent" menu
                            NSDocumentController.shared.noteNewRecentDocumentURL(url!)
                        }
                        else {
                            self.view_controller.info_bar.stringValue = "File " + path + " not recognized"
                        }
                        self.view_controller.hide_progress()
                    }
                }
            }
        }
    }
    
    func load_from_text(text: String, unit: String? = nil) {
        let molecule = Molecule(text: text, unit: unit)
        if molecule.atomlist.count > 0 {
            self.init_scene()
            self.renderSegmentCount = max(20, Int(50 - molecule.atomlist.count/30))
            for atom in molecule.atomlist {
                self.add_atom(atom)
            }
            // set the trajectory length
            self.update_traj_length(length: molecule.traj_length)
            self.auto_add_bond(bonds: molecule.bonds)
            self.adjust_focus()
            self.view_controller.info_bar.stringValue = "Loaded from text"
        } else {
            self.view_controller.info_bar.stringValue = "Text not recognized"
        }
    }
    
    func toggleAdvancedRendering(enable: Bool) {
        if enable != self.advancedRendering {
            self.advancedRendering = enable
            let all_nodes = self.normalatomnode.childNodes + self.selectedatomnode.childNodes +
                self.normalbondnode.childNodes + self.selectedbondnode.childNodes
            if self.advancedRendering == true {
                for node in all_nodes {
                    if let material = node.geometry?.firstMaterial {
                        material.lightingModel = .physicallyBased
                    }
                }
                // update lightingEnvironment
                self.scene?.lightingEnvironment.contents = NSImage(named: "envmap2.jpg")
                self.scene?.lightingEnvironment.intensity = 2.0
                self.ambientLightNode.removeFromParentNode()
            } else {
                for node in all_nodes {
                    if let material = node.geometry?.firstMaterial {
                        material.lightingModel = .blinn
                    }
                }
                self.scene?.lightingEnvironment.contents = nil
                self.scene?.rootNode.addChildNode(self.ambientLightNode)
            }
        }
    }
    
    func toggleBackgroundImage(show: Bool) {
        if show {
            self.scene?.background.contents = NSImage(named: "envmap2-blur.jpg")
        } else {
            self.scene?.background.contents = nil
        }
    }
    
    func change_texture(texture: Texture) {
        var all_nodes = self.selectedatomnode.childNodes + self.selectedbondnode.childNodes
        if all_nodes.count == 0 {
            all_nodes = self.normalatomnode.childNodes + self.normalbondnode.childNodes
            // store the texture if all nodes use that
            self.current_texture = texture
            self.appdelegate.update_default_texture(texture: texture)
        }
        for node in all_nodes {
            self.apply_texture(node, texture)
        }
    }
    
    func apply_texture(_ node: SCNNode, _ texture: Texture) {
        if let material = node.geometry?.firstMaterial {
            material.diffuse.contents = texture.diffuse
            material.normal.contents = texture.normal
            material.roughness.contents = texture.roughness
            material.metalness.contents = texture.metalness
            material.fresnelExponent = texture.fresnelExponent
            material.lightingModel = self.advancedRendering ? .physicallyBased : .blinn
            material.setValue(texture.name, forUndefinedKey: "texture_name")
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
                let url = URL(fileURLWithPath: path)
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
        if total_number_of_atoms > 0 {
            var sumx = 0.0 as CGFloat, sumy = 0.0 as CGFloat, sumz = 0.0 as CGFloat
            var maxz = -CGFloat.greatestFiniteMagnitude
            // get average and standard deviation of all atoms' position
            for eachnode in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
                sumx += eachnode.position.x
                sumy += eachnode.position.y
                sumz += eachnode.position.z
                maxz = max(maxz, eachnode.position.z)
            }
            let ave_x = sumx / CGFloat(total_number_of_atoms)
            let ave_y = sumy / CGFloat(total_number_of_atoms)
            let ave_z = sumz / CGFloat(total_number_of_atoms)
            // adjust camara position
            if let pov = self.pointOfView {
                pov.position = SCNVector3(x: ave_x, y: ave_y, z: maxz+11)
                pov.eulerAngles = SCNVector3(0, 0, 0)
                self.cameraNode.transform = pov.transform
            }
            // store center position
            self.mol_center_pos = SCNVector3(ave_x, ave_y, ave_z)
            // in OSX 10.13, the camera target is not automatically adjusted, so we manually do that here
            self.defaultCameraController.target = self.mol_center_pos
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
        self.adjust_focus()
    }
    
    func toggleRotateAnimation() {
        if self.moleculeNode.action(forKey: "rot") != nil {
            self.moleculeNode.removeAction(forKey: "rot")
        } else {
            if let pov = self.pointOfView {
                // shift the pivot of moleculeNode to the center of all atoms
                var sumx=0.0 as CGFloat, sumy=0.0 as CGFloat, sumz=0.0 as CGFloat
                var total_number_of_atoms = 0.0 as CGFloat
                for eachnode in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
                    sumx += eachnode.position.x
                    sumy += eachnode.position.y
                    sumz += eachnode.position.z
                    total_number_of_atoms += 1
                }
                let ave_x = sumx / total_number_of_atoms
                let ave_y = sumy / total_number_of_atoms
                let ave_z = sumz / total_number_of_atoms
                let pivot = SCNMatrix4MakeTranslation(ave_x, ave_y, ave_z)
                self.moleculeNode.pivot = pivot
                self.moleculeNode.position = SCNVector3(ave_x, ave_y, ave_z)
                // create rotation around the pivot pointing to "up"
                let p_up = pov.convertVector(SCNVector3(0,1,0), to: nil)
                let rotateAction = SCNAction.rotate(by: .pi*2, around: p_up, duration: 10)
                let repeatAction = SCNAction.repeatForever(rotateAction)
                self.moleculeNode.runAction(repeatAction, forKey: "rot")
            }
        }
    }
    
    func update_traj_length(length: Int) {
        self.traj_length = length
        if length > 1 {
            self.view_controller.toolbox.isHidden = false
            self.view_controller.slider.maxValue = Double(length-1)
            self.appdelegate.menu_trajectory.isHidden = false
        } else {
            self.view_controller.toolbox.isHidden = true
            self.appdelegate.menu_trajectory.isHidden = true
        }
    }
    
    func choose_frame(frame: Int) {
        let valid_frame = min(max(frame, 0), self.traj_length-1)
        if self.traj_length > 0 {
            for atomnode in self.normalatomnode.childNodes + self.selectedatomnode.childNodes {
                let traj : [SCNVector3] = atomnode.value(forUndefinedKey: "trajectory") as! [SCNVector3]
                atomnode.position = traj[valid_frame]
            }
            if appdelegate.menu_traj_update_bonds.state == .on {
                self.reset_bond_nodes()
            } else {
                self.update_bond_nodes()
            }            
            self.update_info_bar()
            // update UI components
            self.view_controller.slider.integerValue = valid_frame
            self.view_controller.slider_text.integerValue = valid_frame
            // store current frame
            self.current_frame = valid_frame
        }
    }
    
    func next_frame() {
        let current_frame = self.view_controller.slider.integerValue
        let next_frame = (current_frame + 1) % self.traj_length
        self.choose_frame(frame: next_frame)
    }
    
} // end of class



