/*
 * WPrefixController.h
 * of the 'WineStatus' target in the 'WineBottler' project
 *
 * Copyright 2010 - 2017 Mike Kronenberg
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */



#import <Cocoa/Cocoa.h>
#import "WSController.h"
#import "WBController.h"



@interface WPrefixController : NSObject <NSMetadataQueryDelegate, NSTableViewDataSource, NSTableViewDelegate> {
	IBOutlet id controller;
	id bottlerController;
	
	IBOutlet NSWindow *prefixesWindow;
	IBOutlet NSProgressIndicator *queryProgressIndicator;
	IBOutlet NSTextField *queryProgressText;
	IBOutlet NSTableView *table;
	IBOutlet NSButton *buttonNew;
	IBOutlet NSButton *buttonReload;
	IBOutlet NSTextField *searchField;
	
	NSMetadataQuery *query;
	NSArray *foundPrefixes;
}
- (void) setRow;
- (IBAction) queryForPrefixes:(id)sender;
- (IBAction) changePrefix:(id)sender;
- (IBAction) search:(id)sender;
- (IBAction) createNewPrefix:(id)sender;
- (IBAction) deleteAtRow:(id)sender;
- (void) deletePrefixAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction) showInFinderAtRow:(id)sender;
@end
