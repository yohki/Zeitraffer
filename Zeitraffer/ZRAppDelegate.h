//
//  ZRAppDelegate.h
//  Zeitraffer
//
//  Created by OHKI Yoshihito on 2012/10/12.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#import "ZRImageBrowserDataSource.h"

@interface ZRAppDelegate : NSObject <NSApplicationDelegate> {
    ZRImageBrowserDataSource *_imageSource;
    NSString *_outFileType;
    NSInteger _sortOrder;
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, weak) IBOutlet NSPathControl *picker;
@property (nonatomic, weak) IBOutlet IKImageBrowserView *browserView;
@property (nonatomic, weak) IBOutlet IKImageView *imageView;
@property (nonatomic, weak) IBOutlet NSButton *exportButton;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;
@property (nonatomic, weak) IBOutlet NSTextField *status;
@property (nonatomic, weak) IBOutlet NSTextField *fps;

- (IBAction)exportButtonClicked:(id)sender;
- (IBAction)orderPopupSelected:(id)sender;

@end
