//
//  ZRImageBrowserDataSource.h
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/13.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface ZRImageBrowserDataSource : NSObject {
    NSURL *_path;
}

- (void)setCurrentImageDirectory:(NSURL *)path recursive:(BOOL)recursive;
- (void)sortByFileName:(BOOL)ascending;
- (void)sortByDateCreated:(BOOL)ascending;

@property (readonly, strong) NSMutableArray *imageEntries;

@end
