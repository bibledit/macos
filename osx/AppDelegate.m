//
//  AppDelegate.m
//
//  Copyright (c) 2013-2021 Teus Benschop. All rights reserved.
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
- (IBAction)menuFind:(id)sender;
- (IBAction)menuFindNext:(id)sender;

@property (strong) id activity;

@property (atomic, retain) NSString * accordanceReceivedVerse;

@end


@implementation AppDelegate


NSString * searchText = @"";
NSTimer * urlNsTimer;
NSString * portNumber = @"";


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

  // When the Bibledit app is in the background, macOS puts it to sleep.
  // This is the "App Nap".
  // It has been noticed that even after coming out of the nap, Bibledit remains slowish,
  // and uses a lot of CPU resources.
  // Simple solution: Disable App Nap.
  if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
    self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:0x00FFFFFF reason:@"runs a web server"];
  }

  // Get the port number that the Bibledit kernel has negotiated.
  portNumber = [NSString stringWithUTF8String:bibledit_get_network_port ()];

  // Get the paths of the resources to copy,
  // and get the paths of where to copy those resources to.
  NSArray *components = [NSArray arrayWithObjects:[[NSBundle mainBundle] resourcePath], @"webroot", nil];
  NSString *packagePath = [NSString pathWithComponents:components];
  NSString * documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  components = [NSArray arrayWithObjects:documents, @"webroot", nil];
  NSString *webrootPath = [NSString pathWithComponents:components];
  // Initialize the Bibledit kernel with the paths where to copy from, and where to copy to.
  const char * package = [packagePath UTF8String];
  const char * webroot = [webrootPath UTF8String];
  bibledit_initialize_library (package, webroot);
  
  // Open a "loading" message in the WebView.
  // This message will be displayed for as long as the Bibledit kernel server is not yet availble.
  NSString *htmlString =
  @"<html>"
  "<head>"
  "<style>"
  ".center-screen {"
  " display: flex;"
  " flex-direction: column;"
  " justify-content: center;"
  " align-items: center;"
  " text-align: center;"
  " min-height: 100vh;"
  " background: radial-gradient(gold, yellow, white);"
  "}"
  "</style>"
  "</head>"
  "<body>"
  "<h2 class=\"center-screen\">... Bibledit loading ...</h2>"
  "</body>"
  "</html>";
  [[[self webview] mainFrame] loadHTMLString:htmlString baseURL:nil];
  [self.window setContentView:self.webview];

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
  urlNsTimer = [NSTimer
             scheduledTimerWithTimeInterval:1.0
             target:self
             selector:@selector(urlTimerTimeout)
             userInfo:nil
             repeats:YES];

  // For the developer console in the webview, enter the following from a terminal:
  // defaults write org.bibledit.osx WebKitDeveloperExtras TRUE
  
  self.accordanceReceivedVerse = @"";
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self.window];
  
  [self.webview setPolicyDelegate:self];
  [self.webview setDownloadDelegate:self];
  
  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTimeout) userInfo:nil repeats:YES];

  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(accordanceDidScroll:) name:@"com.santafemac.scrolledToVerse" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorCoalesce];

}


bool kernel_ready = false;

