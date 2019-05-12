//
//  AppDelegate.swift
//  QChelper
//
//  Created by Yudong Qiu on 7/10/15.
//  Copyright (c) 2015 Bruce. All rights reserved.
//

import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if let window = NSApp.mainWindow, let viewController = window.contentViewController as? ViewController {
            viewController.mySceneView.open_file(url: URL(fileURLWithPath: filename))
        }
        return true
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        // Remove the extra default menu items that we don't want
//        let EditMenu = NSApplication.shared.mainMenu!.item(withTitle: "Edit")
//        if (EditMenu != nil)    {
//            let Count: Int = EditMenu!.submenu!.numberOfItems
//            if (EditMenu!.submenu!.item(at: Count - 1)!.title == "Special Characters…")
//            {
//                EditMenu!.submenu!.removeItem(at: Count - 1)
//            }
//            if (EditMenu!.submenu!.item(at: Count - 1)!.title == "Emoji & Symbols")
//            {
//                EditMenu!.submenu!.removeItem(at: Count - 1)
//            }
//            if (EditMenu!.submenu!.item(at: Count - 2)!.title == "Start Dictation…")
//            {
//                EditMenu!.submenu!.removeItem(at: Count - 2)
//            }
//        }
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBOutlet weak var menu_rotate: NSMenuItem!
        
    @IBOutlet weak var menu_high_reso: NSMenuItem!
    
    @IBAction func menu_high_reso_switch(sender: AnyObject) {
        if menu_high_reso.state == .on{
            menu_high_reso.state = .off
        }
        else if menu_high_reso.state == .off {
            menu_high_reso.state = .on
        }
    }
    
    @IBOutlet weak var menu_vdw_representation: NSMenuItem!
    @IBOutlet weak var menu_cast_shadow: NSMenuItem!
    
    func applicationShouldHandleReopen(_ theApplication: NSApplication ,hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            theApplication.windows[0].orderFront(self)
        }
        else {
            theApplication.windows[0].makeKeyAndOrderFront(self)
        }
        return true
    }
    
    @IBOutlet weak var menu_trajectory: NSMenuItem!
    @IBOutlet weak var menu_traj_update_bonds: NSMenuItem!
    @IBAction func toggle_menu_traj_update_bonds(sender: Any) {
        if menu_traj_update_bonds.state == .off {
            menu_traj_update_bonds.state = .on
            if let window = NSApp.mainWindow, let viewController = window.contentViewController as? ViewController {
                viewController.mySceneView.reset_bond_nodes()
            }
        } else {
            menu_traj_update_bonds.state = .off
        }
    }
    
    @IBOutlet weak var menu_adv_render: NSMenuItem!
    @IBAction func toggle_menu_adv_render(_ sender: Any) {
        if let window = NSApp.mainWindow, let viewController =  window.contentViewController as? ViewController {
            if menu_adv_render.state == .off {
                menu_adv_render.state = .on
                viewController.mySceneView.toggleAdvancedRendering(enable: true)
            } else {
                menu_adv_render.state = .off
                viewController.mySceneView.toggleAdvancedRendering(enable: false)
            }
        }
    }
    
    @IBOutlet weak var menu_background_image: NSMenuItem!
    @IBAction func toggle_menu_show_background_image(sender: Any) {
        if let window = NSApp.mainWindow, let viewController =  window.contentViewController as? ViewController {
            if menu_background_image.state == .off {
                menu_background_image.state = .on
                viewController.mySceneView.toggleBackgroundImage(show: true)
            } else {
                menu_background_image.state = .off
                viewController.mySceneView.toggleBackgroundImage(show: false)
            }
        }
    }
    
    @IBOutlet weak var menu_texture_default: NSMenuItem!
    @IBAction func change_texture_default(sender: AnyObject?) {
        menu_texture_default.state = .on
        menu_texture_metal.state = .off
        menu_texture_mirror.state = .off
        menu_texture_wood.state = .off
        self.change_texture(texture: defaultTexture)
    }
    
    @IBOutlet weak var menu_texture_metal: NSMenuItem!
    @IBAction func change_texture_metal(sender: AnyObject?) {
        menu_texture_default.state = .off
        menu_texture_metal.state = .on
        menu_texture_mirror.state = .off
        menu_texture_wood.state = .off
        self.change_texture(texture: metalTexture)
    }
    
    @IBOutlet weak var menu_texture_mirror: NSMenuItem!
    @IBAction func change_texture_mirror(sender: AnyObject?) {
        menu_texture_default.state = .off
        menu_texture_metal.state = .off
        menu_texture_mirror.state = .on
        menu_texture_wood.state = .off
        self.change_texture(texture: mirrorTexture)
    }

    @IBOutlet weak var menu_texture_wood: NSMenuItem!
    @IBAction func change_texture_wood(sender: AnyObject?) {
        menu_texture_default.state = .off
        menu_texture_metal.state = .off
        menu_texture_mirror.state = .off
        menu_texture_wood.state = .on
        self.change_texture(texture: woodTexture)
    }
    
    func change_texture(texture: Texture) {
        if let window = NSApp.mainWindow, let viewController =  window.contentViewController as? ViewController {
            viewController.mySceneView.change_texture(texture: texture)
        }
    }
    
}
