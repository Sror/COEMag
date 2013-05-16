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
#import "TiledPDFView.h"

#define kthumbnailScrollViewHeight 150
#define kthumbnailOffset 10
//#define kthumbnailViewHeight 100
#define ktimerDuration 3.0
#define kanimateDuration 0.5
#define kbarHeight 25.0

@interface RootViewController ()
@property (assign,nonatomic) CGPDFDocumentRef pdf;
@property (readonly, strong, nonatomic) ModelController *modelController;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIScrollView *thumbnailScrollView;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) UIView *bottomBar;

@property BOOL toolbarHidden;
-(void)hideToolbar;
-(void)showToolbar;
-(void)addThumbnails;
-(void)scheduleTimer;

@end

@implementation RootViewController

@synthesize toolbar = _toolbar;
@synthesize pageViewController = _pageViewController;
@synthesize modelController = _modelController;
@synthesize scrollView, thumbnailScrollView;
@synthesize toolbarHidden;
@synthesize timer;
@synthesize bottomBar;
@synthesize delegate;
@synthesize pdf;

-(void)viewDidAppear:(BOOL)animated  {
    self.view.backgroundColor = [UIColor redColor];
    //CGRect frame = self.view.frame;
    
    
        //CGRect newFrame = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
        //self.view.frame = newFrame;
    
}

-(void)setPdf:(CGPDFDocumentRef)aPdf {
    CGPDFDocumentRelease(pdf);
    pdf = aPdf;
    CGPDFDocumentRetain(pdf);
}

- (void)setupScrollView
{
    // set up the top-level scroll view for zooming
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    // Set up the UIScrollView
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = YES;
    self.scrollView.bouncesZoom = YES;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.scrollView.delegate = self;
    
    self.scrollView.maximumZoomScale = 5.0;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    self.scrollView.backgroundColor = [UIColor blackColor];
}

-(void)setupPageView {
    // determine spine position for pageViewController
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
       
    NSNumber *spine = [NSNumber numberWithInt:(UIDeviceOrientationIsLandscape(orientation)? UIPageViewControllerSpineLocationMid : UIPageViewControllerSpineLocationMin)];
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys: spine, UIPageViewControllerOptionSpineLocationKey, nil];
    
    
    // set up the PageViewController
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options];
    self.pageViewController.view.frame = self.scrollView.bounds;
    
    //CGRect pageFrame = self.pageViewController.view.frame;
    //CGRect newPageFrame = CGRectMake(0.0, 0.0, pageFrame.size.width, pageFrame.size.height);
    //self.pageViewController.view.frame = newPageFrame;
    
    [self.pageViewController.view setBackgroundColor:[UIColor blueColor]];
    
    self.pageViewController.delegate = self;
    //NSLog(@"PageView's Gestures: %@", self.pageViewController.view.gestureRecognizers);
    
    // start on page 1
    DataViewController *startingViewController = [self.modelController viewControllerAtIndex:1 storyboard:self.storyboard];
    
    // Portrait or Landscape
    NSArray *viewControllers;
    
    if (UIDeviceOrientationIsLandscape(orientation)) {
        DataViewController *blankViewController = [[DataViewController alloc] init];
        viewControllers = [NSArray arrayWithObjects:blankViewController,startingViewController,nil];
    } else {
        viewControllers = [NSArray arrayWithObject:startingViewController];
    }
    
    
    
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    self.pageViewController.dataSource = self.modelController;
    
    [self addChildViewController:self.pageViewController];
    [self.scrollView addSubview:self.pageViewController.view];
    
     [self.pageViewController didMoveToParentViewController:self];
}

-(void)setupThumbnailView {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // Add the thumbnail scroll view
    CGRect bounds = self.view.bounds;
    
    CGFloat yCoord = bounds.size.height-kthumbnailScrollViewHeight;
    CGFloat xCoord = bounds.size.width-kthumbnailScrollViewHeight;
    if (UIDeviceOrientationIsLandscape(orientation) && xCoord < yCoord)
        yCoord = xCoord;  // seems like a hack
    CGRect frame = CGRectMake(0.0, yCoord, bounds.size.width, kthumbnailScrollViewHeight);
    
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

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // Configure the page view controller and add it as a child view controller.
    
    self.toolbar.barStyle = UIBarStyleBlackTranslucent;
    self.toolbar.translucent = YES;
}