- (void)urlTimerTimeout
{
  // Start the embedded server.
  bibledit_start_library ();

  // Wait shortly to give the system time to start.
  [NSThread sleepForTimeInterval:0.2f];

  // Open the web app in the web view.
  // The server listens on another port than 8080.
  // Goal: Not to interfere with possible development on the same host.
  // It used to connect to localhost but this led to errors like:
  // nw_socket_handle_socket_event [C2.1:2] Socket SO_ERROR [61: Connection refused]
  // The fix is to connect to 127.0.0.1 instead.
  NSString* urlString = [NSString stringWithFormat:@"http://127.0.0.1:%@", portNumber];
  NSURL *url = [NSURL URLWithString:urlString];
  // This timer will keep testing the embedded Bibledit kernel till it becomes available.
  NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *sessionWithoutADelegate = [NSURLSession sessionWithConfiguration:conf];
  NSURLSessionDataTask * task = [sessionWithoutADelegate dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    // If data is received, it means that the Bibledit kernel is ready for use.
    if (data) {
      kernel_ready = true;
    }
    [sessionWithoutADelegate finishTasksAndInvalidate];
  }];
  if (kernel_ready) {
    // Stop the timer.
    [urlNsTimer invalidate];
    urlNsTimer = nil;
    // Load the URL of the Bibledit kernel in the webview.
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [[[self webview] mainFrame] loadRequest:urlRequest];
  }
  [task resume];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.santafemac.scrolledToVerse" object:nil];
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


- (IBAction)menuFind:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Search";
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.informativeText = [NSString stringWithFormat:@"Search for"];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:searchText];
    [alert setAccessoryView:input];
    [[alert window] setInitialFirstResponder: input];
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {
        searchText = [input stringValue];
        if (searchText.length) {
            [self.webview searchFor:searchText direction:TRUE caseSensitive:FALSE wrap:TRUE];
        } else {
            [self.webview setSelectedDOMRange:nil affinity:NSSelectionAffinityDownstream];
        }
    }
}


- (IBAction)menuFindNext:(id)sender {
    [self.webview searchFor:searchText direction:TRUE caseSensitive:FALSE wrap:TRUE];
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


NSString * previous_sent_reference = @"";
NSString * previous_received_reference = @"";
//NSString * previous_reference = @"";
int send_counter = 0;
int receive_counter = 0;


- (void)timerTimeout
{
  // Checking whether Bibledit needs to open a URL in the default system browser.
  NSString * url = [NSString stringWithUTF8String:bibledit_get_external_url ()];
  if (url.length != 0) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: url]];
  }
  
  // Accordance have implemented a ’SantaFeMac’ scheme
  // that should allow intra-app scrolling,
  // even if in the Mac App Store.
  // As of Accordance 13.1.5 that supports it for both sending and receiving.
  // Sandboxed apps can send notifications only if they do not contain a dictionary.
  // If the sending application is in an App Sandbox, userInfo must be nil.
  // Since Bibledit is on the Mac App Store, any additional information cannot be sent.
  // To that end the information can be still sent and retrieved as the “object” of the notification.
  // The Accordance developer has defined the notification string as:
  //   com.santafemac.scrolledToVerse
  // There's timers to prevent oscillation between send and received verse references.
  send_counter++;
  receive_counter++;
  NSString * reference = [NSString stringWithUTF8String:bibledit_get_reference_for_accordance ()];
  if ([reference isNotEqualTo:previous_sent_reference]) {
    if (send_counter > 1) {
      previous_sent_reference = [[NSString alloc] initWithString:reference];
      //previous_received_reference = [[NSString alloc] initWithString:reference];
      //self.accordanceReceivedVerse = [[NSString alloc] initWithString:reference];
      [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.santafemac.scrolledToVerse" object:reference userInfo:nil deliverImmediately:YES];
      receive_counter = 0;
    }
  }
  if ([self.accordanceReceivedVerse isNotEqualTo:previous_received_reference]) {
    if (receive_counter > 1) {
      previous_received_reference = [[NSString alloc] initWithString:self.accordanceReceivedVerse];
      //previous_sent_reference = [[NSString alloc] initWithString:self.accordanceReceivedVerse];
      const char * c_reference = [self.accordanceReceivedVerse UTF8String];
      bibledit_put_reference_from_accordance (c_reference);
      send_counter = 0;
    }
  }
}


// When a new verse references comes in from Accordance,
// store this verse reference,
// to be processed later by the one-second timer.
-(void)accordanceDidScroll:(NSNotification *)notification {
  self.accordanceReceivedVerse = notification.object;
}


@end
