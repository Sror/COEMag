//
//  ModelController.m
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "ModelController.h"

#import "DataViewController.h"
#import "UIImageView+PDFPage.h"



/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */

@interface ModelController()
@property (readonly, strong, nonatomic) NSMutableArray *pageData;
@property size_t count;
@property CGPDFPageRef page;
@property CGPDFDocumentRef pdf;
@property (nonatomic,strong) NSArray *thumbnails;

@property CGFloat pdfScale;   // current pdf zoom scale

@end

@implementation ModelController
@synthesize orientation;
@synthesize pageData;
@synthesize page, pdf, pdfScale;
@synthesize count;
@synthesize thumbnails;

- (id)initWithPDF:(CGPDFDocumentRef)thePDF
{
    self = [super init];
    if (self) {
        
        //set the orientation
        self.orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        // Open the PDF document
		//NSURL *pdfURL = [[NSBundle mainBundle] URLForResource:@"2012winter.pdf" withExtension:nil];
		//pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfURL);
        self.pdf = thePDF;
        self.count = CGPDFDocumentGetNumberOfPages(self.pdf);
        
        // Create the Model
        pageData = [[NSMutableArray alloc] initWithCapacity:(count+1)];  // page numbering starts at 1
        for (int i=0; i<=count; i++) {
            [pageData addObject:[NSNull null]];
        }
        
        // Get the PDF Page that we will be drawing
		//page = CGPDFDocumentGetPage(pdf, 1);
		//CGPDFPageRetain(page);
        //[pageData replaceObjectAtIndex:0 withObject:(__bridge id)page];
        
        // Prep for thumbnail data
        
    }
    return self;
}

-(NSInteger)pageCount {
    return self.count;
}

-(NSArray *) thumbnailViews {
    NSMutableArray *thumbs = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i=1; i<=count; i++) {
        CGPDFPageRef thepage = CGPDFDocumentGetPage(pdf,i);
        UIImageView *thumbView = [UIImageView imageViewFromPage:thepage withWidth:kthumbnailViewWidth];
        [thumbs addObject:thumbView];
    }
    thumbnails = [[NSArray alloc] initWithArray:thumbs];
    return thumbnails;
}

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index
{   
    // Return the data view controller for the given index.
    if (([self.pageData count] == 0) || (index > [self.pageData count])) {
        NSLog(@"Page Number out of range");
        return nil;
    }
    
    DataViewController *dataViewController;
    if ([pageData objectAtIndex:index] == [NSNull null]) {
        if (index==0) {
            dataViewController = [[DataViewController alloc] init];  //blank
        } else {
            // Create a new view controller and pass suitable data.
            CGPDFPageRef p = CGPDFDocumentGetPage(pdf, index);
            dataViewController = [[DataViewController alloc] initWithPage:p];  
        }
        [pageData replaceObjectAtIndex:index withObject:dataViewController];
    } else {
        dataViewController = [pageData objectAtIndex:index];
    }
    return dataViewController;
}


- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard
{   
    // Return the data view controller for the given index.
    if ([self.pageData count] == 0 ) {  //|| (index >= [self.pageData count])
        return nil;
    }
    
    DataViewController *dataViewController;
    
    if (index==0 || index >= [self.pageData count]) {
        //dataViewController = [[DataViewController alloc] init];  //blank
        
        
        if (UIDeviceOrientationIsLandscape(orientation)) {
            dataViewController = [[DataViewController alloc] init];  //blank
        } else {
            dataViewController = nil;  // no extra pages in portrait mode
        }
        
        
    } else if ([pageData objectAtIndex:index] == [NSNull null]) {
            // Create a new view controller and pass suitable data.
            CGPDFPageRef p = CGPDFDocumentGetPage(pdf, index);
            dataViewController = [[DataViewController alloc] initWithPage:p];   //[storyboard instantiateViewControllerWithIdentifier:@"DataViewController"];
         [pageData replaceObjectAtIndex:index withObject:dataViewController];
    }
     else {
        dataViewController = [pageData objectAtIndex:index];
    }
    return dataViewController;
}

- (NSUInteger)indexOfViewController:(DataViewController *)viewController
{   
    // Return the index of the given data view controller.
    // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
 
    NSUInteger index = [self.pageData indexOfObject:viewController];
    NSLog(@"PageData: %d, %@, %@", index, viewController, self.pageData);
    
    return index;
}





#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    index--;
    
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
//    if (index == [self.pageData count]) {
//        return nil;
//    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

@end
