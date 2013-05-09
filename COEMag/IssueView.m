//
//  IssueView.m
//  COEMag
//
//  Created by John Hannan on 4/29/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "IssueView.h"

#define kFrameWidth 200
#define kFrameHeight 180

@implementation IssueView
@synthesize coverButton,title, tapButton, progressView, deleteImage;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
-(id)initWithImage:(UIImage*)anImage title:(NSString*)aTitle andTap:(NSString*)aTap {
    CGRect rect = CGRectMake(0.0, 0.0, kFrameWidth, kFrameHeight);
    self = [super initWithFrame:rect];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:anImage forState:UIControlStateNormal];
        button.frame = CGRectMake(0.0, 0.0, 100.0, 130.0);
        button.center = self.center;
        
        CGRect titleFrame = CGRectMake(5.0, 5.0, kFrameWidth-10, 20.0);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor blueColor];
        titleLabel.textAlignment = UITextAlignmentCenter;
        titleLabel.text = aTitle;
        
        CGRect tapFrame = CGRectMake(5.0, kFrameHeight-25.0, kFrameWidth-10, 20.0);
        UILabel *tapLabel = [[UILabel alloc] initWithFrame:tapFrame];
        tapLabel.textColor = [UIColor whiteColor];
        tapLabel.backgroundColor = [UIColor blueColor];
        tapLabel.textAlignment = UITextAlignmentCenter;
        tapLabel.text = aTap;
        UIProgressView *theProgressView = [[UIProgressView alloc] initWithFrame:tapFrame];
        theProgressView.alpha = 0.0;
        
        [self addSubview:button];
        [self addSubview:titleLabel];
        [self addSubview:tapLabel];
        
        self.coverButton = button;
        self.title = titleLabel;
        self.tap = tapLabel;
        self.progressView = theProgressView;
    }
    return self;
}
 
 */

-(void)setIssue:(NSInteger)issue withImage:(UIImage*)anImage title:(NSString*)aTitle andTap:(NSString*)aTap {
    [self.coverButton setImage:anImage forState:UIControlStateNormal];
    self.coverButton.tag = issue;  // tagged so action knows which issue to selected
    self.tapButton.tag = issue;    //  ""
    self.title.text = aTitle;
    [self.tapButton setTitle:aTap forState:UIControlStateNormal];
    
    // add a delete button if not one already
    if (!self.deleteImage) {
        UIImage *image = [UIImage imageNamed:@"XButtonSmall.png"];
        self.deleteImage = [[UIImageView alloc] initWithImage:image];
        self.deleteImage.userInteractionEnabled = YES;
        self.deleteImage.center = CGPointMake(10.0, 10.0);
    }
    
    [self adjustFrame];
}

//adjust its horizontal position according to its tag (0,1,2) and superview's width - to support rotation
-(void)adjustFrame {
    //position issueViews according to width of cell
    CGRect frame;
    CGPoint origin;
    CGFloat width; // = self.superview.bounds.size.width;
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsPortrait(orientation)) {
        width = 768;
    } else {
        width = 1024;
    }
    //CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat issueWidth = self.bounds.size.width;
    frame = self.frame;
    origin = frame.origin;
    
    origin.x = (self.tag+1)*width/4.0 - issueWidth/2.0;
   
    frame.origin = origin;
    self.frame = frame;
    
}

-(void)prepareForReuse {
    [self.coverButton setImage:nil forState:UIControlStateNormal];
    self.title.text = @"";
    [self.tapButton setTitle:@"" forState:UIControlStateNormal];
    [self.coverButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.tapButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    self.tapButton.alpha = 0.0;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