-(void)viewWillAppear:(BOOL)animated {
            
    [self setupScrollView];
    [self setupPageView];
    [self setupThumbnailView];
    
   
    
    /*
    // add bar at bottom of pageView
    CGRect barFrame = CGRectMake(0.0, pageFrame.size.height-kbarHeight, pageFrame.size.width, pageFrame.size.height);
    self.bottomBar = [[UIView alloc] initWithFrame:barFrame];
    self.bottomBar.backgroundColor = [UIColor blueColor];
    self.bottomBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:self.bottomBar belowSubview:self.scrollView];
    */
    
    
   
       
    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    // Changed 5/16/13
//    for (UIGestureRecognizer *gR in self.view.gestureRecognizers) {
//        gR.delegate = self;
//    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    [self hideToolbar];
    self.toolbarHidden = YES;
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

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    self.modelController.orientation = toInterfaceOrientation;
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
    
    // redo thumbnails
    [self addThumbnails];
}


- (ModelController *)modelController
{
    // Return the model controller object, creating it if necessary.
    // In more complex implementations, the model controller may be passed to the view controller.
    if (!_modelController) {
        _modelController = [[ModelController alloc] initWithPDF:pdf];
    }
    return _modelController;
}

-(CGRect)frameForThumbnailAtIndex:(NSInteger)index isPortrait:(BOOL)portrait {
    CGFloat width = (portrait? kthumbnailViewWidth : 2*kthumbnailViewWidth);
    CGFloat height = kthumbnailViewHeight;
    CGFloat factor = (portrait ? 2 : 1.5);  //spacing for thumbnails
    CGRect frame = CGRectMake((factor*index+1)*width, kthumbnailOffset, width, height);
    return frame;
}

