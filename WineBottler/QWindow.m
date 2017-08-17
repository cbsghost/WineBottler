/*
 * Q Window
 * 
 * Copyright (c) 2007 - 2017 Mike Kronenberg
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "QWindow.h"

// define bgimage size and regions
#define IMG_WIDTH 6
#define IMG_HEIGHT 60
#define BG_TOP 23
#define BG_BOTTOM 30
#define BG_LEFT 0
#define BG_RIGHT 0

// compute rects
#define HEADER_ACTIVE_YELLOW NSMakeRect(0, IMG_HEIGHT - BG_TOP - 1, IMG_WIDTH, BG_TOP)
#define HEADER_INACTIVE_YELLOW NSMakeRect(IMG_WIDTH + 2, IMG_HEIGHT - BG_TOP - 1, IMG_WIDTH, BG_TOP)
#define HEADER_ACTIVE NSMakeRect(2 * (IMG_WIDTH + 2) + 1, IMG_HEIGHT - BG_TOP - 1, IMG_WIDTH, BG_TOP)
#define HEADER_INACTIVE NSMakeRect(3 * (IMG_WIDTH + 2) + 1, IMG_HEIGHT - BG_TOP - 1, IMG_WIDTH, BG_TOP)

#define MIDDLE_ACTIVE_YELLOW NSMakeRect(0, BG_BOTTOM, IMG_WIDTH, IMG_HEIGHT - BG_TOP - BG_BOTTOM)
#define MIDDLE_INACTIVE_YELLOW NSMakeRect(IMG_WIDTH + 2, BG_BOTTOM, IMG_WIDTH, IMG_HEIGHT - BG_TOP - BG_BOTTOM)
#define MIDDLE_ACTIVE NSMakeRect(2 * (IMG_WIDTH + 2) + 1, BG_BOTTOM, IMG_WIDTH, IMG_HEIGHT - BG_TOP - BG_BOTTOM)
#define MIDDLE_INACTIVE NSMakeRect(3 * (IMG_WIDTH + 2) + 1, BG_BOTTOM, IMG_WIDTH, IMG_HEIGHT - BG_TOP - BG_BOTTOM)

#define FOOTER_ACTIVE_YELLOW NSMakeRect(0, 0, IMG_WIDTH, BG_BOTTOM)
#define FOOTER_INACTIVE_YELLOW NSMakeRect(IMG_WIDTH + 2, 0, IMG_WIDTH, BG_BOTTOM)
#define FOOTER_ACTIVE NSMakeRect(2 * (IMG_WIDTH + 2) + 1, 0, IMG_WIDTH, BG_BOTTOM)
#define FOOTER_INACTIVE NSMakeRect(3 * (IMG_WIDTH + 2) + 1, 0, IMG_WIDTH, BG_BOTTOM)



@implementation QWindow


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{    
    // Conditionally add textured window flag to stylemask
    NSWindowStyleMask newStyle;
    if (styleMask & NSTexturedBackgroundWindowMask) {
        newStyle = styleMask;
    } else {
        newStyle = (NSTexturedBackgroundWindowMask | styleMask);
    }
    
    if (self = [super initWithContentRect:contentRect styleMask:newStyle backing:bufferingType defer:flag]) {
        
        forceDisplay = NO;
        //yellow = [[NSUserDefaults standardUserDefaults] boolForKey:@"yellow"];
        yellow = true;
        
        [self setMovableByWindowBackground:YES];
        [self setBackgroundColor:[self sizedPolishedBackground]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowNeedsUpdate:) name:NSWindowDidResizeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowNeedsUpdate:) name:NSWindowDidResignKeyNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowNeedsUpdate:) name:NSWindowDidBecomeKeyNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowNeedsUpdate:) name:NSApplicationDidResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowNeedsUpdate:) name:NSApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setYellow:) name:@"yellow" object:nil];
        
        // chache images
        template = [NSImage imageNamed:@"q_bg.png"];
        
        return self;
    }
    
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"yellow" object:nil];
    
    [super dealloc];
}

- (void) setYellow:(id)sender
{
	yellow = [[NSUserDefaults standardUserDefaults] boolForKey:@"yellow"];
    [self setBackgroundColor:[self sizedPolishedBackground]];
	[self display];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
- (void)setToolbar:(NSToolbar *)toolbar
{
    // Only actually call this if we respond to it on this machine
    if ([toolbar respondsToSelector:@selector(setShowsBaselineSeparator:)]) {
        [toolbar setShowsBaselineSeparator:NO];
    }
    
    [super setToolbar:toolbar];
}
#endif

-(void)awakeFromNib
{
    [self setBackgroundColor:[self sizedPolishedBackground]];
    [self display];
}

- (void)windowNeedsUpdate:(NSNotification *)aNotification
{
    [self setBackgroundColor:[self sizedPolishedBackground]];
    if (forceDisplay) {
        [self display];
    }
}

- (void)setMinSize:(NSSize)aSize
{
    [super setMinSize:NSMakeSize(MAX(aSize.width, 128.0), MAX(aSize.height, 128.0))];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animationFlag
{
    forceDisplay = YES;
    [super setFrame:frameRect display:displayFlag animate:animationFlag];
    forceDisplay = NO;
}

- (NSColor *)sizedPolishedBackground
{
    NSImage *bg = [[NSImage alloc] initWithSize:[self frame].size];
  
    // Begin drawing into our main image
    [bg lockFocus];
    
	NSRect top;
	NSRect middle;
	NSRect footer;
	if ([self isKeyWindow] && yellow) {
		top = HEADER_ACTIVE_YELLOW;
		middle = MIDDLE_ACTIVE_YELLOW;
		footer = FOOTER_ACTIVE_YELLOW;
	} else if ([self isKeyWindow]) {
		top = HEADER_ACTIVE;
		middle = MIDDLE_ACTIVE;
		footer = FOOTER_ACTIVE;
	} else if ([NSApp isActive] && yellow) {
		top = HEADER_INACTIVE_YELLOW;
		middle = MIDDLE_INACTIVE_YELLOW;
		footer = FOOTER_INACTIVE_YELLOW;
	} else {
		top = HEADER_INACTIVE;
		middle = MIDDLE_INACTIVE;
		footer = FOOTER_INACTIVE;
	}

    // header
    [template
        drawInRect:NSMakeRect(0, [bg size].height - BG_TOP -.1, [bg size].width, BG_TOP) 
        fromRect:top
        operation:NSCompositeSourceOver 
        fraction:1.0];
		
    // middle
    [template
        drawInRect:NSMakeRect(0, BG_BOTTOM, [bg size].width, [bg size].height - BG_TOP - BG_BOTTOM) 
        fromRect:middle
        operation:NSCompositeSourceOver 
        fraction:1.0];
		
    // footer
    [template
        drawInRect:NSMakeRect(0, 0, [bg size].width, BG_BOTTOM) 
        fromRect:footer
        operation:NSCompositeSourceOver 
        fraction:1.0];

    [bg unlockFocus];
    
    return [NSColor colorWithPatternImage:[bg autorelease]];
}
@end
