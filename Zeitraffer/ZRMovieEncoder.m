//
//  ZRMovieEncoder.m
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/13.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CVPixelBuffer.h>
#import "ZRMovieEncoder.h"
#import "ZRImageBrowserItem.h"
#import "ZRTiltShiftFilter.h"

@implementation ZRMovieEncoder

static ZRMovieEncoder *_encoder = nil;
BOOL _abortFlag = NO;

+ (ZRMovieEncoder *)encoder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _encoder = [[ZRMovieEncoder alloc] init];
    });
    return _encoder;
}

- (id)init {
    self = [super init];
    if (self) {
        self.tiltShift = NO;
    }
    return self;
}

- (void)exportMovieToURL:(NSURL *)url withFileType:(NSString *)fileType size:(CGSize)size fps:(float)fps data:(NSArray *)array {
    // Setup AVAssetWriter
    NSError *error;
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:url fileType:fileType error:&error];
    if (error) {
        NSLog(@"ERROR: %@", error.description);
        return;
    }
    NSMutableDictionary *settings = [[NSMutableDictionary dictionary] init];
    [settings setValue:AVVideoCodecJPEG forKey:AVVideoCodecKey];
    [settings setValue:[NSNumber numberWithInt:size.width] forKey:AVVideoWidthKey];
    [settings setValue:[NSNumber numberWithInt:size.height] forKey:AVVideoHeightKey];
    
    AVAssetWriterInput *imageInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:settings];
	[imageInput setExpectsMediaDataInRealTime:YES];
	if ([writer canAddInput:imageInput]) {
		[writer addInput:imageInput];
    }

    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:imageInput sourcePixelBufferAttributes:attrs];
    CMTime nextPresentationTime = kCMTimeZero;
	[writer startWriting];
    [writer startSessionAtSourceTime:nextPresentationTime];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("com.veronicasoft.zeitraffer", DISPATCH_QUEUE_SERIAL);
    
    int __block i = 0;
    _abortFlag = NO;
    [imageInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        float frameDuration = 1.0 / fps;
        while (true && !_abortFlag) {
            if ([imageInput isReadyForMoreMediaData]) {
                if (i >= array.count) {
                    break;
                }
                ZRImageBrowserItem *item = (ZRImageBrowserItem *)[array objectAtIndex:i];
                CVPixelBufferRef buffer = [self createImageSampleBufferFromURL:item.url size:size];
                if (buffer) {
                    CMTime t = CMTimeMakeWithSeconds(i * frameDuration, 90000);
                    if(![adapter appendPixelBuffer:buffer withPresentationTime:t]) {
                        _abortFlag = YES;
                        break;
                    } else {
                        double progress = 100.0 * i / (int)array.count;
                        //NSLog(@"Success:%d/%d (%f)", i, (int)array.count, progress);
                        // Notify
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressUpdate" object:[NSNumber numberWithDouble:progress]];
                        i++;
                    }
                    CFRelease(buffer);
                }
            }
        }
        [imageInput markAsFinished];
        [writer finishWriting];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressUpdate" object:[NSNumber numberWithDouble:100]];
        if (_abortFlag) {
            //NSLog(@"Canceled.");
        } else {
            //NSLog(@"Done.");
        }
    }];
}

- (void)abortExport {
    _abortFlag = YES;
}

// Create a sample buffer data from CGImageSource
- (CVPixelBufferRef) createImageSampleBufferFromURL:(NSURL *)url size:(CGSize)size {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    size_t bpr = CVPixelBufferGetBytesPerRow(pxbuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, bpr, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    
    CIImage *ciImage = [[CIImage alloc] initWithContentsOfURL:url];
    CIContext *ciContext = [CIContext contextWithCGContext:context options:nil];
    if (self.tiltShift) {
        // Apply Tilt Shift Filter //
        ZRTiltShiftFilter *filter = [[ZRTiltShiftFilter alloc] init];
        filter.inputImage = ciImage;
        CIImage *ciOutImage = filter.outputimage;
        [ciContext drawImage:ciOutImage inRect:CGRectMake(0, 0, size.width, size.height) fromRect:ciImage.extent];
    } else {
        [ciContext drawImage:ciImage inRect:CGRectMake(0, 0, size.width, size.height) fromRect:ciImage.extent];
    }

    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

@end
