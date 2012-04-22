//
//  UIImage+PDFPage.h
//  COEMag
//
//  Created by John Hannan on 4/22/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (PDFPage)
+(UIImageView *)imageViewFromPage:(CGPDFPageRef)page withWidth:(CGFloat)width;
@end
