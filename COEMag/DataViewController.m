//
//  DataViewController.m
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "DataViewController.h"
#import "TiledPDFView.h"
#import "UIImageView+PDFPage.h"

@interface DataViewController ()
@property CGFloat pdfScale;
@property (nonatomic,strong) UIImageView *backgroundImageView;
@property BOOL nonempty;

@property (nonatomic,strong) TiledPDFView *pdfView, *oldPDFView;

@end

@implementation DataViewController

@synthesize page;
//@synthesize scrollView;
@synthesize pdfScale;
@synthesize backgroundImageView;
@synthesize nonempty;
@synthesize pdfView, oldPDFView;


-(id)init {
    self = [super init];
    if (self) {
        self.nonempty = NO;
        
        
    }
    return self;
}

-(id)initWithPage:(CGPDFPageRef)p atPageNumber:(NSInteger)num{
    self = [super init];
    if (self) {
        self.page = p;
        self.pageNumber = num;
        self.nonempty = YES;
        self.view.backgroundColor = [UIColor blackColor];
        
            }
    return self;
}

-(BOOL)isBlank {
    return !nonempty;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //hide the toolbar
    self.view.backgroundColor = [UIColor blackColor];
    
}



- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}



// the background imageView provides a quick loading view of the page.  The tiled pdf view provides a better view that
// can be scaled, but takes a little time to load

-(void)loadPage {
    if (self.nonempty) {
        
        //UIDeviceOrientation deviceOrientation =  [[UIDevice currentDevice] orientation];
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        //NSLog(@"Orientation 3 %d,%d", deviceOrientation,interfaceOrientation);
        //CGRect bounds = self.view.bounds;
        //NSLog(@"Bounds: %f,%f,%f,%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
        
        CGFloat width;
        width = (interfaceOrientation != UIDeviceOrientationPortrait) ? 512.0 : self.view.bounds.size.width;

        
        /*
        CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        // NSLog(@"frame width:%f, pageWidth:%f", self.view.frame.size.width, pageRect.size.width);
        //    NSLog(@"Parent frame width:%f", self.view.superview.frame.size.width);
        //    CGFloat xyz = self.view.frame.size.width/pageRect.size.width;
        //    NSLog(@"xyz = %f", xyz);
        pdfScale = self.view.frame.size.width/pageRect.size.width;
        //NSLog(@"scale = %f", pdfScale);
        pageRect.size = CGSizeMake(pageRect.size.width*pdfScale, pageRect.size.height*pdfScale);
        
        
        // Create a low res image representation of the PDF page to display before the TiledPDFView
        // renders its content.
        UIGraphicsBeginImageContext(pageRect.size);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // First fill the background with white.
        CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
        CGContextFillRect(context,pageRect);
        
        CGContextSaveGState(context);
        // Flip the context so that the PDF page is rendered
        // right side up.
        CGContextTranslateCTM(context, 0.0, pageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        // Scale the context so that the PDF page is rendered 
        // at the correct size for the zoom level.
        CGContextScaleCTM(context, pdfScale,pdfScale);	
        CGContextDrawPDFPage(context, page);
        CGContextRestoreGState(context);
        
        UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        */
        
        [backgroundImageView removeFromSuperview];
        [pdfView removeFromSuperview];
        
       
        
        backgroundImageView = [UIImageView imageViewFromPage:page withWidth:width];
        
        
//        backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
//        backgroundImageView.frame = pageRect;
//        backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.view  addSubview:backgroundImageView];
        [self.view  sendSubviewToBack:backgroundImageView];
        
        // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
		//pdfView = [[TiledPDFView alloc] initWithFrame:pageRect andScale:pdfScale];
       
        pdfView = [[TiledPDFView alloc] initWithPage:page withWidth:width];
        
		[pdfView setPage:page];
		
		[self.view addSubview:pdfView];
        
    } 
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    NSLog(@"Orientation 1 %d", orientation);
//    CGRect bounds = self.view.bounds;
//    NSLog(@"Bounds: %f,%f,%f,%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    
    /*
    if (self.nonempty && [[self.view subviews] count] == 0) { // if >1, then label already appears
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 65.0)];
        label.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height - 40.0);
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.numberOfLines = 2;
        label.textAlignment = UITextAlignmentCenter;
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        //label.text = @"College of Engineering\nThe Pennsylvania State University";
        [self.view addSubview:label];
    }
     */   

    [self loadPage];
}
 

//-(void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    NSLog(@"Orientation 2 %d", orientation);
//    CGRect bounds = self.view.bounds;
//    NSLog(@"Bounds: %f,%f,%f,%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
//    
//    [self loadPage];
//}

-(void)viewWillDisappear:(BOOL)animated {
    [backgroundImageView removeFromSuperview];
    backgroundImageView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    [self loadPage];
//}



@end
