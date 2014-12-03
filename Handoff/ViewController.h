//
//  ViewController.h
//  Handoff
//
//  Created by Yifei Zhou on 12/3/14.
//  Copyright (c) 2014 Yifei Zhou. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTextField *numberField;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSImageView *qrImageView;

- (IBAction)numberBtnClicked:(NSButton *)sender;
- (IBAction)clearBtnClicked:(NSButton *)sender;
- (IBAction)dialBtnClicked:(NSButton *)sender;

@end

