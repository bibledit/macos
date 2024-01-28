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
        print ("loadView()")
        super.loadView()
        let web_view_configuration = WKWebViewConfiguration ()
        web_view_configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        web_view = WKWebView (frame: CGRect(x:0, y:0, width:800, height:600), configuration:web_view_configuration)
        web_view.uiDelegate = self
        self.view = web_view
    }
    
    override func viewDidLoad() 
    {
        print ("viewDidLoad()")
        super.viewDidLoad()
        let url = Bundle.main.url ( forResource: "changelog",
                                    withExtension: "html",
                                    subdirectory: "webroot/help")
        print (url!)
        let path = url!.deletingLastPathComponent();
        print (path)
        web_view.loadFileURL ( url!, allowingReadAccessTo: path)
        displayLoading()
    }

    func displayLoading()
    {
        // Open a "loading" message in the WebView.
        // This message will be displayed for as long as the Bibledit kernel server is not yet available.
        let htmlString : String = 
"""
<html>
<head>
<style>
.center-screen {
 display: flex;
 flex-direction: column;
 justify-content: center;
 align-items: center;
 text-align: center;
 min-height: 100vh;
 background: radial-gradient(gold, yellow, white);
}
</style>
</head>
<body>
<h2 class=\"center-screen\">... Bibledit loading ...</h2>
</body>
</html>
"""
        web_view.loadHTMLString(htmlString, baseURL: nil)
    }
    
}
