//
//  AppDelegate.m
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "AppDelegate.h"
#import <NewsstandKit/NewsstandKit.h>
#import "Library.h"

static NSString *const host = @"curry.cse.psu.edu/";

@interface AppDelegate ()
@property (nonatomic,strong) NSOperationQueue        *operationQueue;
@property (nonatomic,strong) UITextView *textView;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize operationQueue;
@synthesize textView;

#pragma - mark Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // don't throttle - for testing purposes
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NKDontThrottleNewsstandContentNotifications"];
    
    // Add registration for remote notifications
	[[UIApplication sharedApplication] 
     registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
	// Clear application badge when app launches
	application.applicationIconBadgeNumber = 0;

    // see if app was launched due to a remote notification - new issue ready!
    NSDictionary *payload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(payload) {
        Library *dlibrary = [Library sharedInstance];
        dlibrary.debugText =  [NSString stringWithFormat:@"RemoteNotificationKey: %d, %@, %@", [[UIApplication  sharedApplication] applicationState], [NSDate date], payload];
        //get new issue name from payload
        NSDictionary *aps = [payload objectForKey:@"aps"];
        
        NSString *issueName = [aps objectForKey:@"Name"];
        NSLog(@"Name: %@", issueName);
        Library *library = [Library sharedInstance];
        [library addAndDownloadIssueNamed:issueName];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[aps objectForKey:@"badge"] intValue]];
        
//        NSString *issueName = [payload objectForKey:@"issueName"];
//        // schedule for issue downloading in background
//        NKIssue *nkIssue = [[NKLibrary sharedLibrary] issueWithName:issueName];
//        if(nkIssue) {
//            NSURL *downloadURL = [NSURL URLWithString:@"http://www.viggiosoft.com/media/data/blog/newsstand/magazine-4.pdf"];
//            NSURLRequest *req = [NSURLRequest requestWithURL:downloadURL];
//            NKAssetDownload *assetDownload = [issue4 addAssetWithRequest:req];
//            [assetDownload downloadWithDelegate:store];
//        }
    }
    
    // when the app is relaunched, it is better to restore pending downloading assets as abandoned downloadings will be cancelled
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NSArray *assets = [nkLib downloadingAssets];
    if ([assets count] > 0) {
        Library *library = [Library sharedInstance];
        
        for(NKAssetDownload *asset in assets) {
            //NSLog(@"Asset to download: %@",asset);
            [asset downloadWithDelegate:library];            
        }
    }
    
        
//    NSArray *downloads = [launchOptions objectForKey:UIApplicationLaunchOptionsNewsstandDownloadsKey];
//    if (downloads) {
//        Library *library = [Library sharedInstance];
//        library.debugText =  [NSString stringWithFormat:@"DownloadKey: %@, %@", [NSDate date], downloads];
//    }
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma - mark Remote Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
	
