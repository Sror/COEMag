//
//  RootViewController.m
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "RootViewController.h"
#import "ModelController.h"
#import "DataViewController.h"

#define kthumbnailScrollViewHeight 150
//#define kthumbnailViewHeight 100

@interface RootViewController ()
@property (readonly, strong, nonatomic) ModelController *modelController;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIScrollView *thumbnailScrollView;
@property (nonatomic,strong) NSTimer *timer;

@property BOOL toolbarHidden;
-(void)hideToolbar;
-(void)showToolbar;
-(void)addThumbnails;

@end

@implementation RootViewController

@synthesize toolbar = _toolbar;
@synthesize pageViewController = _pageViewController;
@synthesize modelController = _modelController;
@synthesize scrollView, thumbnailScrollView;
@synthesize toolbarHidden;
@synthesize timer;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Configure the page view controller and add it as a child view controller.
    
    // set up the top-level scroll view for zooming
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    // Set up the UIScrollView
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = YES;
    self.scrollView.bouncesZoom = YES;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.scrollView.delegate = self;
    [self.scrollView setBackgroundColor:[UIColor grayColor]];
    self.scrollView.maximumZoomScale = 5.0;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    // set up the PageViewController
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    
    DataViewController *startingViewController = [self.modelController viewControllerAtIndex:1 storyboard:self.storyboard];
    NSArray *viewControllers = [NSArray arrayWithObject:startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    self.pageViewController.dataSource = self.modelController;
    
    [self addChildViewController:self.pageViewController];
    [self.scrollView addSubview:self.pageViewController.view];
    
    // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
//    CGRect pageViewRect = self.view.bounds;
//    pageViewRect = CGRectInset(pageViewRect, 0.0, 0.0);
//    self.pageViewController.view.frame = pageViewRect;
    
    [self.pageViewController didMoveToParentViewController:self];
    
    // Add the thumbnail scroll view
    CGRect bounds = self.view.bounds;
    CGRect frame = CGRectMake(0.0, bounds.size.height-kthumbnailScrollViewHeight, bounds.size.width, kthumbnailScrollViewHeight);
    self.thumbnailScrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.thumbnailScrollView.backgroundColor = [UIColor lightGrayColor];
    self.thumbnailScrollView.alpha = 0.6;
    self.thumbnailScrollView.delegate = self;
    self.thumbnailScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addThumbnails];
    
//    UIView *backgroundView = [[UIView alloc] initWithFrame:self.thumbnailScrollView.bounds];
//    backgroundView.backgroundColor = [UIColor lightGrayColor];
//    backgroundView.alpha = 0.5;
    //[self.thumbnailScrollView addSubview:backgroundView];
    [self.view addSubview:thumbnailScrollView];
    [self.view bringSubviewToFront:self.thumbnailScrollView];
    
    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    //[self hideToolbar];
    //self.toolbarHidden = YES;
    [self.view bringSubviewToFront:self.toolbar];
}


- (void)viewDidUnload
{
    [self setToolbar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.scrollView = nil;
    self.pageViewController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    //reset zoom
    [self.scrollView setZoomScale:1.0 animated:YES];
    // redisplay pages
    for (DataViewController* d in self.pageViewController.viewControllers) {
        [d loadPage];
    }
    
    //reposition thumbnail scrollview
    CGRect frame = self.thumbnailScrollView.frame;
    CGFloat height = self.view.bounds.size.height + (self.toolbarHidden ? 0.0 : - kthumbnailScrollViewHeight);
    frame = CGRectMake(0.0, height, frame.size.width, frame.size.height);
    self.thumbnailScrollView.frame = frame;
}


- (ModelController *)modelController
{
    // Return the model controller object, creating it if necessary.
    // In more complex implementations, the model controller may be passed to the view controller.
    if (!_modelController) {
        _modelController = [[ModelController alloc] init];
    }
    return _modelController;
}

// add thumbnail images to thumbnail scrollview
-(void)addThumbnails {
    // remove any buttons on scrollView
    [[self.thumbnailScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSArray *thumbnailViews = [self.modelController thumbnailViews];
    UIImageView *imageView = [thumbnailViews objectAtIndex:1];
    CGFloat width =  imageView.bounds.size.width;
    NSInteger count = [thumbnailViews count];
    self.thumbnailScrollView.contentSize = CGSizeMake((count * 2) * width, self.thumbnailScrollView.bounds.size.height);
    
    for (int i=0; i<count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImageView *buttonImage = [thumbnailViews objectAtIndex:i];
        CGRect frame = buttonImage.bounds;
        frame = CGRectMake((2*i+1)*width, 10.0, frame.size.width, frame.size.height);
        button.frame = frame;
        [button setImage:buttonImage.image forState:UIControlStateNormal];
        button.tag = i+1;
        [button addTarget:self action:@selector(thumbnailSelected:) forControlEvents:UIControlEventTouchUpInside];
        [self.thumbnailScrollView addSubview:button];
        
    }
}

-(void)thumbnailSelected:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger page = button.tag;
    DataViewController *currentViewController = [self.modelController viewControllerAtIndex:page];
    NSArray *viewControllers = [NSArray arrayWithObject:currentViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
}

#pragma mark - UIPageViewController delegate methods


- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    [self.scrollView setZoomScale:1.0 animated:YES];
}


- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        // In portrait orientation: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to YES, so set it to NO here.
        UIViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        NSArray *viewControllers = [NSArray arrayWithObject:currentViewController];
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
        
        self.pageViewController.doubleSided = NO;
        
        
        
        
        return UIPageViewControllerSpineLocationMin;
    }
    
    // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
    DataViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    
    NSArray *viewControllers = nil;
    
    NSUInteger indexOfCurrentViewController = [self.modelController indexOfViewController:currentViewController];
    if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0) {
        UIViewController *nextViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
        viewControllers = [NSArray arrayWithObjects:currentViewController, nextViewController, nil];
        
    } else {
        UIViewController *previousViewController = [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
        viewControllers = [NSArray arrayWithObjects:previousViewController, currentViewController, nil];
        
    }
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    
    
    return UIPageViewControllerSpineLocationMid;
}


