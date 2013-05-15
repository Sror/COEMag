//
//  IssueCollectionCell.h
//  COEMag
//
//  Created by John Hannan on 5/15/13.
//  Copyright (c) 2013 Penn State University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IssueCollectionCell : UICollectionViewCell
@property (strong,nonatomic) IBOutlet UILabel *title;
@property (strong,nonatomic) IBOutlet UILabel *action;
@property (strong,nonatomic) IBOutlet UIProgressView *progressView;
@property (strong,nonatomic) IBOutlet UIImageView *coverView;
@end
