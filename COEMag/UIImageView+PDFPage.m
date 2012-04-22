//
//  UIImage+PDFPage.m
//  COEMag
//
//  Created by John Hannan on 4/22/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "UIImageView+PDFPage.h"

@implementation UIImageView (PDFPage)

+(UIImageView *)imageViewFromPage:(CGPDFPageRef)page withWidth:(CGFloat)width {
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    
    CGFloat pdfScale = width/pageRect.size.width;
    
    pageRect.size = CGSizeMake(pageRect.size.width*pdfScale, pageRect.size.height*pdfScale);
    
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
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.frame = pageRect;
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    return backgroundImageView;
}
@end
