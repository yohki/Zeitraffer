//
//  ZRImageBrowserDataSource.m
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/13.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import "ZRImageBrowserDataSource.h"
#import "ZRImageBrowserItem.h"

@implementation ZRImageBrowserDataSource

- (id)init
{
    self = [super init];
    if (self) {
        _imageEntries = [NSMutableArray array];
        _path = nil;
    }
    return self;
}

- (void)setCurrentImageDirectory:(NSURL *)path recursive:(BOOL)recursive {
    if (![_path isEqual:path]) {
        _path = path;
        [_imageEntries removeAllObjects];
        [self addImagesWithURL:_path recursive:recursive];
    }
}

- (void)addImagesWithURL:(NSURL *)url recursive:(BOOL)recursive {
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDir];
    
    if (isDir) {        
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
        
        // parse the directory content
        for (int i = 0; i < content.count; i++) {
            if (recursive) {
                [self addImagesWithURL:[content objectAtIndex:i] recursive:YES];
            } else {
                [self addAnImageWithURL:[content objectAtIndex:i]];
            }
        }
    } else {
        [self addAnImageWithURL:url];
    }
}

- (void)addAnImageWithURL:(NSURL *)url {
    if ([[url.pathExtension lowercaseString] isEqualToString:@"jpg"]) {
        ZRImageBrowserItem *item = [[ZRImageBrowserItem alloc] initWithURL:url];
        [_imageEntries addObject:item];
    }
}

- (void)sortByFileName:(BOOL)ascending {
    if (ascending) {
        _imageEntries = [NSMutableArray arrayWithArray:[_imageEntries sortedArrayUsingSelector:@selector(compareWithFileNameAscending:)]];
    } else {
        _imageEntries = [NSMutableArray arrayWithArray:[_imageEntries sortedArrayUsingSelector:@selector(compareWithFileNameDescending:)]];
    }
}

- (void)sortByDateCreated:(BOOL)ascending {
    if (ascending) {
        _imageEntries = [NSMutableArray arrayWithArray:[_imageEntries sortedArrayUsingSelector:@selector(compareWithDateCreatedAscending:)]];
    } else {
        _imageEntries = [NSMutableArray arrayWithArray:[_imageEntries sortedArrayUsingSelector:@selector(compareWithDateCreatedDescending:)]];
    }
}


#pragma mark IKImageBrowserDataSource protocol

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser {
    return _imageEntries.count;
}

- (id)imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index {
    return [_imageEntries objectAtIndex:index];
}

@end
