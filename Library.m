//
//  Library.m
//  COEMag
//
//  Created by John Hannan on 4/24/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "Library.h"
#import "Reachability.h"


static NSString *const IssuesPlist = @"Issues.plist";
static NSString *const Host = @"curry.cse.psu.edu";
static NSString *const IssuesURL = @"http://curry.cse.psu.edu/~hannan/COE/Issues.plist";
static NSString *const CoverURLBase = @"http://curry.cse.psu.edu/~hannan/COE/Covers/";
static NSString *const IssueURLBase = @"http://curry.cse.psu.edu/~hannan/COE/Issues/";
//static NSString *const CoverURLBase = @"http://www.engr.psu.edu/EngineeringPennStateMagazine/CoverImages/";
//static NSString *const IssueURLBase = @"http://www.engr.psu.edu/EngineeringPennStateMagazine/";


@interface Library ()
//@property (nonatomic,strong) NSMutableArray* issues;
//@property (nonatomic,strong) NSMutableArray *downloadedIssuesIndices;
@property BOOL showAllIssues;
@property (nonatomic,strong) NSMutableDictionary* coverImages;
-(void)addIssues:(NSArray *)theIssues;

-(NSURL*)urlForIssue:(NKIssue*)nkIssue;
-(NSString *)downloadPathForAsset:(NKAssetDownload *)nkAsset;

@property (nonatomic,strong) Reachability* internetReachable;
@property (nonatomic,strong) Reachability* hostReachable;
@property  NetworkStatus internetStatus;
@property  NetworkStatus hostStatus;
@property BOOL statusUpdated;
@end

@implementation Library
//@synthesize  issues, downloadedIssuesIndices;
@synthesize showAllIssues;
//@synthesize ready;
@synthesize coverImages;
@synthesize debugText;

@synthesize internetReachable, hostReachable, internetStatus, hostStatus, statusUpdated;

+ (id)sharedInstance
{
	static id singleton = nil;
	
	if (singleton == nil) {
		singleton = [[self alloc] init];
    }
	
    return singleton;
}


- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


-(id)init {
    self = [super init];
    if(self) {
        
     
        self.showAllIssues = YES;
        
      
        
        //Check for Reachability
        // check for internet connection
        self.statusUpdated = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
        
        self.internetReachable = [Reachability reachabilityForInternetConnection];
        [internetReachable startNotifier];
        
        // check if a pathway to a random host exists
        self.hostReachable = [Reachability reachabilityWithHostname: Host];
        [hostReachable startNotifier];
        

               
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCompleted:) name:NKIssueDownloadCompletedNotification object:nil];
                
    }
    
    return self;
}

- (void) checkNetworkStatus:(NSNotification *)notice {
    self.internetStatus = [internetReachable currentReachabilityStatus];
    self.hostStatus = [hostReachable currentReachabilityStatus];
    self.statusUpdated = YES;
    
    if (self.internetStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection" message:@"Check Network Status" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];	
    } else     if (self.hostStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Service Not Available" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];	
    } else    {  // We're Reachable!
        // download issues plist if library is empty
        if ([self numberOfIssues] == 0) {
            [self checkForIssues];
        }
        

    }
    
}

-(NKAssetDownload*)nkAssetForIssue:(NKIssue*)nkIssue 
                          withName:(NSString*)name 
                           urlBase:(NSString*)urlBase
                           atIndex:(NSInteger)index{
    NSString *urlString = [urlBase stringByAppendingPathComponent:name];
    //NSLog(@"Cover URL: %@", coverString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    
    NKAssetDownload *nkAsset = [nkIssue addAssetWithRequest:urlRequest];
    //NSInteger index = [issues indexOfObject:dict];
    [nkAsset setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:index],@"Index", 
                          name, @"Name", nil]];
    return nkAsset;
}


// download latest issues plist and update library
-(void)checkForIssues {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:IssuesURL]];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:operationQueue 
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error){
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                               if (data) { // success
                                   NSError *error2;
                                   
                                   NSMutableDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers                                                                                                       format:NULL error:&error2];
                                   
                                   NSArray *theIssues = [dict objectForKey:@"Issues"];
                                   //NSLog(@"Issues: %@", theIssues);
//                                   NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:IssuesPlist];
//                                   if (![issues writeToFile:path atomically:NO]) {
//                                       NSLog(@"Issues plist not saved");
//                                   }
                                   [self addIssues:theIssues];
                                   
                               } else {  
                                   NSLog(@"Failure"); 
                               }
                               
                           }];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

}