#pragma mark -
#pragma mark UIScrollView delegate methods

// A UIScrollView delegate callback, called when the user starts zooming. 
// We return our current TiledPDFView.
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.pageViewController.view;
}

/*
 // A UIScrollView delegate callback, called when the user stops zooming.  When the user stops zooming
 // we create a new TiledPDFView based on the new zoom level and draw it on top of the old TiledPDFView.
 - (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
 {
 // set the new scale factor for the TiledPDFView
 pdfScale *=scale;
 
 // Calculate the new frame for the new TiledPDFView
 CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
 pageRect.size = CGSizeMake(pageRect.size.width*pdfScale, pageRect.size.height*pdfScale);
 
 // Create a new TiledPDFView based on new frame and scaling.
 pdfView = [[TiledPDFView alloc] initWithFrame:pageRect andScale:pdfScale];
 [pdfView setPage:page];
 
 // Add the new TiledPDFView to the PDFScrollView.
 [self.view addSubview:pdfView];
 }
 
 // A UIScrollView delegate callback, called when the user begins zooming.  When the user begins zooming
 // we remove the old TiledPDFView and set the current TiledPDFView to be the old view so we can create a
 // a new TiledPDFView when the zooming ends.
 - (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
 {
 // Remove back tiled view.
 [oldPDFView removeFromSuperview];
 //[oldPDFView release];
 
 // Set the current TiledPDFView to be the old view.
 oldPDFView = pdfView;
 [self.view addSubview:oldPDFView];
 }
 */

#pragma mark - Tap Gesture
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    //CGPoint location = [touch locationInView:self.view];
    if ([touch.view isKindOfClass:[UIButton class]]) {      //change it to your condition
        return NO;
    }
//    if (location.y > self.view.bounds.size.height * 0.8) {
//        return NO;
//    }
    return YES;
}

-(void)handleTap:(id)sender {
    //UITapGestureRecognizer *tapGesture = (UITapGestureRecognizer*)sender;
    NSLog(@"Tapped");
    if (self.toolbarHidden) {
        [self showToolbar];
    } else {
        [self hideToolbar];
    }
}


-(void)hideToolbar {
    [timer invalidate];
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect newtoolbarFrame = CGRectOffset(toolbarFrame, 0.0, -toolbarFrame.size.height);
    CGRect scrollbarFrame = self.thumbnailScrollView.frame;
    CGRect newscrollbarFrame = CGRectOffset(scrollbarFrame, 0.0, scrollbarFrame.size.height);
    [UIView animateWithDuration:1.0 animations:^{
        self.toolbar.frame = newtoolbarFrame;
        self.thumbnailScrollView.frame = newscrollbarFrame;}];
    self.toolbarHidden = YES;
}

-(void)showToolbar {
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect newtoolbarFrame = CGRectOffset(toolbarFrame, 0.0, +toolbarFrame.size.height);
    CGRect scrollbarFrame = self.thumbnailScrollView.frame;
    CGRect newscrollbarFrame = CGRectOffset(scrollbarFrame, 0.0, -scrollbarFrame.size.height);
    [UIView animateWithDuration:1.0 animations:^{
        self.toolbar.frame = newtoolbarFrame;
        self.thumbnailScrollView.frame = newscrollbarFrame;}];
    timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideToolbar) userInfo:nil repeats:NO];
    self.toolbarHidden = NO;
}



@end