#if !TARGET_IPHONE_SIMULATOR
    
    //NSLog(@"Token: %@", devToken);
    
	// Get Bundle Info for Remote Registration (handy if you have more than one app)
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
	NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	
	// Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
	NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
	
    
	// Set the defaults to disabled unless we find otherwise...
	NSString *pushBadge = (rntypes & UIRemoteNotificationTypeBadge) ? @"enabled" : @"disabled";
	NSString *pushAlert = (rntypes & UIRemoteNotificationTypeAlert) ? @"enabled" : @"disabled";
	NSString *pushSound = (rntypes & UIRemoteNotificationTypeSound) ? @"enabled" : @"disabled";	


    
	// Get the users Device Model, Display Name, Unique ID, Token & Version Number
	UIDevice *dev = [UIDevice currentDevice];
	NSString *deviceUuid;
    
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id uuid = [defaults objectForKey:@"deviceUuid"];
    if (uuid)
        deviceUuid = (NSString *)uuid;
    else {
        CFStringRef cfUuid = CFUUIDCreateString(NULL, CFUUIDCreate(NULL));
        deviceUuid = (__bridge NSString *)cfUuid;
        CFRelease(cfUuid);
        [defaults setObject:deviceUuid forKey:@"deviceUuid"];
    }
	
	NSString *deviceName = dev.name;
	NSString *deviceModel = dev.model;
	NSString *deviceSystemVersion = dev.systemVersion;
	
	// Prepare the Device Token for Registration (remove spaces and < >)
	NSString *deviceToken = [[[[devToken description] 
                               stringByReplacingOccurrencesOfString:@"<"withString:@""] 
                              stringByReplacingOccurrencesOfString:@">" withString:@""] 
                             stringByReplacingOccurrencesOfString: @" " withString: @""];
	
	// Build URL String for Registration
	// !!! CHANGE "www.mywebsite.com" TO YOUR WEBSITE. Leave out the http://
	// !!! SAMPLE: "secure.awesomeapp.com"
	//NSString *host = @"www.cse.psu.edu";
	
	// !!! CHANGE "/apns.php?" TO THE PATH TO WHERE apns.php IS INSTALLED 
	// !!! ( MUST START WITH / AND END WITH ? ). 
	// !!! SAMPLE: "/path/to/apns.php?"
	NSString *urlString = [NSString stringWithFormat:@"~hannan/COE/apns.php?task=%@&appname=%@&appversion=%@&deviceuid=%@&devicetoken=%@&devicename=%@&devicemodel=%@&deviceversion=%@&pushbadge=%@&pushalert=%@&pushsound=%@", @"register", appName,appVersion, deviceUuid, deviceToken, deviceName, deviceModel, deviceSystemVersion, pushBadge, pushAlert, pushSound];
	
	// Register the Device Data
	// !!! CHANGE "http" TO "https" IF YOU ARE USING HTTPS PROTOCOL
	//NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:host path:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:host path:urlString]; //[urlString stringByExpandingTildeInPath]];
    NSLog(@"URL: %@", url);
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    operationQueue = [[NSOperationQueue alloc] init];
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse* response, NSData* data, NSError* error){
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"Return Data: %@", data);
        }
        
        }];
    
	//NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    //NSLog(@"Return Data: %@", returnData);
	//NSLog(@"Register URL: %@", url);
	
	
#endif
}


/**
 * Failed to Register for Remote Notifications
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	
#if !TARGET_IPHONE_SIMULATOR
	
	NSLog(@"Error in registration. Error: %@", error);
	
#endif
}

/**
 * Remote Notification Received while application was open.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	
#if !TARGET_IPHONE_SIMULATOR
    
//	NSLog(@"remote notification: %@",[userInfo description]);
//	NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
//	
//	NSString *alert = [apsInfo objectForKey:@"alert"];
//	NSLog(@"Received Push Alert: %@", alert);
//	
//	NSString *sound = [apsInfo objectForKey:@"sound"];
//	NSLog(@"Received Push Sound: %@", sound);
//	//AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//	
//	NSString *badge = [apsInfo objectForKey:@"badge"];
//	NSLog(@"Received Push Badge: %@", badge);
//	application.applicationIconBadgeNumber = [[apsInfo objectForKey:@"badge"] integerValue];
    
        
    //NSLog(@"User Info: %@", userInfo);
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    //
    // NSLog(@"New Issue: %@", name);
    
     Library *library = [Library sharedInstance];
    UIApplicationState applicationState = [[UIApplication  sharedApplication] applicationState];
    if (applicationState == UIApplicationStateActive) {  //foreground, alert user
        [library checkForIssues];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Issue Available" message:@"Refresh Library to Download" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    } else {  // in background so we'll download it
        NSString *issueName = [aps objectForKey:@"Name"];
        [library addAndDownloadIssueNamed:issueName];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[aps objectForKey:@"badge"] intValue]];
    }
    
   
//    NSLog(@"Text: %@", library.debugText);
//    library.debugText =  [NSString stringWithFormat:@"UserInfo: %d, %@, %@", [[UIApplication  sharedApplication] applicationState], [NSDate date], userInfo];
//     NSLog(@"Text: %@", library.debugText);
    
    
    
	
#endif
}



@end