// We've just downloaded the list of issues;  add any that aren't in our library already.
-(void)addIssues:(NSArray *)theIssues {
   // coverImages = [[NSMutableDictionary alloc] initWithCapacity:[issuesList count]];
    
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    
    
    for (NSMutableDictionary *dict in theIssues) {
        NSInteger index = [theIssues indexOfObject:dict];
        
        
        //[dict setObject:[NSNumber numberWithInt:index] forKey:@"Index"];  // might be useful;  maybe not?  5/28/12
        
        NSString *name = [dict objectForKey:@"Name"];
        NKIssue *nkIssue = [nkLib issueWithName:name];
        
        if(!nkIssue) {  // not in library, so we add it & request the cover
            //NSLog(@"Adding %@", name);
            nkIssue = [nkLib addIssueWithName:name date:[dict objectForKey:@"Date"]];
            NSString *imageName = [name stringByAppendingString:@".jpg"];
            
            NKAssetDownload *nkAssetCover = [self nkAssetForIssue:nkIssue withName:imageName urlBase:CoverURLBase atIndex:index];
            
            
            //[dict setObject:nkAssetCover forKey:@"CoverAsset"];  // never used
            
            //[dict setObject:[NSNumber numberWithBool:NO] forKey:@"Downloaded"];
            
            /*
            NSString *coverString = [CoverURLBase stringByAppendingPathComponent:imageName];
            NSLog(@"Cover URL: %@", coverString);
            NSURL *coverURL = [NSURL URLWithString:coverString];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:coverURL];
            
            NKAssetDownload *nkAsset = [nkIssue addAssetWithRequest:urlRequest];
           // NSInteger index = [issues indexOfObject:dict];
            [nkAsset setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:index],@"Index", 
                                    imageName, @"Name", nil]];
             */
            
            [nkAssetCover downloadWithDelegate:self];
        } 
//        else {  //already in library. just check if it's been downloaded already
//            NSURL *issueURL = [self urlForIssue:nkIssue];
//            
//            
//            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[issueURL path]];
//            [dict setObject:[NSNumber numberWithBool:fileExists] forKey:@"Downloaded"];
//            if (fileExists) {
//               
//                [self.downloadedIssuesIndices addObject:[NSNumber numberWithInt:index]];
//            }
//        }
        
       // NSLog(@"Issue: %@",[nkIssue description]);
        }
    
//    NSArray *myIssues = [nkLib issues];
//    NSLog(@"Issues: %@", myIssues);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LibraryDidUpdateNotification object:self];
    
}

//-(void)addDownloadedIssuesIndex:(NSInteger)index {
//    int i;
//    for (i=0; i<[downloadedIssuesIndices count] && [[downloadedIssuesIndices objectAtIndex:i] intValue]<index; i++) {
//        ;
//    }
//    [downloadedIssuesIndices insertObject:[NSNumber numberWithInt:index] atIndex:i];
//}

//-(void)removeDownloadedIssuesIndex:(NSInteger)index {
//    [downloadedIssuesIndices removeObject:[NSNumber numberWithInt:index]];
//}


// return array of relevant issues based on whether we're showing all or just downloaded issues
-(NSArray *)relevantIssues {
    NSArray *nkIssues = [[NKLibrary sharedLibrary] issues];
    if (self.showAllIssues) {
        return nkIssues;
    }
    else {
        NSMutableArray *downloadedIssues = [[NSMutableArray alloc] initWithCapacity:[nkIssues count]];
        for (NKIssue *nkIssue in nkIssues) {
            NSURL *issueURL = [self urlForIssue:nkIssue];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[issueURL path]];
            if (fileExists) {
                [downloadedIssues addObject:nkIssue];
            }
        }
        return downloadedIssues;
    }
}

-(NSInteger)numberOfIssues {
    NSArray *nkIssues = [self relevantIssues];
    return [nkIssues count];    
}

//-(NSInteger)convertIndex:(NSInteger)index {
//    if (!showAllIssues) {
//        index = [[downloadedIssuesIndices objectAtIndex:index] intValue];
//    }
//    return index;
//}

-(NKIssue *)issueAtIndex:(NSInteger)index {
    NSArray *nkIssues = [self relevantIssues];
    return [nkIssues objectAtIndex:index];
}

