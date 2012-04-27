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
-(void)addIssues:(NSArray*)issues;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listReady:) name:LibraryDidUpdateNotification object:self];
        
        
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:IssuesURL]];
        
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:operationQueue 
                               completionHandler:^(NSURLResponse* response, NSData* data, NSError* error){
                                   [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                   if (data) { // success
                                       NSError *error2;
                                       
                                       NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable
                                                                                                       format:NULL error:&error2];
                                       NSLog(@"dict: %@", dict);
                                       issues = [dict objectForKey:@"Issues"];
                                       [self addIssues:issues];
                                       
                                       [[NSNotificationCenter defaultCenter] postNotificationName:LibraryDidUpdateNotification object:issues];
                                       
                                   } else {  // failure
                                       [[NSNotificationCenter defaultCenter] postNotificationName:LibraryFailedUpdateNotification object:issues];
                                   }
                                   ready = YES;
                               }];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    return self;
}


// We've just downloaded the list of issues;  add any that aren't in our library already.
-(void)addIssues:(NSArray *)issuesList {
    coverImages = [[NSMutableDictionary alloc] initWithCapacity:[issuesList count]];
    NSLog(@"IssuesList: %@", issuesList);
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    
    for (NSDictionary *dict in issuesList) {
        NSString *name = [dict objectForKey:@"Name"];
        NKIssue *nkIssue = [nkLib issueWithName:name];
        if(!nkIssue) {
            nkIssue = [nkLib addIssueWithName:name date:[dict objectForKey:@"Date"]];
            NSString *imageName = [name stringByAppendingString:@".jpg"];
            NSString *coverString = [CoverURLBase stringByAppendingPathComponent:imageName];
            NSLog(@"Cover URL: %@", coverString);
            NSURL *coverURL = [NSURL URLWithString:coverString];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:coverURL];
            
            NKAssetDownload *nkAsset = [nkIssue addAssetWithRequest:urlRequest];
            NSInteger index = [issuesList indexOfObject:dict];
            [nkAsset setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:index],@"Index", 
                                    name, @"Name", nil]];
            [nkAsset downloadWithDelegate:self];
        }
        
       // NSLog(@"Issue: %@",[nkIssue description]);
        }
}

-(NSInteger)numberOfIssues {
    NKLibrary *nkLibrary = [NKLibrary sharedLibrary];
    return [[nkLibrary issues] count];
}

-(NKIssue *)issueAtIndex:(NSInteger)index {
    NKLibrary *nkLibrary = [NKLibrary sharedLibrary];
    NSArray *issues2 = [nkLibrary issues];
    NKIssue *issue = [issues2 objectAtIndex:index];
    return issue;
}

-(NSString *)titleOfIssueAtIndex:(NSInteger)index {
    NKIssue *issue = [self issueAtIndex:index];
    return [issue name];    
}

-(UIImage *)coverImageOfIssueAtIndex:(NSInteger)index {
    NKIssue *issue = [self issueAtIndex:index];
    NSURL *contentURL = [issue contentURL];
    NSString *name = [issue name];
    NSURL *imageURL = [NSURL URLWithString:name relativeToURL:contentURL];
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    UIImage *image = [UIImage imageWithData:imageData];
    return image;
}


#pragma mark - NSURLConnectionDownloadDelegate Protocol
-(void)updateProgressOfConnection:(NSURLConnection *)connection withTotalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    // get asset
    NKAssetDownload *dnl = [connection newsstandAssetDownload];
    //UITableViewCell *cell = [table_ cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[[dnl.userInfo objectForKey:@"Index"] intValue] inSection:0]];
   // UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:102]; progressView.alpha=1.0;
    //[[cell viewWithTag:103] setAlpha:0.0]; progressView.progress=1.f*totalBytesWritten/expectedTotalBytes;
}

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    [self updateProgressOfConnection:connection
      withTotalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
}

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL {
    NSLog(@"Wrote to %@", [[destinationURL path] description]);
    [[NSNotificationCenter defaultCenter] postNotificationName:LibraryDidUpdateNotification object:nil];
    
    // copy file to destination URL
    NKAssetDownload *nkAsset = [connection newsstandAssetDownload];
    //NKIssue *nkIssue = [nkAsset issue];
    NSDictionary *dictionary = [nkAsset userInfo];
    
    NSString *contentPath = [self downloadPathForAsset:nkAsset]; 
    NSError *moveError=nil;
    if([[NSFileManager defaultManager] moveItemAtPath:[destinationURL path] toPath:contentPath error:&moveError]==NO) {
        NSLog(@"Error copying file from %@ to %@",destinationURL,contentPath);
    } else {
        NSLog(@"Copied file from %@ to %@",destinationURL,contentPath);
        [[NSNotificationCenter defaultCenter] postNotificationName:LibraryAssetUpdateNotification object:issues userInfo:dictionary];
    }
    //[table_ reloadData];

}

- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    
}

-(NSString *)downloadPathForAsset:(NKAssetDownload *)nkAsset {
    NKIssue *nkIssue = [nkAsset issue];
    NSDictionary *dictionary = [nkAsset userInfo];
    NSString *name = [[dictionary objectForKey:@"Name"] stringByAppendingString:@".pdf"];
    return [[nkIssue.contentURL path] stringByAppendingPathComponent:name];
}

@end
