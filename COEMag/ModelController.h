//
//  ModelController.h
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataViewController;

@interface ModelController : NSObject <UIPageViewControllerDataSource>

@property UIDeviceOrientation orientation;

-(id)initWithPDF:(CGPDFDocumentRef)pdf;
- (DataViewController *)viewControllerAtIndex:(NSUInteger)index;
- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(DataViewController *)viewController;
- (NSArray *)thumbnailViews;
-(NSInteger)pageCount;
-(void)clearModel;
-(void)clearPage:(NSInteger)pageNumber;

@end
