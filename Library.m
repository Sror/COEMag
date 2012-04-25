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
                                       issues = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable
                                                                                           format:NULL error:&error2];
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
    
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    
    for (NSDictionary *dict in issuesList) {
        NSString *name = [dict objectForKey:@"Name"];
        NKIssue *nkIssue = [nkLib issueWithName:name];
        if(!nkIssue) {
            nkIssue = [nkLib addIssueWithName:name date:[dict objectForKey:@"Date"]];
            
            NSString *coverString = [CoverURLBase stringByAppendingPathComponent:name];
            NSURL *coverURL = [NSURL URLWithString:coverString];
            NSData *imageData = [NSData dataWithContentsOfURL:coverURL];
            [imageData writeToFile:imageString atomically:YES];
            UIImage *coverImage = [UIImage imageWithData:imageData];
            [coverImages setObject:coverImage  forKey:name];
        }
        
        NSString *contentString = [[nkIssue contentURL] absoluteString];
        NSString *imageString = [contentString stringByAppendingPathComponent:name];
        NSLog(@"Issue: %@",nkIssue);
        }
}

-(NSInteger)numberOfIssues {
    NKLibrary *nkLibrary = [NKLibrary sharedLibrary];
    return [[nkLibrary issues] count];
}

-(NSString *)nameOfIssueAtIndex:(NSInteger)index {
    NKLibrary *nkLibrary = [NKLibrary sharedLibrary];
    NSArray *issues2 = [nkLibrary issues];
    NKIssue *issue = [issues2 objectAtIndex:index];
    return [issue name];    
}


@end
