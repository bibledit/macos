/*
 Copyright (©) 2003-2024 Teus Benschop.
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

import Cocoa


// This must be kept alive through the applications's duration to retain the settings made on it.
var activityToken: NSObjectProtocol?

// The negotiated port number for the webserver to listen on.
public var portNumber : String = "";


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    

    // Put code here to initialize the application.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        disableAppNap()
        
        getNegotiatedLocalWebServerPortNumber()
        
        initializeBibleditLibrary()
    }

    
    // Put code here to tear down the application.
    func applicationWillTerminate(_ aNotification: Notification) {
    }

    
    // Restoring the state of the application has not been implemented.
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    
    func disableAppNap () -> Void {
        // When the Bibledit app is in the background, macOS puts it to sleep.
        // This is the "App Nap".
        // It has been noticed that even after coming out of the nap, 
        // Bibledit remains slowish and uses a lot of CPU resources.
        // Simple solution: Disable App Nap.
        activityToken = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "runs a web server")
        // The Activity Monitor shows the intended effects.
        // Upon minimizing Bibledit, the App Nap remains "No".
        // Without the code above it would change to "Yes".
        // This proves that disabling App Nap works.
    }
    
    
    func getNegotiatedLocalWebServerPortNumber() -> Void {
        // Get the port number that the Bibledit kernel has negotiated.
        // This is of Swift type: Optional<UnsafePointer<Int8>>
        let port = bibledit_get_network_port ()
        if let port = port {
            portNumber = String (cString: port)
        } else {
            portNumber = "9876"
        }
        print ("port number: ", portNumber)
    }

    
    func initializeBibleditLibrary() -> Void {

        // Get the path of the resources to copy.
        let resourcesUrl = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let resourceWebroot = resourcesUrl.appendingPathComponent("webroot")
        let packagePath = resourceWebroot.path()
        print (packagePath)

        // Get the path of where to copy the resources to.
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        let documentsWebroot = documentsUrl.appendingPathComponent("webroot")
        let webrootPath = documentsWebroot.path()
        print (webrootPath)

        // Initialize the Bibledit kernel with the paths where to copy the resource data from,
        // and where to copy that data too.
        // The Bibledit webserver needs a writable webfoot folder.
        // The webroot is not writable in the resources folder.
        // To have a writable webroot, it needs to be copied to the Documents folder.
        // The kernel will initialize the copying operation in a thread.
        let package: UnsafePointer<Int8>? = NSString(string: packagePath).utf8String
        let webroot: UnsafePointer<Int8>? = NSString(string: webrootPath).utf8String
        bibledit_initialize_library (package, webroot);
    }
}