// add thumbnail images to thumbnail scrollview
-(void)addThumbnails {
    // remove any buttons on scrollView
    [[self.thumbnailScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSArray *thumbnailViews = [self.modelController thumbnailViews];
    UIImageView *imageView = [thumbnailViews objectAtIndex:1];
    CGRect imageBounds = imageView.bounds;
    //CGRect doubleBounds = CGRectMake(0.0, 0.0, imageBounds.size.width*2, imageBounds.size.height);
    CGRect leftFrame = imageBounds;
    CGRect rightFrame = CGRectMake(imageBounds.size.width, 0.0, imageBounds.size.width, imageBounds.size.height);
    CGFloat width =  imageBounds.size.width;
    //CGFLoat doubleWidth = doubleBounds.size.width;
    NSInteger count = [thumbnailViews count];
    
    UIImageView *leftImage;
    UIImageView *rightImage;
    
    BOOL portrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
    
    if (!portrait) {
        count = (count)/2 +1;   // 2 thumbnails per page
    }
    self.thumbnailScrollView.contentSize = CGSizeMake((count * (portrait? 2:3)+1) * width, self.thumbnailScrollView.bounds.size.height);
        
    CGRect frame;
        for (int i=0; i<count; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            
            if (portrait) {
                UIImageView *buttonImage = [thumbnailViews objectAtIndex:i];
                //frame = imageBounds;
                frame = [self frameForThumbnailAtIndex:i isPortrait:YES];     //CGRectMake((2*i+1)*width, 10.0, frame.size.width, frame.size.height);
                button.frame = frame;
                [button setImage:buttonImage.image forState:UIControlStateNormal];
            } else { // landscape
                
                
                // special case for cover page
                if (i==0) {
                    leftImage = nil;
                } else {
                    leftImage = [thumbnailViews objectAtIndex:(2*i-1)];
                }
                leftImage.frame = leftFrame;
                if (i<count-1) {
                    rightImage = [thumbnailViews objectAtIndex:(2*i)];
                } else {
                    rightImage = nil;
                }
                
                rightImage.frame = rightFrame;
                //frame = doubleBounds;
                frame = [self frameForThumbnailAtIndex:i isPortrait:NO];     //CGRectMake((3*i+1)*width, 10.0, frame.size.width, frame.size.height);
                button.frame = frame;
                [button addSubview:leftImage];
                [button addSubview:rightImage];

            }
            
            button.tag = i+1;
            [button addTarget:self action:@selector(thumbnailSelected:) forControlEvents:UIControlEventTouchUpInside];
            
            // add page label
            frame = CGRectMake(0, frame.size.height-20.0, frame.size.width, 20.0);
            UILabel *pageLabel = [[UILabel alloc] initWithFrame:frame];
            pageLabel.backgroundColor = [UIColor clearColor];
            pageLabel.textAlignment = UITextAlignmentCenter;
            pageLabel.textColor = [UIColor blackColor];
            //pageLabel.shadowColor = [UIColor blueColor];
            if (portrait) {
                pageLabel.text = [NSString stringWithFormat:@"Page %d", i+1];
            } else {
                if (i==0 || i==count-1) {
                    pageLabel.text = @"";
                } else {
                    pageLabel.text = [NSString stringWithFormat:@"Pages %d,%d", 2*i,2*i+1];
                }
                
            }
            
            [button addSubview:pageLabel];
            
            [self.thumbnailScrollView addSubview:button];
            
     
        }
}

-(void)turnFromPage:(DataViewController*)currentViewController direction:(UIPageViewControllerNavigationDirection)direction {
    NSArray *viewControllers;
    BOOL portrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
    
    if (portrait) {
        UIViewController *newViewController = (direction == UIPageViewControllerNavigationDirectionForward) ?
                [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController] :
        [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
        viewControllers = [NSArray arrayWithObject:newViewController];
        
    } else {  // landscape - need the previous/next two view controllers
        UIViewController *leftViewController;
        UIViewController *rightViewController;
        if (direction == UIPageViewControllerNavigationDirectionForward) {
            leftViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
            rightViewController =  [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:leftViewController];
        } else {
            rightViewController = [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
            leftViewController =  [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:rightViewController];
        }
       
        viewControllers = [NSArray arrayWithObjects: leftViewController, rightViewController,nil];
        
    }
    [self.pageViewController setViewControllers:viewControllers direction:direction animated:YES completion:NULL];
    
}

-(void)turnToPage:(NSInteger)newPage direction:(UIPageViewControllerNavigationDirection)direction {
    NSArray *viewControllers;
    BOOL portrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
    
    if (portrait) {
        DataViewController *currentViewController = [self.modelController viewControllerAtIndex:newPage];
        viewControllers = [NSArray arrayWithObject:currentViewController];
        
    } else {
        DataViewController *currentViewController = [self.modelController viewControllerAtIndex:newPage];
        UIViewController *nextViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
        viewControllers = [NSArray arrayWithObjects: currentViewController, nextViewController,nil];
        
    }
    [self.pageViewController setViewControllers:viewControllers direction:direction animated:YES completion:NULL];
    NSLog(@"Turned: %@", viewControllers);
    NSLog(@"Turned: %@", [self.pageViewController viewControllers]);
    
}

-(void)thumbnailSelected:(id)sender {
    UIButton *button = (UIButton *)sender;
    BOOL portrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
    
    NSInteger currentPage = [self.modelController indexOfViewController: (DataViewController*)[self.pageViewController.viewControllers objectAtIndex:0]];
    NSInteger newPage = (portrait? button.tag : button.tag*2-2);
    if (newPage == currentPage) {
        return;   // no page change
    }
    
    UIPageViewControllerNavigationDirection direction;
    if (newPage<currentPage) {
        direction = UIPageViewControllerNavigationDirectionReverse;
    } else {
        direction = UIPageViewControllerNavigationDirectionForward;
    }
    
    [self turnToPage:newPage direction:direction];
//    NSArray *viewControllers;
//    if (portrait) {
//        DataViewController *currentViewController = [self.modelController viewControllerAtIndex:newPage];
//       viewControllers = [NSArray arrayWithObject:currentViewController];
//
//    } else {
//        DataViewController *currentViewController = [self.modelController viewControllerAtIndex:newPage];
//        UIViewController *nextViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
//        viewControllers = [NSArray arrayWithObjects: currentViewController, nextViewController,nil];
//
//    }
//        [self.pageViewController setViewControllers:viewControllers direction:direction animated:YES completion:NULL];
}

#pragma mark - UIPageViewController delegate methods


- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    NSLog(@"Previous: %@", previousViewControllers);
    [self.scrollView setZoomScale:1.0 animated:YES];
}


- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        // In portrait orientation: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to YES, so set it to NO here.
        DataViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        if ([currentViewController isBlank]) {  // we're currently showing blank/cover pages
            currentViewController = [self.pageViewController.viewControllers objectAtIndex:1];
        }
        
        NSArray *viewControllers = [NSArray arrayWithObject:currentViewController];
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
        
        self.pageViewController.doubleSided = NO;
        
        
        
        
        return UIPageViewControllerSpineLocationMin;
    }
    
    // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
    DataViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    
    NSArray *viewControllers = nil;
    
    NSUInteger indexOfCurrentViewController = [self.modelController indexOfViewController:currentViewController];
    if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0) {  // even pages on left
        UIViewController *nextViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
        viewControllers = [NSArray arrayWithObjects:currentViewController, nextViewController, nil];
        
    } else {
        UIViewController *previousViewController = [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
        viewControllers = [NSArray arrayWithObjects:previousViewController, currentViewController, nil];
        
    }
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    
    // add bar at bottom to cover blank space
    
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
    if (aScrollView == self.thumbnailScrollView) {
        //NSLog(@"Scrolling Ended");
        [self scheduleTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
    if (aScrollView == self.thumbnailScrollView && !decelerate) {
        //NSLog(@"Scrolling Ended");
        [self scheduleTimer];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    if (aScrollView == self.thumbnailScrollView && [timer isValid]) {
         [timer invalidate];
    }
   
}


-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale{
    //do any other stuff you may need to do.
    [self.view setNeedsLayout];
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
    //NSLog(@"Gesture: %@", [[gestureRecognizer class] description]);
    //NSLog(@"Touched View: %@", touch.view.description);
    if ([touch.view isKindOfClass:[TiledPDFView class]])
        return YES;
    else {
        return NO;
    }
    
    /*
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[UIBarButtonItem class]]) {      //change it to your condition
        return NO;
    }
   if (location.y < self.toolbar.bounds.size.height) {
        return NO;
    }
    return YES;
     */
}

// taps either show/hide toolbar or change pages, depending upon the x-coord of the touch
-(void)handleTap:(id)sender {
    UITapGestureRecognizer *tapGesture = (UITapGestureRecognizer*)sender;
        
    CGPoint touchPoint = [tapGesture locationInView:self.view];
    CGFloat xCoord = touchPoint.x;
    CGFloat width = self.view.bounds.size.width;
    
    
    if (xCoord <= 0.2*width || xCoord>=0.8*width) {

        BOOL previous = (xCoord <= 0.2*width);
        BOOL portrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
        //NSArray *viewControllers = self.pageViewController.viewControllers;
        
        DataViewController *currentViewController;
        if (portrait || previous) {
            currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        } else {
            currentViewController = [self.pageViewController.viewControllers objectAtIndex:1];
        }
        NSInteger page = [self.modelController indexOfViewController:currentViewController];
        
        NSLog(@"Current Page: %d", page);
        
        // No previous page to page 1
        if (previous && page==1) {
            return;
        }
        // No next page to last page
        if (!previous && page == [self.modelController pageCount]) {
            return;
        }
        
        NSInteger pageDelta = (portrait ? 1 : 2);
        NSInteger newPage = (previous ? page - pageDelta : page + 1);
        
         UIPageViewControllerNavigationDirection direction;
        if (previous) {
            direction = UIPageViewControllerNavigationDirectionReverse;
        } else {
            direction = UIPageViewControllerNavigationDirectionForward;
        }
        
        NSLog(@"Turning to page %d", newPage);
        
        //[self turnToPage:newPage direction:direction];
        
        if (!portrait && previous) {
            currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        }
        [self turnFromPage:currentViewController direction:direction];
        
    } else {  // show/hide toolbar
    
    if (self.toolbarHidden) {
        [self showToolbar];
    } else {
        [self hideToolbar];
    }
    }
}

-(void)scheduleTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:ktimerDuration target:self selector:@selector(hideToolbar) userInfo:nil repeats:NO];
}

-(void)hideToolbar {
    [timer invalidate];
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect newtoolbarFrame = CGRectOffset(toolbarFrame, 0.0, -toolbarFrame.size.height);
    CGRect scrollbarFrame = self.thumbnailScrollView.frame;
    CGRect newscrollbarFrame = CGRectOffset(scrollbarFrame, 0.0, scrollbarFrame.size.height);

    // want to scroll thumbnails to show current page's thumbnail
    //NSInteger index =[self.modelController indexOfViewController:[self.pageViewController.viewControllers objectAtIndex:0]];
    
    
      
    [UIView animateWithDuration:kanimateDuration animations:^{
        self.toolbar.frame = newtoolbarFrame;
        self.thumbnailScrollView.frame = newscrollbarFrame;}];
    self.toolbarHidden = YES;
}

-(void)showToolbar {
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect newtoolbarFrame = CGRectOffset(toolbarFrame, 0.0, +toolbarFrame.size.height);
    CGRect scrollbarFrame = self.thumbnailScrollView.frame;
    CGRect newscrollbarFrame = CGRectOffset(scrollbarFrame, 0.0, -scrollbarFrame.size.height);
    [UIView animateWithDuration:kanimateDuration animations:^{
        self.toolbar.frame = newtoolbarFrame;
        self.thumbnailScrollView.frame = newscrollbarFrame;}];
    timer = [NSTimer scheduledTimerWithTimeInterval:ktimerDuration target:self selector:@selector(hideToolbar) userInfo:nil repeats:NO];
    self.toolbarHidden = NO;
}


#pragma mark - Modal Dismiss
-(IBAction)dismissMe:(id)sender {
    [self.delegate dismissModal];
}



@end
