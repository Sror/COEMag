//
//  IssueView.h
//  COEMag
//
//  Created by John Hannan on 4/29/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IssueView : UIView

@property (strong,nonatomic) IBOutlet UIButton *coverButton;
@property (strong,nonatomic) IBOutlet UILabel *title;
@property (strong,nonatomic) IBOutlet UILabel *tap;
@property (strong,nonatomic) IBOutlet UIProgressView *progressView;
@property (strong,nonatomic) IBOutlet UIImageView *deleteImage;

//-(id)initWithImage:(UIImage*)anImage title:(NSString*)aTitle andTap:(NSString*)aTap;
-(void)setIssue:(NSInteger)issue withImage:(UIImage*)anImage title:(NSString*)aTitle andTap:(NSString*)aTap;
@end
