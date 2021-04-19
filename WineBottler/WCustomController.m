/*
 * WCustomController.m
 * of the 'WineBottler' target in the 'WineBottler' project
 *
 * Copyright 2009 Mike Kronenberg
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



#import "WCustomController.h"
#import "WBottlerController.h"



@implementation WCustomController
- (void) awakeFromNib
{
	while([prefixes numberOfItems] > 1)
		[prefixes removeItemAtIndex:1];
	[prefixes addItemsWithTitles:[[NSUserDefaults standardUserDefaults] objectForKey:@"knownPrefixes"]];	
}


- (IBAction) createCustom:(id)sender
{
	[self askForFilename];
}



#pragma mark -
#pragma mark choose Filename
- (void) askForFilename
{
	NSSavePanel *savePanel;
    NSString *silent;
    NSString *template;
    NSString *installerSwitches;
    NSString *exe;
    BOOL tNoMono;
    BOOL tNoGecko;
    BOOL tNoUsers;
    BOOL tNoInstallers;
    BOOL selfcontained;
    NSArray *tCategoryTypes = [NSArray arrayWithObjects:
                               @"public.app-category.business",
                               @"public.app-category.developer-tools",
                               @"public.app-category.education",
                               @"public.app-category.entertainment",
                               @"public.app-category.finance",
                               @"public.app-category.games",
                               @"public.app-category.graphics-design",
                               @"public.app-category.healthcare-fitness",
                               @"public.app-category.lifestyle",
                               @"public.app-category.medical",
                               @"public.app-category.music",
                               @"public.app-category.news",
                               @"public.app-category.photography",
                               @"public.app-category.productivity",
                               @"public.app-category.reference",
                               @"public.app-category.social-networking",
                               @"public.app-category.sports",
                               @"public.app-category.travel",
                               @"public.app-category.utilities",
                               @"public.app-category.video",
                               @"public.app-category.weather",
                               nil];
    NSArray *tSystemVersionInfo = [NSArray arrayWithObjects:
                               @"win95",
                               @"win98",
                               @"win2k",
                               @"winxp",
                               @"win2k3",
                               @"win7",
                               nil];
    
    template = nil;
    if ([prefixes indexOfSelectedItem] > 0)
        template = [prefixes titleOfSelectedItem];
    
    exe = @"winefile";
    installerSwitches = [switches stringValue];
    switch ([copyInstall selectedRow]) {
        case 1:
            exe = [NSString stringWithFormat:@"C:\\winebottler\\%@", [[installer stringValue] lastPathComponent]];
            installerSwitches = @"WINEBOTTLERCOPYFILEONLY";
            break;
        case 2:
            exe = [NSString stringWithFormat:@"C:\\winebottler\\%@", [[installer stringValue] lastPathComponent]];
            installerSwitches = @"WINEBOTTLERCOPYFOLDERONLY";
            break;
    }
    
    tNoMono = FALSE;
    if ([noMono state] == NSOffState)
        tNoMono = TRUE;
    
    tNoGecko = FALSE;
    if ([noGecko state] == NSOffState)
        tNoGecko = TRUE;
    
    tNoUsers = FALSE;
    if ([noUsers state] == NSOnState)
        tNoUsers = TRUE;
    
    tNoInstallers= FALSE;
    if ([noInstallers state] == NSOnState)
        tNoInstallers = TRUE;
    
    selfcontained = FALSE;
    if ([selfcontainedInstall state] == NSOnState)
        selfcontained = TRUE;
    
    silent = @"";
    if ([silentInstall state] == NSOnState)
        silent = @"-q";
    
	savePanel = [NSSavePanel savePanel];
	[savePanel setExtensionHidden:YES];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"app"]];
	[savePanel setCanCreateDirectories:YES];
    [savePanel beginSheetModalForWindow:[bottlerController bottlerWindow] completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSModalResponseOK) {
            [[[WBottler alloc] initWithScript:nil
                                          URL:[savePanel URL]
                                     template:template
                                 installerURL:[installer stringValue]
                            installerIsZipped:nil
                                installerName:[[installer stringValue] lastPathComponent]
                           installerArguments:installerSwitches
                                       noMono:tNoMono
                                      noGecko:tNoGecko
                                      noUsers:tNoUsers
                                      noInstallers:tNoInstallers
                                   winetricks:[NSString stringWithFormat:@"%@ %@", [tSystemVersionInfo objectAtIndex:[systemVersionInfo indexOfSelectedItem]], [winetricksController winetricks]]
                                    overrides:[overriedes stringValue]
                                          exe:exe
                                 exeArguments:[executableArguments stringValue]
                                bundleCopyright:[bundleCopyright stringValue]
                                bundleVersion:[bundleVersion stringValue]
                             bundleIdentifier:[bundleIdentifier stringValue]
                           bundleCategoryType:[tCategoryTypes objectAtIndex:[bundleCategoryType indexOfSelectedItem]]
                              bundleSignature:[bundleSignature stringValue]
                                       silent:silent
                                selfcontained:selfcontained
                                       sender:bottlerController
                                     callback:nil] autorelease];
        }
    }];
}



#pragma mark -
#pragma mark selectInstaller
- (IBAction) selectInstaller:(id)sender
{
	NSOpenPanel *openPanel;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"exe",@"msi",nil]];
	[openPanel setAllowsMultipleSelection:NO];
    [openPanel beginSheetModalForWindow:[bottlerController bottlerWindow] completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSModalResponseOK) {
            [installer setStringValue:[[openPanel URL] path]];
        }
    }];
}
@end
