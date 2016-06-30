//
//  AppDelegate.swift
//  QChelper
//
//  Created by Yudong Qiu on 7/10/15.
//  Copyright (c) 2015 Bruce. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        // Remove the extra default menu items that we don't want
        let EditMenu = NSApplication.sharedApplication().mainMenu!.itemWithTitle("Edit")
        if (EditMenu != nil)    {
            let Count: Int = EditMenu!.submenu!.numberOfItems
            if (EditMenu!.submenu!.itemAtIndex(Count - 1)!.title == "Special Characters…")
            {
                EditMenu!.submenu!.removeItemAtIndex(Count - 1)
            }
            if (EditMenu!.submenu!.itemAtIndex(Count - 1)!.title == "Emoji & Symbols")
            {
                EditMenu!.submenu!.removeItemAtIndex(Count - 1)
            }
            if (EditMenu!.submenu!.itemAtIndex(Count - 2)!.title == "Start Dictation…")
            {
                EditMenu!.submenu!.removeItemAtIndex(Count - 2)
            }
        }
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBOutlet weak var menu_rotate: NSMenuItem!
        
    @IBOutlet weak var menu_high_reso: NSMenuItem!
    
    @IBAction func menu_high_reso_switch(sender: AnyObject) {
        if menu_high_reso.state == NSOnState {
            menu_high_reso.state = NSOffState
        }
        else if menu_high_reso.state == NSOffState {
            menu_high_reso.state = NSOnState
        }
    }

    
    func applicationShouldHandleReopen(theApplication: NSApplication ,hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            theApplication.windows[0].orderFront(self)
        }
        else {
            theApplication.windows[0].makeKeyAndOrderFront(self)
        }
        return true
    }
    

    
    
}
