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


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    

    // Put code here to initialize the application.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        disableAppNap()
    }

    
    // Put code here to tear down the application.
    func applicationWillTerminate(_ aNotification: Notification) {
    }

    
    // Restoring the state of the application has not been implemented.
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    // Disable App Nap.
    func disableAppNap () {
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
}

