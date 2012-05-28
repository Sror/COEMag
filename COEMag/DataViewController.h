//
//  DataViewController.h
//  COEMag
//
//  Created by John Hannan on 4/13/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController 


@property CGPDFPageRef page;
//@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
-(id)initWithPage:(CGPDFPageRef)p;
-(void)loadPage;
-(BOOL)isBlank;
@end
