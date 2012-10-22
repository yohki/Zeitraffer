//
//  ZRAppDelegate.m
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/12.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ZRAppDelegate.h"
#import "ZRImageBrowserItem.h"
#import "ZRMovieEncoder.h"

@implementation ZRAppDelegate

const float kDefaultFPS = 30;

const NSInteger kSortOrderFileNameAscending = 0;
const NSInteger kSortOrderFileNameDescending = 1;
const NSInteger kSortOrderDateCreatedAscending = 2;
const NSInteger kSortOrderDateCreatedDescending = 3;

CGSize _outputSize;
BOOL _exportInProgress = NO;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    _imageSource = [[ZRImageBrowserDataSource alloc] init];
    _outFileType = AVFileTypeQuickTimeMovie;
    
    self.browserView.dataSource =_imageSource;
    self.browserView.allowsMultipleSelection = NO;
    [self.browserView setIntercellSpacing:NSMakeSize(0, 0)];
    [self.browserView setValue:[NSColor grayColor] forKey:IKImageBrowserBackgroundColorKey];
    [self.browserView setCellsStyleMask:IKCellsStyleTitled|IKCellsStyleSubtitled|IKCellsStyleOutlined];
	NSMutableParagraphStyle *paraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	[paraphStyle setAlignment:NSCenterTextAlignment];

	NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont fontWithName:@"Helvetica" size:12] forKey:NSFontAttributeName];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[self.browserView setValue:attributes forKey:IKImageBrowserCellsTitleAttributesKey];
    
    attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont fontWithName:@"Helvetica" size:9] forKey:NSFontAttributeName];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    [self.browserView setValue:attributes forKey:IKImageBrowserCellsSubtitleAttributesKey];

    attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont fontWithName:@"Helvetica Bold" size:12] forKey:NSFontAttributeName];
	[attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    [self.browserView setValue:attributes forKey:IKImageBrowserCellsHighlightedTitleAttributesKey];
    
    self.imageView.autoresizes = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressBar:) name:@"ProgressUpdate" object:nil];
    
    _outputSize = CGSizeMake(360, 240);
    
    _sortOrder = kSortOrderFileNameAscending;
    [self.fps setIntValue:kDefaultFPS];
}

- (NSURL *)selectDirectory {
    NSURL *url = nil;
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setExtensionHidden:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    NSInteger result = [panel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        url = (NSURL *)[panel.URLs objectAtIndex:0];
    }
    return url;
}

#pragma mark NSButton delegate

- (IBAction)exportButtonClicked:(id)sender {
    if (_exportInProgress) {
        self.exportButton.title = @"Export...";
        [[ZRMovieEncoder encoder] abortExport];
    } else {
        // Validate FPS value
        float fps = [self.fps floatValue];
        if (fps <= 0) {
            [self.fps setIntValue:kDefaultFPS];
            fps = kDefaultFPS;
        }

        NSSavePanel *panel = [NSSavePanel savePanel];
        [panel setTitle:@"Choose the location to save..."];
        [panel setNameFieldStringValue:@"Untitled"];
        [panel setCanSelectHiddenExtension:YES];
        [panel setCanCreateDirectories:NO];
        [panel setAllowedFileTypes:[NSArray arrayWithObject:_outFileType]];
        
        NSInteger result = [panel runModal];
        if (result != NSFileHandlingPanelOKButton) {
            return;
        }

        if ([[NSFileManager defaultManager] fileExistsAtPath:panel.URL.path]) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:panel.URL error:&error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
                return;
            }
        }
        [[ZRMovieEncoder encoder] exportMovieToURL:panel.URL withFileType:_outFileType size:_outputSize fps:fps data:_imageSource.imageEntries];
        self.exportButton.title = @"Cancel";
        _exportInProgress = YES;
    }
}

- (IBAction)orderPopupSelected:(id)sender {
    NSPopUpButton *popup = (NSPopUpButton *)sender;
    NSInteger index = [popup indexOfSelectedItem];
    if (index != _sortOrder) {
        _sortOrder = index;
        [self sortItems];        
    }
}

- (void)sortItems {
    if (_sortOrder == kSortOrderFileNameAscending) {
        [_imageSource sortByFileName:YES];
    } else if (_sortOrder == kSortOrderFileNameDescending) {
        [_imageSource sortByFileName:NO];
    } else if (_sortOrder == kSortOrderDateCreatedAscending) {
        [_imageSource sortByDateCreated:YES];
    } else if (_sortOrder == kSortOrderDateCreatedDescending) {
        [_imageSource sortByDateCreated:NO];
    }
    [self.browserView reloadData];
}

- (void)updateProgressBar:(NSNotification *)notification {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^(void) {
        NSNumber *value = (NSNumber *)[notification object];
        if ([value isEqualToNumber:[NSNumber numberWithDouble:100]]) {
            [self.progressBar setDoubleValue:0];
            [self.status setStringValue:@"Done."];
            self.exportButton.title = @"Export...";
            _exportInProgress = NO;
        } else {
            [self.progressBar setDoubleValue:[value doubleValue]];
            [self.status setStringValue:[NSString stringWithFormat:@"Now processing... (%2.0f%%)", [value doubleValue]]];
            
        }
        [self.progressBar displayIfNeeded];
        //NSLog(@"%f", [value doubleValue]);
    });
}

#pragma mark NSPathControl delegate

- (IBAction)changeLocationAction:(id)sender {
    NSPathControl *pathCntl = (NSPathControl *)sender;
    
    // find the path component selected
    NSPathComponentCell *component = [pathCntl clickedPathComponentCell];
    
    NSURL *url = [component URL];
    if (url) {
        [_imageSource setCurrentImageDirectory:url recursive:NO];
        [self sortItems];
        [self.browserView reloadData];
        [self.browserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        if (_imageSource.imageEntries.count == 0) {
            [self.exportButton setEnabled:NO];
        } else {
            [self.exportButton setEnabled:YES];
        }
        _outputSize.width = self.imageView.imageSize.width;
        _outputSize.height = self.imageView.imageSize.height;
    }
}

- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel {
	// change the wind title and choose buttons title
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setTitle:@"Choose a directory of images"];
	[openPanel setPrompt:@"Choose"];
}

#pragma mark IKImageBrowserDelegate protocol

- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)browser {
    NSIndexSet *selection = browser.selectionIndexes;
    if (selection.count == 1) {
        IKImageBrowserCell *cell = [self.browserView cellForItemAtIndex:selection.firstIndex];
        ZRImageBrowserItem *item = (ZRImageBrowserItem *)cell.representedItem;
        [self.imageView setImageWithURL:item.url];
    }
}

@end
