//
//  ZRTiltShiftFilter.h
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/24.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface ZRTiltShiftFilter : CIFilter

@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat radius;
@property (strong, nonatomic) CIImage *inputImage;
@property (readonly, strong, nonatomic) CIImage *outputimage;

@end
