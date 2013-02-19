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

const NSInteger kFormatQuickTime = 0;
const NSInteger kFormatMPEG4 = 1;

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
    self.progressBar.usesThreadedAnimation = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressBar:) name:@"ProgressUpdate" object:nil];
    
    _outputSize = CGSizeMake(360, 240);    
    _sortOrder = kSortOrderFileNameAscending;

    [NSBundle loadNibNamed:@"ZRExportSettingsView" owner:self];
    _savePanel = [NSSavePanel savePanel];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
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

- (IBAction)formatSelected:(id)sender {
    NSPopUpButton *popup = (NSPopUpButton *)sender;
    NSInteger index = [popup indexOfSelectedItem];
    if (index == kFormatQuickTime) {
        [_savePanel setAllowedFileTypes:[NSArray arrayWithObject:AVFileTypeQuickTimeMovie]];
    } else if (index == kFormatMPEG4) {
        [_savePanel setAllowedFileTypes:[NSArray arrayWithObject:AVFileTypeMPEG4]];
    }
}

- (IBAction)exportButtonClicked:(id)sender {
    if (_exportInProgress) {
        self.exportButton.title = NSLocalizedString(@"ExportButtonLabel", @"Label for export button");
        [[ZRMovieEncoder encoder] abortExport];
    } else {
        [_savePanel setTitle:NSLocalizedString(@"SavePanelTitle", @"Title for save panel")];
        [_savePanel setNameFieldStringValue:NSLocalizedString(@"DefaultFileName", @"Default file name to export")];
        [_savePanel setCanSelectHiddenExtension:YES];
        [_savePanel setCanCreateDirectories:NO];
        [_savePanel setAllowedFileTypes:[NSArray arrayWithObject:_outFileType]];
        
        // setup accessory view
        [self.optionFPS setFloatValue:kDefaultFPS];
        [self.optionWidth setFloatValue:_outputSize.width];
        [self.optionHeight setFloatValue:_outputSize.height];
        
        [_savePanel setAccessoryView:self.accessoryView];
             
        NSInteger result = [_savePanel runModal];
        if (result != NSFileHandlingPanelOKButton) {
            return;
        }

        // validate values
        float fps = [self.optionFPS floatValue];
        if (fps <= 0) {
            [self.optionFPS setIntValue:kDefaultFPS];
            fps = kDefaultFPS;
        }
        float width = [self.optionWidth floatValue];
        if (0 < width) {
            _outputSize.width = width;
        }
        float height = [self.optionHeight floatValue];
        if (0 < height) {
            _outputSize.height = height;
        }
        NSInteger index = self.optionFormat.indexOfSelectedItem;
        if (index == kFormatQuickTime) {
            _outFileType = AVFileTypeQuickTimeMovie;
        } else if (index == kFormatMPEG4) {
            _outFileType = AVFileTypeMPEG4;
        }
        
        // delete if overwrite
        if ([[NSFileManager defaultManager] fileExistsAtPath:_savePanel.URL.path]) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:_savePanel.URL error:&error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert runModal];
                return;
            }
        }
        
        // Start progress
        [self.status setStringValue:NSLocalizedString(@"MessageProgressNoDetail", @"Message in progress")];
        [self.progressBar setIndeterminate:YES];
        [self.progressBar startAnimation:nil];

        [[ZRMovieEncoder encoder] exportMovieToURL:_savePanel.URL withFileType:_outFileType size:_outputSize fps:fps data:_imageSource.imageEntries];
        self.exportButton.title = NSLocalizedString(@"CancelButtonLabel", @"Label for cancel button");
        [self.picker setEnabled:NO];
        [self.orderPopup setEnabled:NO];
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
    NSNumber *value = (NSNumber *)notification.object;
    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        if ([self.progressBar isIndeterminate]) {
            [self.progressBar setIndeterminate:NO];
        }
        // This is a workaround for update progress indicator correctly
        [self.progressBar setDoubleValue:100];
        
        [self.progressBar setDoubleValue:[value doubleValue]];
        [self.progressBar displayIfNeeded];
        [self.status setStringValue:[NSString stringWithFormat:NSLocalizedString(@"MessageProgress", @"Message in progress"), [value doubleValue]]];
        //NSLog(@"%5.2f", self.progressBar.doubleValue);
        
        if ([value isEqualToNumber:[NSNumber numberWithDouble:100]]) {
            [self.progressBar setDoubleValue:0];
            [self.progressBar displayIfNeeded];
            [self.status setStringValue:NSLocalizedString(@"MessageDone", @"Message when done")];
            self.exportButton.title = NSLocalizedString(@"ExportButtonLabel", nil);
            [self.picker setEnabled:YES];
            [self.orderPopup setEnabled:YES];
            _exportInProgress = NO;
        }
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
        if (_imageSource.imageEntries.count == 0) {
            [self.browserView setSelectionIndexes:nil byExtendingSelection:NO];
            [self.exportButton setEnabled:NO];
        } else {
            [self.browserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
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
	[openPanel setTitle:NSLocalizedString(@"OpenPanelTitle", @"Title for open panel")];
	[openPanel setPrompt:NSLocalizedString(@"ChooseButtonLabel", @"Label for choose button")];
}

#pragma mark IKImageBrowserDelegate protocol

- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)browser {
    NSIndexSet *selection = browser.selectionIndexes;
    if (selection.count == 0) {
        [self.imageView setImageWithURL:nil];
    } else if (selection.count == 1) {
        IKImageBrowserCell *cell = [self.browserView cellForItemAtIndex:selection.firstIndex];
        ZRImageBrowserItem *item = (ZRImageBrowserItem *)cell.representedItem;
        [self.imageView setImageWithURL:item.url];
    }
}

@end
