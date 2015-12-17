//
//  AppDelegate.swift
//  LIFX Master
//
//  Created by Dallas McNeil on 15/11/2015.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, LFXLightObserver, LFXLightCollectionObserver, NSMenuDelegate {

    /// Status item that represents the menu bar item
    let statusItem:NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(24)
    
    /// Menu of the status itme
    let menu:NSMenu = NSMenu()
    
    /// Light submenu, displays all light information
    var lightMenu:NSMenu = NSMenu()
    
    /// Effects submenu, displays all effects
    let effectMenu:NSMenu = NSMenu()
    
    /// Colour submenu, displays HSB colour sliders
    let colourMenu:NSMenu = NSMenu()
    
    /// All lights on the local network
    var lights:[LFXLight] = []
    
    /// Represents the labels of light menu items with a tick
    var selectedLights:[String:Bool] = [:]
    
    /// All lights that are approved to be used by the user
    var approvedLights:[LFXLight] = []
    
    /// The last highlights menu item
    var selectedItem:NSMenuItem?
    
    /// The on/off state of all lights
    var toggleState = false
    /*
    CREATING ADDITIONAL EFFECTS
    
    Effects are managed by a closure system where each effect is updated periodically and sets the colour of the lights
    All closure recieve the current time of the lights (An Int value 0 or greater which is increased by 1 every time the lights are updated) and a reference to the AppDelegate to access lighting methods and approved lights
    All closures are placed in an array
    The update time periods are in another array and correspond to the same index in the effects array
    The name of each effect is in another array and corresponds to the same index in the effects array
    
    To add your own effects, simply add to the arrays your effect closure, update time and effect name
    Here is a template for the closures array
    
    {(time:Int,delegate:AppDelegate) in
        *YOUR CODE GOES HERE*
    }
    
    */
    
    /// A set of closures that form the effects available to the user
    var effects:[(Int,AppDelegate)->()] = [
        {(time:Int,delegate:AppDelegate) in
            delegate.setAllLights(LFXHSBKColor(hue: 0, saturation: 0 , brightness: 1), duration: 0.5)
        },
        {(time:Int,delegate:AppDelegate) in
            delegate.setAllLights(LFXHSBKColor(hue: CGFloat(time)*36, saturation: 1, brightness: 1), duration: 1)
        },
        {(time:Int,delegate:AppDelegate) in
            delegate.setAllLights(LFXHSBKColor(hue: CGFloat(random()%360), saturation: CGFloat(random()%256)/256, brightness: CGFloat(random()%256)/256), duration: 1)
        },
        {(time:Int,delegate:AppDelegate) in
            delegate.setAllLights(LFXHSBKColor(hue:(CGFloat(sin(Double(time*5)/(180*M_PI)))*3600), saturation: 1, brightness: 1), duration: 0.2)
        },
        {(time:Int,delegate:AppDelegate) in
            delegate.setAllLights(LFXHSBKColor(hue:CGFloat(time/2), saturation: 1, brightness: 1), duration: 1)
        },
        {(time:Int,delegate:AppDelegate) in
            if time%2 == 0 {
                delegate.setAllLights(LFXHSBKColor(hue:0, saturation: 1, brightness: 1), duration: 0)
            } else {
                delegate.setAllLights(LFXHSBKColor(hue:120, saturation: 1, brightness: 1), duration: 0)
            }
        },
        {(time:Int,delegate:AppDelegate) in
            if time%4 == 0 {
                delegate.setAllLights(LFXHSBKColor(hue:0, saturation: 1, brightness: 1), duration: 0)
            } else if time%4 == 1 {
                delegate.setAllLights(LFXHSBKColor(hue:120, saturation: 1, brightness: 1), duration: 0)
            } else if time%4 == 2 {
                delegate.setAllLights(LFXHSBKColor(hue:50, saturation: 1, brightness: 1), duration: 0)
            } else if time%4 == 3 {
                delegate.setAllLights(LFXHSBKColor(hue:240, saturation: 1, brightness: 1), duration: 0)
            }
        }
        
        
    ]
    
    /// The corresponding name of the effect displayed to the user
    var effectNames:[String] = ["Standard","Rainbow","Random","Varying Rainbow","Slow Rainbow","Christmas 1","Christmas 2"]
    
    /// The corresponding update time of each effect
    var updateTimings:[NSTimeInterval] = [1,1,1,0.2,1,1,1]
    
    /// A timer that manages the update of light effects
    var timer:NSTimer = NSTimer()
    
    /// The current effect option being used
    var effectOption:Int = 0
    
    /// The current effects time
    var effectCount:Int = 0
    
    /// Hue slider in colour menu
    let sliderH = NSSlider(frame: NSRect(x: 0, y: 0, width: 24, height: 120))
    /// Saturation slider in colour menu
    let sliderS = NSSlider(frame: NSRect(x: 24, y: 0, width: 24, height: 120))
    /// Brightness slider in colour menu
    let sliderB = NSSlider(frame: NSRect(x: 48, y: 0, width: 24, height: 120))

    /// The colour of the lights determined by the HSB sliders
    let lightColour = LFXHSBKColor(hue: 0, saturation: 1, brightness: 0)
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        LFXClient.sharedClient().localNetworkContext.allLightsCollection.addLightCollectionObserver(self)
        
        let title = NSMenuItem(title: "LIFX Master", action: nil, keyEquivalent: "")
        title.enabled = false
        
        let lights = NSMenuItem(title: "Lights", action: nil, keyEquivalent: "")
        
        let quit = NSMenuItem(title: "Quit", action: Selector("quit"), keyEquivalent: "")
        statusItem.image = NSImage(named: "MenuLogo")
  
        let effects = NSMenuItem(title: "Effects", action: nil, keyEquivalent: "")
        
        for name in effectNames {
            let item = NSMenuItem(title: name, action: Selector("setEffect"), keyEquivalent: "")
            effectMenu.addItem(item)
        }
        
        let toggle = NSMenuItem(title: "Lights On", action: nil, keyEquivalent: "")
        toggle.enabled = false
        
        let colour = NSMenuItem(title: "Colour", action: nil, keyEquivalent: "")
        colour.submenu = colourMenu
        
        let slidersView = NSView(frame: NSRect(x: 0, y: 0, width: 72, height: 120))
        slidersView.addSubview(sliderH)
        slidersView.addSubview(sliderS)
        slidersView.addSubview(sliderB)
        
        let colourItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        colourItem.view = slidersView
        colourMenu.addItemWithTitle("HSB", action: nil, keyEquivalent: "")
        colourMenu.addItem(colourItem)
        
        sliderH.maxValue = 360.0
        sliderH.minValue = 0.0
        sliderS.maxValue = 1.0
        sliderS.minValue = 0.0
        sliderB.maxValue = 1.0
        sliderB.minValue = 0.0
        
        sliderH.target = self
        sliderS.target = self
        sliderB.target = self
        
        sliderH.action = Selector("updateLightColour:")
        sliderS.action = Selector("updateLightColour:")
        sliderB.action = Selector("updateLightColour:")
        
        menu.addItem(title)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(lights)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(toggle)
        menu.addItem(colour)
        menu.addItem(effects)
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(quit)
    
        lights.submenu = lightMenu
        effects.submenu = effectMenu
        effectMenu.delegate = self
        
        let noLights = NSMenuItem(title: "No Lights", action: nil, keyEquivalent: "")
        noLights.enabled = false
        lightMenu.addItem(noLights)
        
        statusItem.menu = menu
        
        
        
        menu.delegate = self
        lightMenu.delegate = self
        
    }

    
    /// Called if light is discovered on network
    func lightCollection(lightCollection: LFXLightCollection!, didAddLight light: LFXLight!) {
        updateSelectedLights()
    }
    
    /// Called if light is removed from network
    func lightCollection(lightCollection: LFXLightCollection!, didRemoveLight light: LFXLight!) {
        updateSelectedLights()
    }

    /// Updates which lights are selected in the lights menu
    func updateSelectedLights() {
        
        lights = LFXClient.sharedClient().localNetworkContext.allLightsCollection.lights as! [LFXLight]
        for light in lights {
            if selectedLights[light.label()] == nil {
                selectedLights[light.label()] = false
            }
        }
        updateMenuLightOptions()
    }
    
    /// Updates menu lighting options as new lights are discovered on the network
    func updateMenuLightOptions() {
        lightMenu = NSMenu()
        lightMenu.delegate = self
        
        for light in lights {
            let item = NSMenuItem(title: "\(light.label())", action: Selector("lightPicked"), keyEquivalent: "")
            item.target = self
            lightMenu.addItem(item)
            item.enabled = true

        }
        
        menu.itemAtIndex(2)!.submenu = lightMenu

        if lights.isEmpty {
            let noLights = NSMenuItem(title: "No Lights", action: nil, keyEquivalent: "")
            noLights.enabled = false
            lightMenu.addItem(noLights)
        }
        
    }
    
    /// Called when a light is selected, approved or diapproved for use
    func lightPicked() {
        if selectedItem != nil {
            if selectedItem!.state == NSOnState {
                selectedItem!.state = NSOffState
                selectedLights[selectedItem!.title] = false
            } else {
                selectedItem!.state = NSOnState
                selectedLights[selectedItem!.title] = true 
            }
        }
        
        approvedLights.removeAll()
        for light in lights {
            if let approve = selectedLights[light.label()] {
                if approve {
                    approvedLights.append(light)
                }
            }
        }
        
        if !approvedLights.isEmpty {
            menu.itemAtIndex(4)!.enabled = true
            menu.itemAtIndex(4)!.action = Selector("toggleLights")
            if approvedLights.count == 1 {
                toggleState = approvedLights[0].powerState() == LFXPowerState.On
                if !toggleState {
                    menu.itemAtIndex(4)!.title = "Light On"
                } else {
                    menu.itemAtIndex(4)!.title = "Light Off"
                }
            }
        } else {
            menu.itemAtIndex(4)!.enabled = false
            menu.itemAtIndex(4)!.action = nil
        }
        
    }
    
    /// Delegate method called when item is highlited, updates selectedItem to last highlighted item
    func menu(menu: NSMenu, willHighlightItem item: NSMenuItem?) {
        if menu === lightMenu {
            selectedItem = item
        } else if menu === effectMenu {
            selectedItem = item
        }
    }
    
    /// Terminated application
    func quit() {
        NSApplication.sharedApplication().terminate(self)

    }
    
    /// Sets all approvedLights to colour over duration
    func setAllLights(color:LFXHSBKColor, duration:NSTimeInterval) {
        for light in approvedLights {
            light.setColor(color, overDuration: duration)
        }
    }
    
    /// Sets the current effect based on last selected menu item
    func setEffect() {
        if let option = effectMenu.itemArray.indexOf(selectedItem!) {
            effectOption = option
            
            setupTimingForOption(option)
        }
    }
    
    /// Toggles lights on or off depending on toggle state
    func toggleLights() {
        for light in approvedLights {
            if toggleState {
                light.setPowerState(.Off)
                
            } else {
                light.setPowerState(.On)
            }
        }
        if toggleState {
            menu.itemAtIndex(4)!.title = "Light On"
            toggleState = false
            
        } else {
            menu.itemAtIndex(4)!.title = "Light Off"
            toggleState = true
        }
    }
    
    /// Sets timer for current effect option to update after a period of time
    func setupTimingForOption(option:Int) {
        effectCount = 0
        effectOption = option
        
        timer = NSTimer.scheduledTimerWithTimeInterval(updateTimings[effectOption], target: self, selector: Selector("updateLightsEffect"), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    /// Updates current lighting effect
    func updateLightsEffect() {
        effects[effectOption](effectCount,self)
        effectCount++
    }
    
    
    /// Updates the colour of all approvedLights based on HSB slider values
    func updateLightColour(sender:NSSlider) {
        
        if sender === sliderH {
            lightColour.hue = CGFloat(sliderH.doubleValue)
        } else if sender === sliderS {
            lightColour.saturation = CGFloat(sliderS.doubleValue)
        } else if sender === sliderB {
            lightColour.brightness = CGFloat(sliderB.doubleValue)
        }
        for light in approvedLights {
            light.setColor(lightColour)
        }
    }
}

