# Bibledit macOS

Bibledit for macOS source code repository and developer assistance

## Introduction

Bibledit has been working on macOS in various forms:
* Bibledit-Gtk written for Linux and ported to Mac macOS.
* Bibledit-Web written in PHP and adapted to run on Mac macOS.
* Bibledit-macOS written in Objective-C and running natively on macOS.

The current port of Bibledit for macOS consists of the following parts:
* A native Bibledit macOS app written in Swift.
* An embedded WebKit View.
* The bibledit kernel written in C++, compiled for macOS.

## Sandboxing

With the app sandbox enabled in Xcode, the app cannot write to the webroot folder in the app's Resources. To deal with this, the app copies the webroot folder to the documents folder within the sandbox. The sandbox is at ~/Library/Containers/org.bibledit.osx/
It needs the following entitlements: Network Server, Network Client, Printing.

## App Transport Security

OSX 10.11 El Capitan has “App Transport Security”. This was disabled in the Info.plist.

## Inspect embedded Webview

To enable the developer tools in the embedded WebKit browser, enter the following into the Terminal:

defaults write org.bibeldit.osx WebKitDeveloperExtras -bool true

Then launch Bibledit. Web Inspector can now be accessed by a Control-click or right-click from within any web view. You must also enable contextual menus in your app.

## Refreshing Bibledit kernel

Run script "bash ./refresh.txt".

## Setting up Xcode

* The initial steps to embed a webview were taken from this: https://stackoverflow.com/questions/60082417/how-do-i-create-a-wkwebview-app-for-macos
* Information how to embed C and C++ code in a Swift project was taken from this: https://stackoverflow.com/questions/32541268/can-i-have-swift-objective-c-c-and-c-files-in-the-same-xcode-project/32546879#32546879 with full information here: https://www.swift.org/documentation/cxx-interop/
* Set the header search path and the user header search path.
* Set the location of the bridging header.
* Set the C++ and Objective-C interoperability to "C++/Objective-C++".
"
## Building and distributing the app

* Open the Bibledit Xcode project.
* Clean it.
* Build it.
* Copy the Bibledit product from Xcode to another location.
* Test it from the other location.
* Test it on a clean macOS installation.
* Archive the app from Xcode, and submit it to the Apple App Store.
* Have it reviewed by Apple.
* On release, immediately test it on a clean macOS installation.

## Compliance with Mac App Store

Upon submission to the store the Bibledit app was rejected on the grounds that the interface was not of sufficient quality. It just had a button to open Safari to display the web app. The solution to this was to integrate a WebView into the Bibledit app.
Upon a second submission to the store, the app was rejected on the grounds that it accessed '/Library/Managed Preferences/Guest/com.apple.familycontrols.contentfilter.plist'. After an investigation into this, it appeared that the Bibledit app itself was not accessing this location, but that the integrated WebView did it. The WebView is a component from Apple, thus access to this location is outside Bibledit's control.
Upon a third submission to the store, the app was rejected because "The app uses 'osx' in the menu item names in a manner that is not consistent with Apple's trademark guidelines." The solution was to update the names of the menu items.
After a submission to the store, the app was rejected for the following reason: "This app uses one or more entitlements which do not have matching functionality within the app. Apps should have only the minimum set of entitlements necessary for the app to function properly. Please remove all entitlements that are not needed by your app and submit an updated binary for review, including the following: com.apple.security.network.server". The following explanation was given: The app includes a web server on port 9876 to function properly. The GUI of the app is a Web View that connects to the included web server to display the app's interface and to interact with the app. After removing the "com.apple.security.network.server" entitlement, the app ceases to work.
After a submission to the store, the app was rejected for the following reason: "We have found that when the user closes the main application window there is no menu item to re-open it.". The solution was to quit the app when the main window is closed.
After a new submission to the store, the app was again rejected for the same reason as before: "This app uses one or more entitlements which do not have matching functionality within the app. Apps should have only the minimum set of entitlements necessary for the app to function properly. Please remove all entitlements that are not needed by your app and submit an updated binary for review, including the following: com.apple.security.network.server". "Commonly added entitlements that many apps don't need include: "com.apple.security.network.server". Apps that initiate outgoing connections (for example, to download new content from your server) only need to include "com.apple.security.network.client". The server entitlement is only necessary for apps that listen for and respond to incoming network connections (such as web or FTP servers). The following response was given: The Bibledit app listens for and responds to incoming network connections, because it is a web server. Since it is a web server, it needs the entitlement "com.apple.security.network.server". Without this entitlement, the app ceases to work. The entitlement is essential to Bibledit operation.
After another submission to the store, the app was rejected as follows: "We noticed an issue in your app that contributes to a lower quality user experience than Apple users expect: Specifically, when expanding the main window, the UI gets cutoff. Please evaluate whether you can improve the user experience and resubmit your app for review." The solution to this was to make the embedded webview resize when the main window was resized.


## History

Distributing the app:
Create a dmg in Disk Utility.
Add Bibledit.app to it.
Set the correct background image, and view options.
Create a link to /Applications, and add this link.
Convert the dmg to read-only.

