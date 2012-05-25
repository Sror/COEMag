//
//  IssueTableCell.m
//  COEMag
//
//  Created by John Hannan on 4/24/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "IssueTableCell.h"

@implementation IssueTableCell
//@synthesize title, tap, progressView, coverImageView;
@synthesize issueView1, issueView2, issueView3;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth; // | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin; 
        self.autoresizesSubviews=YES;
    }
    return self;
}


-(void)prepareForReuse {
    [self.issueView1 prepareForReuse];
    [self.issueView2 prepareForReuse];
    [self.issueView3 prepareForReuse];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
