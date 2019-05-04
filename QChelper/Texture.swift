//
//  Texture.swift
//  QCdraw
//
//  Created by Yudong Qiu on 5/4/19.
//  Copyright © 2019 QYD. All rights reserved.
//

import Foundation
import SceneKit

struct Texture {
    var name : String
    var diffuse: Any = 1.0
    var normal: Any = 0.0
    var roughness: Any = 0.0
    var metalness: Any = 0.0
    var fresnelExponent: CGFloat = 0.0
    init (name: String, diffuse: Any = 1.0, normal: Any = 1.0, roughness: Any = 0.0, metalness: Any = 0.0, fresnelExponent: CGFloat = 0.0) {
        self.name = name
        self.diffuse = diffuse
        self.normal = normal
        self.roughness = roughness
        self.metalness = metalness
        self.fresnelExponent = fresnelExponent
    }
}

let defaultTexture = Texture(name: "Default")

let metalTexture = Texture(name: "Metal",
                           diffuse: NSImage(named: "metal-diffuse.jpg") ?? 1.0,
                           normal: NSImage(named: "metal-normal.jpg") ?? 0.0,
                           roughness: NSImage(named: "metal-roughness.jpg") ?? 0.0,
                           metalness: NSImage(named: "metal-metalness.jpg") ?? 0.0)

let woodTexture = Texture(name: "Wood",
                          diffuse: NSImage(named: "wood-diffuse.jpg") ?? 1.0,
                          normal: NSImage(named: "wood-normal.jpg") ?? 0.0,
                          roughness: NSImage(named: "wood-roughness.jpg") ?? 0.0,
                          metalness: 0.0)

let mirrorTexture = Texture(name: "Mirror",
                          diffuse: 1.0,
                          normal: 0.0,
                          roughness: 0.0,
                          metalness: 1.0)
