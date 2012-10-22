//
//  ZRImageBrowserItem.m
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/13.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "ZRImageBrowserItem.h"

@implementation ZRImageBrowserItem

NSDateFormatter *_formatter;

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        self.url = url;
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:self.url.path error:nil];
        self.date = [attrs objectForKey:NSFileCreationDate];
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return self;
}

- (NSComparisonResult)compareWithFileNameAscending:(ZRImageBrowserItem *)item {
    return [self.url.lastPathComponent compare:item.url.lastPathComponent];
}

- (NSComparisonResult)compareWithDateCreatedAscending:(ZRImageBrowserItem *)item {
    return [self.date compare:item.date];
}

- (NSComparisonResult)compareWithFileNameDescending:(ZRImageBrowserItem *)item {
    return [item.url.lastPathComponent compare:self.url.lastPathComponent];
}

- (NSComparisonResult)compareWithDateCreatedDescending:(ZRImageBrowserItem *)item {
    return [item.date compare:self.date];
}

#pragma mark IKImageBrowserItem protocol

/* let the image browser knows we use a path representation */
- (NSString *)imageRepresentationType {
	return IKImageBrowserNSURLRepresentationType;
}

/* give our representation to the image browser */
- (id)imageRepresentation {
	return self.url;
}

/* use the absolute filepath as identifier */
- (NSString *)imageUID {
    return [self.url absoluteString];
}

- (NSString *)imageTitle {
    return [self.url lastPathComponent];
}

- (NSString *)imageSubtitle {
    return [_formatter stringFromDate:self.date];
}
@end
