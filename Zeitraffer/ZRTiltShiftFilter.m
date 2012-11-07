//
//  ZRTiltShiftFilter.m
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/24.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "ZRTiltShiftFilter.h"

@implementation ZRTiltShiftFilter
- (id)init {
    self = [super init];
    if (self) {
        self.radius = 10;
    }
    return self;
}

- (CIImage *) outputimage {
    // Blur
    CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blur setDefaults];
    [blur setValue:[NSNumber numberWithFloat:self.radius] forKey:kCIInputRadiusKey];
    [blur setValue:self.inputImage forKey:kCIInputImageKey];
    CIImage *blurOut = [blur valueForKey:kCIOutputImageKey];
    
    // 2 Linear gradients
    CGFloat h = self.inputImage.extent.size.height;
    CIFilter *grad1 = [CIFilter filterWithName:@"CILinearGradient"];
    [grad1 setDefaults];
    CIVector *ip0 = [CIVector vectorWithX:0 Y:0.75 * h];
    CIVector *ip1 = [CIVector vectorWithX:0 Y:0.5 * h];
    CIColor *c0 = [CIColor colorWithRed:0 green:1 blue:0 alpha:1];
    CIColor *c1 = [CIColor colorWithRed:0 green:1 blue:0 alpha:0];
    [grad1 setValue:ip0 forKey:@"inputPoint0"];
    [grad1 setValue:ip1 forKey:@"inputPoint1"];
    [grad1 setValue:c0 forKey:@"inputColor0"];
    [grad1 setValue:c1 forKey:@"inputColor1"];
    CIImage *gradOut1 = [grad1 valueForKey:kCIOutputImageKey];

    CIFilter *grad2 = [CIFilter filterWithName:@"CILinearGradient"];
    [grad2 setDefaults];
    ip0 = [CIVector vectorWithX:0 Y:0.25 * h];
    ip1 = [CIVector vectorWithX:0 Y:0.5 * h];
    c0 = [CIColor colorWithRed:0 green:1 blue:0 alpha:1];
    c1 = [CIColor colorWithRed:0 green:1 blue:0 alpha:0];
    [grad2 setValue:ip0 forKey:@"inputPoint0"];
    [grad2 setValue:ip1 forKey:@"inputPoint1"];
    [grad2 setValue:c0 forKey:@"inputColor0"];
    [grad2 setValue:c1 forKey:@"inputColor1"];
    CIImage *gradOut2 = [grad2 valueForKey:kCIOutputImageKey];
    
    // Create a Mask from the Linear Gradients
    CIFilter *mask = [CIFilter filterWithName:@"CIAdditionCompositing"];
    [mask setDefaults];
    [mask setValue:gradOut1 forKey:kCIInputImageKey];
    [mask setValue:gradOut2 forKey:kCIInputBackgroundImageKey];
    CIImage *maskOut = [mask valueForKey:kCIOutputImageKey];
    
    // Combine the Blurred Image, Source Image, and the Gradients
    CIFilter *blend = [CIFilter filterWithName:@"CIBlendWithMask"];
    [blend setDefaults];
    [blend setValue:blurOut forKey:kCIInputImageKey];
    [blend setValue:self.inputImage forKey:kCIInputBackgroundImageKey];
    [blend setValue:maskOut forKey:kCIInputMaskImageKey];
    CIImage *blendOut = [blend valueForKey:kCIOutputImageKey];
    
    return blendOut;
}

@end
