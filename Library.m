//
//  Library.m
//  COEMag
//
//  Created by John Hannan on 4/24/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "Library.h"


static NSString *const IssuesURL = @"http://www.cse.psu.edu/~hannan/Issues.plist";
static NSString *const CoverURLBase = @"http://www.engr.psu.edu/EngineeringPennStateMagazine/CoverImages/";
static NSString *const IssueURLBase = @"http://www.engr.psu.edu/EngineeringPennStateMagazine/";

@interface Library ()
@property (nonatomic,strong) NSArray* issues;
@property (nonatomic,strong) NSMutableDictionary* coverImages;
-(void)addIssues;
-(NSURL*)urlForIssue:(NKIssue*)nkIssue;
-(NSString *)downloadPathForAsset:(NKAssetDownload *)nkAsset;
@end

@implementation Library
@synthesize  issues;
@synthesize ready;
@synthesize coverImages;

-(id)init {
    self = [super init];
    if(self) {
        ready = NO;
        issues = nil;
        
        issues = [[NSMutableArray alloc] initWithCapacity:75];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listReady:) name:LibraryDidUpdateNotification object:self];
        
        
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:IssuesURL]];
        
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:operationQueue 
                               completionHandler:^(NSURLResponse* response, NSData* data, NSError* error){
                                   [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                   if (data) { // success
                                       NSError *error2;
                                       
                                       NSMutableDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers                                                                                                       format:NULL error:&error2];
                                       //NSLog(@"dict: %@", dict);
                                       issues = [dict objectForKey:@"Issues"];
                                       //NSLog(@"Issues: %d", [issues count]);
                                       [self addIssues];
                                       
                                       
                                       
                                   } else {  
                                       NSLog(@"Failure"); 
                                       // failure
                                       //[[NSNotificationCenter defaultCenter] postNotificationName:LibraryFailedUpdateNotification object:issues];
                                   }
                                   ready = YES;
                               }];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    //NSLog(@"Library init");
    return self;
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

// We've just downloaded the list of issues;  add any that aren't in our library already.
-(void)addIssues {
   // coverImages = [[NSMutableDictionary alloc] initWithCapacity:[issuesList count]];
    
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    
    for (NSMutableDictionary *dict in issues) {
        NSInteger index = [issues indexOfObject:dict];
        NSString *name = [dict objectForKey:@"Name"];
        NKIssue *nkIssue = [nkLib issueWithName:name];
        if(!nkIssue) {
            nkIssue = [nkLib addIssueWithName:name date:[dict objectForKey:@"Date"]];
            NSString *imageName = [name stringByAppendingString:@".jpg"];
            
            NKAssetDownload *nkAssetCover = [self nkAssetForIssue:nkIssue withName:imageName urlBase:CoverURLBase atIndex:index];
            
            
            [dict setObject:nkAssetCover forKey:@"CoverAsset"];
            
            [dict setObject:[NSNumber numberWithBool:NO] forKey:@"Downloaded"];
            
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
        } else {  //already in library. just check if it's been downloaded already
            NSURL *issueURL = [self urlForIssue:nkIssue];
            
            
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[issueURL path]];
            [dict setObject:[NSNumber numberWithBool:fileExists] forKey:@"Downloaded"];
            
        }
        
       // NSLog(@"Issue: %@",[nkIssue description]);
        }
    //NSLog(@"Number of Issues: %d,%d", [self numberOfIssues],[[nkLib issues] count]);
    [[NSNotificationCenter defaultCenter] postNotificationName:LibraryDidUpdateNotification object:self];
    
}

-(NSInteger)numberOfIssues {
    return [issues count];
}
//-(NSInteger)numberOfIssues {
//    NKLibrary *nkLibrary = [NKLibrary sharedLibrary];
//    return [[nkLibrary issues] count];
//}


-(NKIssue *)issueAtIndex:(NSInteger)index {
    NSDictionary *issueDictionary = [issues objectAtIndex:index];
    NSString *name = [issueDictionary objectForKey:@"Name"];
    NKLibrary *nkLibrary = [NKLibrary sharedLibrary];
    //NSArray *issues2 = [nkLibrary issues];
    NKIssue *issue = [nkLibrary issueWithName:name];   //[issues2 objectAtIndex:index];
    return issue;
}

-(NSInteger)indexOfIssue:(NKIssue*)nkIssue {
    NSString *name = [nkIssue name];
    for (int i=0; i<[issues count]; i++) {
        if ([[[issues objectAtIndex:i] objectForKey:@"Name"] isEqualToString:name]) {
            return i;
        }
    }
    return -1;
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
    NSDictionary* issueDictionary = [issues objectAtIndex:index];
    BOOL downloaded = [[issueDictionary objectForKey:@"Downloaded"] boolValue];
    return downloaded;
}


-(void)downloadIssueAtIndex:(NSInteger)index {
    //NKIssue *nkIssue = [self issueAtIndex:index];
    NSMutableDictionary* issueDictionary = [issues objectAtIndex:index];
    NSString *name = [issueDictionary objectForKey:@"Name"];
    NSString *pdfName = [name stringByAppendingString:@".pdf"];
    
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NKIssue *nkIssue = [nkLib issueWithName:name];
    
    NKAssetDownload *nkAssetPDF = [self nkAssetForIssue:nkIssue withName:pdfName urlBase:IssueURLBase atIndex:index];
    [issueDictionary setObject:nkAssetPDF forKey:@"PDFAsset"];
    
    [nkAssetPDF downloadWithDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCompleted:) name:NKIssueDownloadCompletedNotification object:nil];
    
}

-(void)downloadCompleted:(NSNotification*)notification {
    NKIssue *nkIssue = [notification object];
    NSInteger index = [self indexOfIssue:nkIssue];
    NSMutableDictionary *issueDictionary = [issues objectAtIndex:index];
    [issueDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"Downloaded"];
    
    // now notify the tableview controller to update this cell
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:index ]forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:LibraryAssetUpdateNotification object:self userInfo:dictionary];
    
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
    //[table_ reloadData];

}

- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    
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

-(CGPDFDocumentRef)PDFForIssueAtIndex:(NSInteger)index {
    NKIssue *nkIssue = [self issueAtIndex:index];
    NSURL *issueURL = [self urlForIssue:nkIssue];
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)issueURL);
    return pdf;
}

@end
