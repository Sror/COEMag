//
//  Library.h
//  COEMag
//
//  Created by John Hannan on 4/24/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NewsstandKit/NewsstandKit.h>

@interface Library : NSObject <NSURLConnectionDownloadDelegate>

//@property (nonatomic,readonly,getter = isReady) BOOL ready;



+ (id)sharedInstance;

-(NSInteger)numberOfIssues;
-(NSString *)titleOfIssueAtIndex:(NSInteger)index;
-(UIImage *)coverImageOfIssueAtIndex:(NSInteger)index;
-(BOOL)issueDownloadedAtIndex:(NSInteger)index;
-(void)downloadIssueAtIndex:(NSInteger)index;
-(void)deleteIssueAtIndex:(NSInteger)index;
-(BOOL)currentlyDownloadingIssue:(NSInteger)index;

-(CGPDFDocumentRef)PDFForIssueAtIndex:(NSInteger)index;

-(void)checkForIssues;

@end