-(NSInteger)indexOfIssue:(NKIssue*)nkIssue {
    NSArray *nkIssues = [self relevantIssues];
    return [nkIssues indexOfObject:nkIssue];
}
   

// e.g. Springsummer --> Spring/Summer
-(NSString *)modifySeason:(NSString *)season {
    NSString *newSeason;
    if ([season isEqualToString:@"Springsummer"]) {
        newSeason = @"Spring/Summer";
    } else {
        newSeason = season;
    }
    return newSeason;
}

// example name: 2007fall  
// example Title: Fall 2007
-(NSString*)titleForName:(NSString*)name {
    NSString *year = [name substringToIndex:4];
    NSString *season = [[name substringFromIndex:4] capitalizedString];
    NSString *newSeason = [self modifySeason:season];
    NSString *title = [NSString stringWithFormat:@"%@ %@", newSeason, year];
    return title;
}


-(NSString *)titleOfIssueAtIndex:(NSInteger)index {
    NKIssue *issue = [self issueAtIndex:index];
    NSString *title = [self titleForName:[issue name]];
    return title;    
}


-(UIImage *)coverImageOfIssueAtIndex:(NSInteger)index {
    NKIssue *issue = [self issueAtIndex:index];
    NSURL *contentURL = [issue contentURL];
    NSString *name = [[issue name] stringByAppendingString:@".jpg"];
    NSURL *imageURL = [NSURL URLWithString:name relativeToURL:contentURL];
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    UIImage *image = [UIImage imageWithData:imageData];
    return image;
}

-(BOOL)issueDownloadedAtIndex:(NSInteger)index {
    NKIssue *nkIssue = [self issueAtIndex:index];
    
    NSURL *issueURL = [self urlForIssue:nkIssue];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[issueURL path]];
    return fileExists;
}

-(void)deleteIssueAtIndex:(NSInteger)index {
    NKIssue *nkIssue = [self issueAtIndex:index];
    NSString *name = [nkIssue name];
    NSString *pdfName = [name stringByAppendingFormat:@".pdf"];
    
    //index = [self convertIndex:index];
    //NSMutableDictionary* issueDictionary = [issues objectAtIndex:index];
    //NSString *name = [issueDictionary objectForKey:@"Name"];
    
    //NKLibrary *nkLib = [NKLibrary sharedLibrary];
    //NKIssue *nkIssue = [nkLib issueWithName:name];
    
    NSString *contentPath = [[nkIssue.contentURL path] stringByAppendingPathComponent:pdfName];
    NSError *removeError=nil;
    BOOL result = [[NSFileManager defaultManager] removeItemAtPath:contentPath error:&removeError];
    if (result) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"Index"];
        [[NSNotificationCenter defaultCenter] postNotificationName:LibraryAssetUpdateNotification object:self userInfo:userInfo];
    } else {
         NSLog(@"Error removing file %@",contentPath);
    }
    
}

-(BOOL)currentlyDownloadingIssue:(NSInteger)index {
    NKIssue *nkIssue = [self issueAtIndex:index];
    
    return  ([nkIssue status] == NKIssueContentStatusDownloading);
}

-(void)addAndDownloadIssueNamed:(NSString *)issueName {
    NSDate *dateNow = [NSDate date];
    NSInteger index = 0;  // new issue will be at index 0
    
    //add to issues array
//    NSDictionary *issueDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:issueName, @"Name", dateNow, @"Date", [NSNumber numberWithBool:NO], @"Downloaded", nil];
//    [issues insertObject:issueDictionary atIndex:index];  // newest entry is first one
    
    //create the issue in the library
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NKIssue *nkIssue = [nkLib addIssueWithName:issueName date:dateNow];
    
    //download cover
    NSString *imageName = [issueName stringByAppendingString:@".jpg"];
    NKAssetDownload *nkAssetCover = [self nkAssetForIssue:nkIssue withName:imageName urlBase:CoverURLBase atIndex:index];
    [nkAssetCover downloadWithDelegate:self];
    
    //download the pdf
    [self downloadIssueAtIndex:index];
    
    
}

-(void)downloadIssueAtIndex:(NSInteger)index {
    NKIssue *nkIssue = [self issueAtIndex:index];
    NSString *name = [nkIssue name];
    NSString *pdfName = [name stringByAppendingString:@".pdf"];
    
    NKAssetDownload *nkAssetPDF = [self nkAssetForIssue:nkIssue withName:pdfName urlBase:IssueURLBase atIndex:index];
    [nkAssetPDF downloadWithDelegate:self];
}

