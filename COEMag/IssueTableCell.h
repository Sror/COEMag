//
//  IssueTableCell.h
//  COEMag
//
//  Created by John Hannan on 4/24/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IssueView.h"

@interface IssueTableCell : UITableViewCell

@property (nonatomic, strong) IBOutlet IssueView *issueView1;
@property (nonatomic, strong) IBOutlet IssueView *issueView2;
@property (nonatomic, strong) IBOutlet IssueView *issueView3;

/*
@property (nonatomic, strong) IBOutlet UILabel *title;
@property (nonatomic, strong) IBOutlet UILabel *tap;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UIImageView *coverImageView;
 */
@end
