//
//  AppDelegate.m
//
//  Created by Teus Benschop on 28/05/2015.
//  Copyright (c) 2015 Teus Benschop. All rights reserved.
//


#import "AppDelegate.h"
#import <WebKit/WebKit.h>
#import "bibledit.h"
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>


@interface AppDelegate ()

@property (weak) IBOutlet WebView *webview;
@property (weak) IBOutlet NSWindow *window;
- (IBAction)openInBrowser:(id)sender;

@property (strong) id activity;

@end


@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // When the Bibledit app is in the background, macOS puts it to sleep.
    // This is the "App Nap".
    // It has been noticed that even after coming out of the nap, Bibledit remains slowish,
    // and uses a lot of CPU resources.
    // Disable App Nap:
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:0x00FFFFFF reason:@"runs a web server"];
    }
    
    NSArray *components = [NSArray arrayWithObjects:[[NSBundle mainBundle] resourcePath], @"webroot", nil];
    NSString *packagePath = [NSString pathWithComponents:components];

    NSString * documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    components = [NSArray arrayWithObjects:documents, @"webroot", nil];
    NSString *webrootPath = [NSString pathWithComponents:components];

    const char * package = [packagePath UTF8String];
    const char * webroot = [webrootPath UTF8String];
    
    bibledit_initialize_library (package, webroot);
    bibledit_start_library ();
    
    // Open the web app in the web view.
    // The server listens on another port than 8080 so as not to interfere with possible development on the same host.
    NSURL *url = [NSURL URLWithString:@"http://localhost:9876"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [[[self webview] mainFrame] loadRequest:urlRequest];
    [self.window setContentView:self.webview];

    // For the developer console in the webview, enter the following from a terminal:
    // defaults write org.bibledit.osx WebKitDeveloperExtras TRUE

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self.window];
    
    [self.webview setPolicyDelegate:self];
    [self.webview setDownloadDelegate:self];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTimeout) userInfo:nil repeats:YES];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    bibledit_stop_library ();
    while (bibledit_is_running ()) {}
    bibledit_shutdown_library ();
}


// The embedded webview should resize when the main window resizes.
- (void) windowDidResize:(NSNotification *) notification
{
    NSSize size = self.window.contentView.frame.size;
    [[self webview] setFrame:CGRectMake(0, 0, size.width, size.height)];
}


-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
    return YES;
}


- (IBAction)openInBrowser:(id)sender {
    WebFrame *frame = [self.webview mainFrame];
    NSString * url = [[[[frame dataSource] request] URL] absoluteString];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: url]];
}


- (void) webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    if (![[webView class] canShowMIMEType:type]) [listener download];
}


- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSString * directory = @"/tmp";
    struct passwd *pw = getpwuid(getuid());
    if (pw->pw_dir) directory = [NSString stringWithUTF8String:pw->pw_dir];
    if (filename == nil) filename = @"bibledit-download";
    NSString *destinationPath = [NSString stringWithFormat:@"%@/%@/%@", directory, @"Downloads", filename];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Download";
    [alert addButtonWithTitle:@"OK"];
    alert.informativeText = [NSString stringWithFormat:@"Will be saved to: %@", destinationPath];
    [alert runModal];
    [download setDestination:destinationPath allowOverwrite:YES];
}


- (void)webView:(WebView *)sender runOpenPanelForFileButtonWithResultListener:(id < WebOpenPanelResultListener >)resultListener
{
    // Create the file open dialog.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Enable the selection of directories in the dialog.
    [openDlg setCanChooseDirectories:NO];
    
    // Run it.
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSArray* files = [[openDlg URLs]valueForKey:@"relativePath"];
        [resultListener chooseFilenames:files];
    }
}


- (void)timerTimeout
{
    NSString * url = [NSString stringWithUTF8String:bibledit_get_external_url ()];
    if (url.length != 0) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: url]];
    }
}


@end
