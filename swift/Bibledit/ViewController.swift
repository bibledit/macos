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

// The WebKit view.
public var web_view: WKWebView!

// Flag for whether the kernel is ready.
public var kernelReady : Bool = false

class ViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate
{
    
    override func loadView()
    {
        super.loadView()
        let web_view_configuration = WKWebViewConfiguration ()
        web_view_configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        web_view = WKWebView (frame: CGRect(x:0, y:0, width:800, height:600), configuration:web_view_configuration)
        web_view.uiDelegate = self
        self.view = web_view
        // For the developer console in the webview, enter the following from a terminal:
        //   defaults write org.bibledit.osx WebKitDeveloperExtras TRUE
        web_view.navigationDelegate = self
    }

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        displayLoading()
        urlTimer()
    }
    
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        // Set the delegate for downloading. In this case it is set to self.
        // It could also be set to an object that handles the download.
        download.delegate = self
    }

    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void)
    {
        // This occurs if the "download" attribute in the HTML has been specified.
        if navigationAction.shouldPerformDownload {
            // Express the intent to download the URL.
            decisionHandler(.download, preferences)
        } else {
            // Express the intent to open the URL in the browser.
            decisionHandler(.allow, preferences)
        }
    }


    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
    {
        // if let mimeType = navigationResponse.response.mimeType {
        // }
//        if let url = navigationResponse.response.url {
//            if url.pathExtension == "usfm" {
//                // Express the intent to download the URL.
//                decisionHandler(.download)
//                return
//            }
//        }
        if navigationResponse.canShowMIMEType {
            // Express the intent to open the URL in the browser.
            decisionHandler(.allow)
            return
        } else {
            // The browser cannot show this MIME type, so express the intent to download it.
            decisionHandler(.download)
            return
        }
    }


    // The name of the downloaded file.
    var downloadedFilename : String = ""

    
    // Asks the delegate to provide a file destination
    // where the system should write the download data.
    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {

        // Store the file in the Downloads directory using the suggested file name.
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileName = downloadsDirectory.appendingPathComponent(suggestedFilename)

        // If the file to download already exists, delete it, and keep a note of that.
        do {
            try FileManager.default.removeItem(at: fileName)
        }
        catch { }

        // Store the suggested filename.
        downloadedFilename = suggestedFilename

        // Pass the filename to download to actually start the download.
        completionHandler(fileName)
    }

    
    // Tells the delegate that the download finished.
    // Inform the user.
    func downloadDidFinish(_ download: WKDownload) {
        let alert = NSAlert()
        alert.messageText = "Download complete"
        alert.informativeText = "The file was saved to the Downloads directory as " + downloadedFilename
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal() 
    }

    
    // Tells the delegate that the download failed,
    // with error information and data you can use to restart the download.
    // Inform the user.
    public func download(_ download: WKDownload,
                         didFailWithError error: Error,
                         resumeData: Data?) {
        let alert = NSAlert()
        alert.messageText = "Download failed"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        alert.runModal()
    }


    func displayLoading()
    {
        // Open a "loading" message in the WebView.
        // This message will be displayed for as long as the Bibledit kernel server is not yet available.
        let url = Bundle.main.url ( forResource: "loading",
                                    withExtension: "html",
                                    subdirectory: "webroot/bootstrap")
        let path = url!.deletingLastPathComponent()
        web_view.loadFileURL ( url!, allowingReadAccessTo: path )
    }
    
    
    // The following is to fix the following bug:
    //   We discovered one or more bugs in your app when reviewed on Mac running macOS 10.13.5.
    //   On first launch of the app, only a blank window is shown.
    //   On the second launch of the app, the UI then properly appears.
    // While resolving this bug, it was discovered that on initial run,
    // the internal webserver did indeed start, but could not be contacted right away.
    // That caused the blank window.
    // The solution is this:
    //   Start the internal web server plus the browser after a delay.
    // Obviously the sandbox does not assign the server privilege right away.
    // But it does do so after a slight delay.
    func urlTimer () -> Void {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in

            // Start the embedded server.
            // Note that it may seem to be started multiple times, each timer iteration,
            // but the function's implementation limits this to just once.
            bibledit_start_library ()

            // Wait shortly to give the system time to start. The value is in seconds.
            Thread.sleep(forTimeInterval: 0.5)

            // The server listens on another port than 8080.
            // Goal: Not to interfere with possible development on the same host.
            // It used to connect to localhost but this led to errors like:
            // nw_socket_handle_socket_event [C2.1:2] Socket SO_ERROR [61: Connection refused]
            // The fix is to connect to 127.0.0.1 instead.
            // This timer will keep testing the embedded Bibledit kernel webserver
            // till it becomes available.
            let urlString : String = "http://127.0.0.1:" + portNumber
            let url = URL(string: urlString)
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                // The data task fails or succeeds.
                // If the data task fails, then error has a value. 
                // If the data task succeeds, then data and response have a value.
                // If data is received, it means that the Bibledit kernel is ready for use.
                if data != nil {
                    kernelReady = true
                }
            }
            print ("kernel ready:", kernelReady)

            // The data task is created, but the HTTP request isn't executed.
            // Call resume() on the task to execute it.
            task.resume()

            // If the Bibledit kernel is now ready to accept requests,
            // stop the timer and cancel the task,
            // and open the web app in the WebKit view.
            if (kernelReady) {
                timer.invalidate()
                task.cancel()
                let request = URLRequest(url: url!)
                web_view.load(request)
            }
        }
    }

    
    override func keyDown(with event: NSEvent) {
        if (event.modifierFlags.contains(.command)) {
            let code = event.keyCode
            // Handle Cmd-F to find text.
            if (code == 3) {
                print ("Cmd-F")
            }
        }
    }

    
    
}
