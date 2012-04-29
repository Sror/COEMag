//
//  RootViewController.h
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol RootModal <NSObject>

-(void)dismissModal;

@end

@interface RootViewController : UIViewController <UIPageViewControllerDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (assign,nonatomic) CGPDFDocumentRef pdf;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (weak,nonatomic) id<RootModal> delegate;
-(IBAction)dismissMe:(id)sender;

@end
