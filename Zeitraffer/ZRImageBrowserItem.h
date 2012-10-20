//
//  ZRImageBrowserItem.h
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/13.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZRImageBrowserItem : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDate *date;

- (id)initWithURL:(NSURL *)url;

- (NSComparisonResult)compareWithFileNameAscending:(ZRImageBrowserItem *)item;
- (NSComparisonResult)compareWithDateCreatedAscending:(ZRImageBrowserItem *)item;
- (NSComparisonResult)compareWithFileNameDescending:(ZRImageBrowserItem *)item;
- (NSComparisonResult)compareWithDateCreatedDescending:(ZRImageBrowserItem *)item;

@end