-(void)downloadCompleted:(NSNotification*)notification {
    NKIssue *nkIssue = [notification object];
    NSInteger index = [self indexOfIssue:nkIssue];
           
    // now notify the tableview controller to update this cell
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:index ]forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:LibraryAssetUpdateNotification object:self userInfo:dictionary];
    
}

-(void)updateIcon:(NSString *)iconPath {
    
}

#pragma mark - NSURLConnectionDownloadDelegate Protocol
-(void)updateProgressOfConnection:(NSURLConnection *)connection withTotalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    // get asset
   // NKAssetDownload *dnl = [connection newsstandAssetDownload];
    //UITableViewCell *cell = [table_ cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[[dnl.userInfo objectForKey:@"Index"] intValue] inSection:0]];
   // UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:102]; progressView.alpha=1.0;
    //[[cell viewWithTag:103] setAlpha:0.0]; progressView.progress=1.f*totalBytesWritten/expectedTotalBytes;
}

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    
    CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat)(expectedTotalBytes);
    NSNumber *downloadProgress = [NSNumber numberWithFloat:progress];
    NKAssetDownload *nkAsset = [connection newsstandAssetDownload];
    //NKIssue *nkIssue = [nkAsset issue];
    NSDictionary *dictionary = [nkAsset userInfo];
    NSDictionary *progressDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [dictionary objectForKey:@"Index"], @"Index",
                                        downloadProgress, @"Progress",
                                        nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:LibraryProgressUpdateNotification object:self userInfo:progressDictionary];
    
}

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL {
    //NSLog(@"Wrote to %@", [[destinationURL path] description]);
   // [[NSNotificationCenter defaultCenter] postNotificationName:LibraryDidUpdateNotification object:nil];
    
    // copy file to destination URL
    NKAssetDownload *nkAsset = [connection newsstandAssetDownload];
    //NKIssue *nkIssue = [nkAsset issue];
    NSDictionary *dictionary = [nkAsset userInfo];
    
    NSString *contentPath = [self downloadPathForAsset:nkAsset]; 
    NSError *moveError=nil;
    if([[NSFileManager defaultManager] moveItemAtPath:[destinationURL path] toPath:contentPath error:&moveError]==NO) {
        NSLog(@"Error copying file from %@ to %@",destinationURL,contentPath);
    } else {
        //NSLog(@"Copied file from %@ to %@",destinationURL,contentPath);
        [[NSNotificationCenter defaultCenter] postNotificationName:LibraryAssetUpdateNotification object:self userInfo:dictionary];
    }
    
    NSNumber *number = [dictionary objectForKey:@"Index"];
    NSInteger index = [number intValue];
    if (index == 0) {
        [self updateIcon:contentPath];
    }
    
}

- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    [self connection:connection didWriteData:0 totalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
    
}

-(NSString *)downloadPathForAsset:(NKAssetDownload *)nkAsset{
    NKIssue *nkIssue = [nkAsset issue];
    NSDictionary *dictionary = [nkAsset userInfo];
    NSString *name = [dictionary objectForKey:@"Name"];
    return [[nkIssue.contentURL path] stringByAppendingPathComponent:name];
}

-(NSURL*)urlForIssue:(NKIssue*)nkIssue {
    NSURL *urlbase = [nkIssue contentURL];
    NSString *name = [nkIssue name];
    NSString *issueName = [name stringByAppendingString:@".pdf"];
    NSURL *urlIssue = [NSURL URLWithString:issueName relativeToURL:urlbase];
    return urlIssue;
    
}

// get a document to read, and make it the current issue
-(CGPDFDocumentRef)PDFForIssueAtIndex:(NSInteger)index {
    NKIssue *nkIssue = [self issueAtIndex:index];
    NSURL *issueURL = [self urlForIssue:nkIssue];
    //NSLog(@"Getting pdf from %@", issueURL);
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)issueURL);
    
    // make current issue
    NKLibrary *nkLibrary = [NKLibrary sharedLibrary];
    nkLibrary.currentlyReadingIssue = nkIssue;
    
    return pdf;
}

-(void)toggleIssuesToShow {
    self.showAllIssues = !self.showAllIssues;
}

@end
