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
import WebKit

public var web_view: WKWebView!

class ViewController: NSViewController, WKUIDelegate
{
    
    override func loadView()
    {
        let web_view_configuration = WKWebViewConfiguration ()
        web_view_configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        web_view = WKWebView (frame: CGRect(x:0, y:0, width:800, height:600), configuration:web_view_configuration)
        // web_view = WKWebView (frame: CGRectZero, configuration: web_view_configuration) This displays hidden, no use. Todo perhaps to connect to the resize event.
        web_view.uiDelegate = self
        view = web_view
    }
    
    override func viewDidLoad() {
        print ("view did load")
        super.viewDidLoad()
        let url = Bundle.main.url ( forResource: "changelog",
                                    withExtension: "html",
                                    subdirectory: "webroot/help")
        print (url!)
        let path = url!.deletingLastPathComponent();
        print (path)
        web_view.loadFileURL ( url!, allowingReadAccessTo: path)
        self.view = web_view
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.orderFrontRegardless()
    }
}
