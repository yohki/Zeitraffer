//
//  ZRMovieEncoder.h
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/13.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZRMovieEncoder : NSObject

+ (ZRMovieEncoder *)encoder;

- (void)exportMovieToURL:(NSURL *)url withFileType:(NSString *)fileType size:(CGSize)size fps:(float)fps data:(NSArray *)array;

- (void)abortExport;

@property BOOL tiltShift;

@end
