/*
 * WTController.h
 * of the 'Winetricks' target in the 'WineBottler' project
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
#import <WBottler/WWinetricksController.h>
#import <KBActionWindow/KBActionWindow.h>
#import <KBActionWindow/KBAction.h>



@interface WTController : NSObject <NSWindowDelegate> {
	IBOutlet NSWindow *winetricksWindow;	
	IBOutlet WWinetricksController *winetricksController;
	
	KBAction *copyAction;
	NSUInteger filesToCopy;
	NSUInteger filesCopied;
	NSFileHandle *fileHandle;
	NSMutableArray *runningExes;
}
- (void) copyPrefixFromPath:(NSString *)fromPath toPath:(NSString *)toPath withTitle:(NSString *)tTitle;
- (IBAction) abort:(id)sender;
@end
