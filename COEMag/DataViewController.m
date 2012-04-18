//
//  DataViewController.m
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "DataViewController.h"
#import "TiledPDFView.h"

@interface DataViewController ()
@property CGFloat pdfScale;
@property (nonatomic,strong) UIImageView *backgroundImageView;
@property BOOL nonempty;
@property (nonatomic,strong) TiledPDFView *pdfView, *oldPDFView;

@end

@implementation DataViewController
@synthesize page;
@synthesize scrollView;
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

-(id)initWithPage:(CGPDFPageRef)p {
    self = [super init];
    if (self) {
        self.page = p;
        self.nonempty = YES;
        
        // Set up the UIScrollView
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.bouncesZoom = YES;
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        self.scrollView.delegate = self;
		[self.scrollView setBackgroundColor:[UIColor grayColor]];
		self.scrollView.maximumZoomScale = 5.0;
		self.scrollView.minimumZoomScale = .25;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // determine the size of the PDF page
    }

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)loadPage {
    if (self.nonempty) {
        
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
//    NSLog(@"frame width:%f, pageWidth:%f", self.view.frame.size.width, pageRect.size.width);
//    CGFloat xyz = self.view.frame.size.width/pageRect.size.width;
//    NSLog(@"xyz = %f", xyz);
    pdfScale = self.scrollView.frame.size.width/pageRect.size.width;
    NSLog(@"scale = %f", pdfScale);
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
    
    [backgroundImageView removeFromSuperview];
        [pdfView removeFromSuperview];
    backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.frame = pageRect;
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView  addSubview:backgroundImageView];
    [self.scrollView  sendSubviewToBack:backgroundImageView];
        
        // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
		pdfView = [[TiledPDFView alloc] initWithFrame:pageRect andScale:pdfScale];
		[pdfView setPage:page];
		
		[self.scrollView addSubview:pdfView];

    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadPage];
}

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


#pragma mark -
#pragma mark UIScrollView delegate methods

// A UIScrollView delegate callback, called when the user starts zooming. 
// We return our current TiledPDFView.
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return pdfView;
}

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
	[self.scrollView addSubview:pdfView];
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
	[self.scrollView addSubview:oldPDFView];
}



@end
