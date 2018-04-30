/*
 * WBottlerController.m
 * of the 'WineBottler' target in the 'WineBottler' project
 *
 * Copyright 2009 - 2018 Mike Kronenberg
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



#import "WBottlerController.h"

//#define PREDEFINED_URL @"http://localhost/~mike/winebottler/"
#define PREDEFINED_URL @"https://winebottler.kronenberg.org/winebottler/"
#define APPSUPPORT_WINE [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/Wine/"]
#define APPSUPPORT_WINEBOTTLER [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/WineBottler/"]

#define SHOWCASE_APPS @"adobeair cmd kde kindle mozillabuild openwatcom 7zip abiword adobe_diged autohotkey kobo cmake controlpad cygwin dxdiag firefox35 firefox36 firefox5 firefox irfanview ie6 ie7 ie8 mingw mpc mspaint nook opera psdk2003 psdkwin7 python26 python26_comtypes spotify safari sketchup steam utorrent utorrent3 vc2005express vc2005trial vlc winamp wmp9 wmp10 3dmark2000 3dmark2001 3dmark03 3dmark05 3dmark06 unigine_heaven wglgears depends plc shareholder2 metatrader buspro elster divagis teach2000"

/*
 Installer auf bestimmte DLLs untersuchen
 grep --binary-file=text -c GDI32.dll /Users/mike/Downloads/7z920.exe
 AdobeAir
 Mono
 mfc40
 vb2run
 vb3run
 vb4run
 vb5run
 vb6run
 #vcrun6 (mfc42, msvcp60, msvcirt)
 vcrun6sp6 (mfc42, msvcp60, msvcirt)
 vcrun2003 (mfc71, msvcp71, msvcr71)
 vcrun2005 (mfc80, msvcp80, msvcr80)
 vcrun2008 (mfc90, msvcp90, msvcr90)
 vcrun2010 (mfc100, msvcp100, msvcr100)
*/



@implementation WBottlerController
- (id) init
{
    BOOL dir;
    
	self = [super init];
	if (self) {
        isWindowRevealed = NO;
        
        // see that we have an Application Support directory
        if (![[NSFileManager defaultManager] fileExistsAtPath:APPSUPPORT_WINEBOTTLER isDirectory:&dir])
            [[NSFileManager defaultManager] createDirectoryAtPath:APPSUPPORT_WINEBOTTLER withIntermediateDirectories:YES attributes:nil error:nil];
        
		// predefined
		NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"predefined" ofType:@"html"];
		predefinedTemplate = [[NSString alloc] initWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
        predefinedBottles = [[NSArray alloc] init];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(predefinedUpdated:) name:@"WineBottlerPredefinedChanged" object:nil];	
		
		// prefixes
		prefixFound = [[NSArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"knownPrefixes"]] retain];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixQuery:) name:@"WineBottlerPrefixesChanged" object:nil];	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefixQueryFinished:) name:NSMetadataQueryDidFinishGatheringNotification object:prefixMetadataQuery];
	}
	return self;
}


- (void) dealloc
{
	// predefined
    if (predefinedApps)
        [predefinedApps release];
	[predefinedTemplate release];
	[predefinedBottles release];
	
	// prefixes
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[prefixMetadataQuery release];
	[prefixFound release];
	
	[super dealloc];
}


- (NSString *) stringWithContentsOfURLNoCache:(NSURL *)url {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    NSData *urlData;
    NSURLResponse *response;
    NSError *error;
    
    urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error];
    return [[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] autorelease];
}


- (BOOL) checkInternet {
    NSURLResponse *response;
    NSError *error;
    NSURL *url = [NSURL URLWithString:PREDEFINED_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"HEAD";
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    request.timeoutInterval = 10.0;
    if (![NSURLConnection sendSynchronousRequest:request returningResponse:&response error: &error]) {
        NSLog(@"%@", error);
    };
    
    return ([(NSHTTPURLResponse *)response statusCode] == 200);
}


- (void) checkUpdate:(id)sender {
    NSString *string;
    NSString *oldVersion;
    NSMutableAttributedString * link;
    NSAlert *alert;
    NSTextView *av;
    
    NSLog(@"WineBottler: checkUpdate1: %@", NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"]);
    string = [self stringWithContentsOfURLNoCache:[NSURL URLWithString:[NSString stringWithFormat:@"%@latest", PREDEFINED_URL ]]];
    if (string && [string length]) {
        NSLog(@"WineBottler: checkUpdate2: %@", string);
        if (![string isEqualToString:NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"]]) {
            oldVersion = [NSString stringWithFormat:@"Your are using WineBottler %@ now.\nDownload WineBottler %@ at\n\nwinebottler.kronenberg.org.", NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"], string];
            link = [[NSMutableAttributedString alloc] initWithString:oldVersion];
            [link addAttribute:NSLinkAttributeName value: @"https://winebottler.kronenberg.org" range: NSMakeRange([oldVersion length] - 27, 26)];
            av = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 250, 50)];
            [av insertText:link];
            [av setDrawsBackground:NO];
            alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"WineBottler %@ of available", string]
                                    defaultButton:@"OK"
                                  alternateButton:nil
                                      otherButton:nil
                        informativeTextWithFormat:@""];
            alert.accessoryView = av;
            [alert runModal];
        } else if (![sender isEqual:self]) {
            alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"You are running the latest version of WineBottler"]
                                    defaultButton:@"OK"
                                  alternateButton:nil
                                      otherButton:nil
                        informativeTextWithFormat:@""];
            [alert runModal];
        }
    } else {
        alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Can't connect to winebottler.kronenberg.org!"]
                                defaultButton:@"OK"
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@""];
        [alert runModal];
    }
}


-(void) awakeFromNib
{
    NSString *string;
    NSAlert *alert;
    NSError *error;
    
    [self showPredefinedWeb:self];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setIndeterminate:YES];
    [progressIndicator startAnimation:self];
    
    // check if the internet is up:
    if (![self checkInternet]) {
        NSLog(@"Can't connect to the internet");
        alert = [NSAlert alertWithMessageText:@"No Connection to the Internet"
                                defaultButton:@"OK"
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@"You can still use WineBottler, but some functions like \"Download\" and \"Winetricks\" will only work, if cached data is available. To update, just restart WineBottler, once you have an internet connection."];
        [alert runModal];
        [self revealBottlerWindow:self];
        return;
    }
    
    [updatePanel makeKeyAndOrderFront:self];

    // check for update
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"updateCheck"]) {
        [self checkUpdate: self];
    }
    
    // update showcase
    string = [self stringWithContentsOfURLNoCache:[NSURL URLWithString:[NSString stringWithFormat:@"%@winebottler.plist", PREDEFINED_URL ]]];
    if (string) {
        if (![string writeToURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@winebottler.plist", APPSUPPORT_WINEBOTTLER]] atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"%@", error);
        }
    } else {
        NSLog(@"Can't update winebottler.plist");
    }
    
    // update metadata
    string = [self stringWithContentsOfURLNoCache:[NSURL URLWithString:[NSString stringWithFormat:@"%@metadata.plist", PREDEFINED_URL ]]];
    if (string) {
        if (![string writeToURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@metadata.plist", APPSUPPORT_WINEBOTTLER]] atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"%@", error);
        }
    } else {
        NSLog(@"Can't update metadata.plist");
    }
}


-(void) revealBottlerWindow:(id)sender
{
    [predefinedSearchField setAutoresizingMask:NSViewMinXMargin];
    [toolbarButton1.image setTemplate:YES];
    [toolbarButton2.image setTemplate:YES];
    [toolbarButton3.image setTemplate:YES];
    isWindowRevealed = YES;
    
	// prefixes
    [bottlerViewPrefixes setDrawsBackground:NO];
	[self prefixQuery:self];
	
	// predefined
    predefinedApps = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@winebottler.plist", APPSUPPORT_WINEBOTTLER]]];
    [bottlerViewPredefined setDrawsBackground:NO];
	[self predefinedUpdated:self];
    
    [bottlerWindow makeKeyAndOrderFront:self];
    [updatePanel orderOut:self];
}



#pragma mark -
#pragma mark general
- (void) killWine:(id)sender
{
	NSTask *task;
	
	task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
	[task setArguments:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@/killwine.sh", [[NSBundle mainBundle] resourcePath]]]];
	[task launch];
	[task waitUntilExit];
	[task release];
}


- (void) explanationHide:(NSString *)tHide
{
	NSUserDefaults *userDefaults;
	
	userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:NO forKey:tHide];
	[userDefaults synchronize];
	
	[self predefinedSearch:self];
	[self prefixSearch:self];
}



#pragma mark -
#pragma mark navigation
- (void) showPrefixes:(id)sender
{
    [self prefixQuery:self];
	if ([bottlerViewCustom superview]) {
		[bottlerViewCustom retain];
		[bottlerViewCustom removeFromSuperview];
	} else if ([bottlerViewPredefined superview]) {
		[bottlerViewPredefined retain];
		[bottlerViewPredefined removeFromSuperview];
	}
    [toolbarButton1 setState:0];
    [toolbarButton2 setState:1];
    [toolbarButton3 setState:0];
	[bottlerViewRight addSubview:bottlerViewPrefixes];
	[bottlerViewPrefixes setFrame:[bottlerViewRight bounds]];
}


- (void) showPredefinedWeb:(id)sender
{
	if ([bottlerViewPrefixes superview]) {
		[bottlerViewPrefixes retain];
		[bottlerViewPrefixes removeFromSuperview];
	} else if ([bottlerViewCustom superview]) {
		[bottlerViewCustom retain];
		[bottlerViewCustom removeFromSuperview];
	}
    [toolbarButton1 setState:1];
    [toolbarButton2 setState:0];
    [toolbarButton3 setState:0];
	[bottlerViewRight addSubview:bottlerViewPredefined];
	[bottlerViewPredefined setFrame:[bottlerViewRight bounds]];
}


- (void) showCustom:(id)sender
{
	if ([bottlerViewPrefixes superview]) {
		[bottlerViewPrefixes retain];
		[bottlerViewPrefixes removeFromSuperview];
	} else if ([bottlerViewPredefined superview]) {
		[bottlerViewPredefined retain];
		[bottlerViewPredefined removeFromSuperview];
	}
    [toolbarButton1 setState:0];
    [toolbarButton2 setState:0];
    [toolbarButton3 setState:1];
	[bottlerViewRight addSubview:bottlerViewCustom];
	[bottlerViewCustom setFrame:[bottlerViewRight bounds]];
}



#pragma mark -
#pragma mark predefined
- (IBAction) predefinedUpdated:(id)sender
{
    NSArray *tWinetricks;
    NSDictionary *tMetadata;
	NSMutableDictionary *programProperties;
    
    tWinetricks = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@winetricks.plist", APPSUPPORT_WINE]]];
    tMetadata = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@metadata.plist", APPSUPPORT_WINEBOTTLER]]];
    
    if (tWinetricks) {
        if (predefinedBottles)
            [predefinedBottles release];
        predefinedBottles = [tWinetricks mutableCopy];
        [tWinetricks release];
        for (programProperties in predefinedBottles) {
            if ([tMetadata objectForKey:[programProperties objectForKey:@"verb"]]) {
                [programProperties setObject:[[tMetadata objectForKey:[programProperties objectForKey:@"verb"]] objectForKey:@"exe"] forKey:@"installed_exe1"];
            }
        }
    }
    [self predefinedSearch:self];
    
    if (!isWindowRevealed) {
        [self revealBottlerWindow:self];
    }
    [tMetadata release];
}


- (IBAction) predefinedSearch:(id)sender
{
    NSArray *foundBottles;
    NSSortDescriptor *sortDescriptor;
	NSPredicate *predicate;
	NSString *search;
	NSDictionary *programProperties;
	NSMutableString *items;
	NSString *explanation;
    NSString *category;
    NSString *verb;
    NSArray *keys;
	
    if (![sender isEqual:self])
        [self showPredefinedWeb:self];

    [[NSUserDefaults standardUserDefaults] synchronize];
    sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    
    search = [predefinedSearchField stringValue];
    if ([search isEqual:@""]) {
        items = [NSMutableString stringWithString:@""];
        keys = [[predefinedApps allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];

        for (category in keys) {
            [items appendFormat:@"<div><h1>%@</h1>", category];
            for (verb in [predefinedApps objectForKey:category]) {
                for (programProperties in predefinedBottles) {
                    if([[programProperties objectForKey:@"verb"] isEqual:verb]) {
                        [items appendFormat:NSLocalizedStringFromTable(@"WBottlerController:predefined:item", @"Localizable", @"WBottlerController"),
                         [NSString stringWithFormat:@"%@96icons/%@.png", PREDEFINED_URL, [programProperties objectForKey:@"verb"]],
                         [programProperties objectForKey:@"homepage"],
                         [programProperties objectForKey:@"title"],
                         [programProperties objectForKey:@"publisher"],
                         [programProperties objectForKey:@"year"],
                         [programProperties objectForKey:@"verb"]];
                        break;
                    }
                }
            }
            [items appendString:@"</div>"];
        }
    } else {
        predicate = [NSPredicate predicateWithFormat:@"(title CONTAINS[cd] %@) && ((category == \"apps\") || (category == \"games\")) && (media == \"download\")", search];
        foundBottles = [[predefinedBottles filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        items = [NSMutableString stringWithString:@"<div>"];
        for (programProperties in foundBottles) {
            [items appendFormat:NSLocalizedStringFromTable(@"WBottlerController:predefined:item", @"Localizable", @"WBottlerController"),
             [NSString stringWithFormat:@"%@96icons/%@.png", PREDEFINED_URL, [programProperties objectForKey:@"verb"]],
             [programProperties objectForKey:@"homepage"],
             [programProperties objectForKey:@"title"],
             [programProperties objectForKey:@"publisher"],
             [programProperties objectForKey:@"year"],
             [programProperties objectForKey:@"verb"]];
        }
        [items appendString:@"</div>"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"predefinedExplanation"]) {
        explanation = NSLocalizedStringFromTable(@"WBottlerController:predefined:explanation", @"Localizable", @"WBottlerController");
    } else {
        explanation = @"";
    }
    [[bottlerViewPredefinedWebView mainFrame] loadHTMLString:[NSString stringWithFormat:predefinedTemplate, explanation, items] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
}


- (void) askForFilename:(NSString *)filename
{
	NSSavePanel *savePanel;
	NSDictionary *programProperties;
    NSString *exe;
    
    for (programProperties in predefinedBottles) {
        if ([[programProperties objectForKey:@"verb"] isEqual:filename]) {
            
            if ([programProperties objectForKey:@"installed_exe1"]) {
                exe = [programProperties objectForKey:@"installed_exe1"];
            } else if ([programProperties objectForKey:@"installed_file1"] && ([[[programProperties objectForKey:@"installed_file1"] substringFromIndex:[[programProperties objectForKey:@"installed_file1"] length] - 4] isEqual:@".exe"])) {
                exe = [programProperties objectForKey:@"installed_file1"];
            } else {
                exe = @"winefile";
            }
            
            savePanel = [NSSavePanel savePanel];
            [savePanel setExtensionHidden:YES];
            [savePanel setNameFieldStringValue:[programProperties objectForKey:@"title"]];
            [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"app"]];
            [savePanel setCanCreateDirectories:YES];
            [savePanel beginSheetModalForWindow:bottlerWindow completionHandler:^(NSInteger returnCode) {
                if (returnCode == NSOKButton) {
                    [[[WBottler alloc] initWithScript:[programProperties objectForKey:@"script"]
                                                  URL:[savePanel URL]
                                             template:nil
                                         installerURL:nil
                                    installerIsZipped:nil
                                        installerName:nil
                                   installerArguments:nil
                                               noMono:NO
                                               noGecko:NO
                                               noUsers:NO
                                               noInstallers:NO
                                           winetricks:[programProperties objectForKey:@"verb"]
                                            overrides:nil
                                                  exe:exe
                                         exeArguments:nil
                                      bundleCopyright:nil
                                        bundleVersion:nil
                                     bundleIdentifier:[NSString stringWithFormat:@"org.kronenberg.winebottler.%@", [programProperties objectForKey:@"verb"]]
                                   bundleCategoryType:nil
                                      bundleSignature:nil
                                               silent:@"-q"
                                        selfcontained:FALSE
                                               sender:self
                                             callback:nil] autorelease];
                }
            }];
            break;
        }
    }
}



#pragma mark -
#pragma mark prefix
- (IBAction) prefixQuery:(id)sender
{
	NSUInteger i;
	NSUserDefaults *userDefaults;
	NSMutableArray *knownPrefixes;
	NSPredicate *predicate;
	
	userDefaults = [NSUserDefaults standardUserDefaults];
	
	// remove obsolete entries
	knownPrefixes = [[[userDefaults objectForKey:@"knownPrefixes"] mutableCopy] autorelease];
	for (i = [knownPrefixes count] - 1; i > -1; i--) {
		if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/WineBottler.id", [knownPrefixes objectAtIndex:i]]]) {
			[knownPrefixes removeObjectAtIndex:i];
		}
	}
	
	[userDefaults setObject:knownPrefixes forKey:@"knownPrefixes"];
	[userDefaults synchronize];
	
	// search new entries
	prefixMetadataQuery = [[NSMetadataQuery alloc] init];
	[prefixMetadataQuery setDelegate:self];
	predicate = [NSPredicate predicateWithFormat:@"kMDItemDisplayName ENDSWITH 'WineBottler.id' OR kMDItemKind == 'Application'", nil];
	[prefixMetadataQuery setPredicate:predicate];
	[prefixMetadataQuery setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryLocalComputerScope]];
	[prefixMetadataQuery startQuery];	
}


- (void)prefixQueryFinished:(NSNotification*)note
{
	int i;
	NSUserDefaults *userDefaults;
	NSArray *searchResults;
	NSString *path;
	NSMutableArray *knownPrefixes;
	//NSSortDescriptor *sortDescriptor;
    
    //sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
	
	userDefaults = [NSUserDefaults standardUserDefaults];
	knownPrefixes = [[[userDefaults objectForKey:@"knownPrefixes"] mutableCopy] autorelease];
	searchResults = [(NSMetadataQuery*)[note object] results];

	for (i = 0; i < [searchResults count]; i++) {
        // search working copies
        if ([[[[searchResults objectAtIndex:i] valueForAttribute: (NSString *)kMDItemPath] lastPathComponent] isEqual:@"WineBottler.id"]) {
            if (![[[[[searchResults objectAtIndex:i] valueForAttribute: (NSString *)kMDItemPath] stringByDeletingLastPathComponent] lastPathComponent] isEqual:@"wineprefix"]) {
                path = [[[[searchResults objectAtIndex:i] valueForAttribute: (NSString *)kMDItemPath] stringByResolvingSymlinksInPath] stringByDeletingLastPathComponent];
                if (![knownPrefixes containsObject:path]) {
                    [knownPrefixes addObject:path];
                }
            }
        // search new apps
		} else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents/Resources/wineprefix/WineBottler.id", [[searchResults objectAtIndex:i] valueForAttribute:(NSString *)kMDItemPath]]]) {
			path = [NSString stringWithFormat:@"%@/Contents/Resources", [[searchResults objectAtIndex:i] valueForAttribute: (NSString *)kMDItemPath]];
			if (![knownPrefixes containsObject:path]) {
				[knownPrefixes addObject:path];
			}
        // search old apps
		} else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents/Resources/WineBottler.id", [[searchResults objectAtIndex:i] valueForAttribute:(NSString *)kMDItemPath]]]) {
			path = [NSString stringWithFormat:@"%@/Contents/Resources", [[searchResults objectAtIndex:i] valueForAttribute: (NSString *)kMDItemPath]];
			if (![knownPrefixes containsObject:path]) {
				[knownPrefixes addObject:path];
			}
		}
	}
    
    if (prefixFound)
        [prefixFound release];
	prefixFound = knownPrefixes;
    [prefixFound retain];
    
	[userDefaults setObject:prefixFound forKey:@"knownPrefixes"];
	[userDefaults synchronize];
	
	[self prefixSearch:self];
}

- (NSString *) iconToBase64:(NSString *)icon {
    NSArray *keys = [NSArray arrayWithObject:@"NSImageCompressionFactor"];
    NSArray *objects = [NSArray arrayWithObject:@"1.0"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:icon];
    NSBitmapImageRep *iconImageBitmapRep = [[NSBitmapImageRep alloc] initWithData:[iconImage TIFFRepresentation]];
    NSData *iconData = [iconImageBitmapRep representationUsingType:NSPNGFileType properties:dictionary];
    return [NSString stringWithFormat:@"data:image/png;base64,%@", [iconData base64EncodedStringWithOptions:NULL]];
}

- (IBAction) prefixSearch:(id)sender
{
	int i;
	NSString *program;
	NSMutableString *items;
	NSMutableString *lonePrefixes;
	NSRange range;
	NSString *path;
    NSString *appPath;
	NSString *name;
	NSString *icon;
	NSString *explanation;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"prefixExplanation"]) {
        explanation = NSLocalizedStringFromTable(@"WBottlerController:prefix:explanation", @"Localizable", @"WBottlerController");
    } else {
        explanation = @"";
    }
    
    items = [NSMutableString stringWithString:@"<div><h1>Installed WineBottler Applications</h1>"];
    lonePrefixes = [NSMutableString stringWithString:@""];
    for (i = 0; i < [prefixFound count]; i++) {
        program = [prefixFound objectAtIndex:i];
        range = [program rangeOfString:@".app"];
        if (range.location != NSNotFound) {
            path = [program substringToIndex:range.location + 4];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { // see if the app actually exists!
                name = [[path lastPathComponent] substringToIndex:[[path lastPathComponent] length] - 4];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents/Resources/Icon.icns", path]]) {
                    icon = [NSString stringWithFormat:@"%@/Contents/Resources/Icon.icns", path];
                } else {
                    icon = [NSString stringWithFormat:@"%@/Application.icns", [[NSBundle mainBundle] resourcePath]];
                }
                
                [items appendFormat:NSLocalizedStringFromTable(@"WBottlerController:prefix:item", @"Localizable", @"WBottlerController"),
                 path,
                 [self iconToBase64:icon],
                 name,
                 path,
                 path,
                 path];
            }
        } else {
            path = program;
            appPath = [[ NSWorkspace sharedWorkspace ] absolutePathForAppBundleWithIdentifier:[path lastPathComponent]];
            if (!appPath && [[NSFileManager defaultManager] fileExistsAtPath:path]) { // see if the folder actually exists!
                name = path;
                icon = [NSString stringWithFormat:@"%@/Programs.icns", [[NSBundle mainBundle] resourcePath]];
                [lonePrefixes appendFormat:NSLocalizedStringFromTable(@"WBottlerController:prefix:prefix", @"Localizable", @"WBottlerController"),
                 [self iconToBase64:icon],
                 name,
                 path,
                 path];
            }
        }
    }
    [items appendString:@"</div>"];
    
    if (![lonePrefixes isEqual:@""]) {
        [items appendString:@"</div><div><h1>Other Wine prefixes</h1>"];
        [items appendString:lonePrefixes];
        [items appendString:@"</div>"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[bottlerViewPrefixWebView mainFrame] loadHTMLString:[NSString stringWithFormat:predefinedTemplate, explanation, items] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
    });
}


- (void) prefixDelete:(NSString *)tPath
{	
	NSRange range;
	NSString *path;
	NSAlert *alert;
    
	range = [tPath rangeOfString:@".app"];
	if (range.location != NSNotFound) {
		path = [tPath substringToIndex:range.location + 4];
    } else {
        path = tPath;
    }
    alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"WBottlerController:prefixDelete:setMessageText", @"Localizable", @"WBottlerController"), [path lastPathComponent]]];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"WBottlerController:prefixDelete:setInformativeText", @"Localizable", @"WBottlerController"), [path lastPathComponent]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"WBottlerController:prefixDelete:addButtonWithTitle:Remove", @"Localizable", @"WBottlerController")];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"WBottlerController:prefixDelete:addButtonWithTitle:Cancel", @"Localizable", @"WBottlerController")];
    [alert beginSheetModalForWindow:bottlerWindow
                      modalDelegate:self
                     didEndSelector:@selector(prefixDeleteAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:[tPath retain]];
}


- (void)prefixDeleteAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSRange range;
	NSString *path;
    NSError *error;
	
	switch (returnCode) {
		case NSAlertFirstButtonReturn:
			range = [(NSString *)contextInfo rangeOfString:@".app"];
			if (range.location != NSNotFound) {
				
				// get rid of all auxiliary files
				[(NSString *)contextInfo retain];
				[self prefixResetAlertDidEnd:alert returnCode:returnCode contextInfo:contextInfo];
				
				// get rid of app itself
				path = [(NSString *)contextInfo substringToIndex:range.location + 4];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                    if (![[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:&error])
                        NSLog(@"Removing App: %@ Error: %@", path, error);
				
			} else {
				path = (NSString *)contextInfo;
                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                    if (![[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:&error])
                        NSLog(@"Removing Wine.app prefix: %@ Error: %@", contextInfo, error);
            }
            [self prefixSearch:self];
			break;
            
		case NSAlertSecondButtonReturn:
			break;
	}
	
	[(NSString *)contextInfo release];
}


- (void) prefixReset:(NSString *)tPath
{
	NSRange range;
	NSString *path;
	NSAlert *alert;
	
	range = [tPath rangeOfString:@".app"];
	if (range.location != NSNotFound) {
		path = [tPath substringToIndex:range.location + 4];
		alert = [[NSAlert alloc] init];
		[alert setMessageText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"WBottlerController:prefixReset:setMessageText", @"Localizable", @"WBottlerController"), [path lastPathComponent]]];
		[alert setInformativeText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"WBottlerController:prefixReset:setInformativeText", @"Localizable", @"WBottlerController"), [path lastPathComponent]]];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert addButtonWithTitle:NSLocalizedStringFromTable(@"WBottlerController:prefixReset:addButtonWithTitle:Reset", @"Localizable", @"WBottlerController")];
		[alert addButtonWithTitle:NSLocalizedStringFromTable(@"WBottlerController:prefixReset:addButtonWithTitle:Cancel", @"Localizable", @"WBottlerController")];
		[alert beginSheetModalForWindow:bottlerWindow
						  modalDelegate:self
						 didEndSelector:@selector(prefixResetAlertDidEnd:returnCode:contextInfo:)
							contextInfo:[tPath retain]];
	}
}


- (void)prefixResetAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSRange range;
	NSString *path;
	NSString *appIdentifier;
	NSDictionary *info;
    NSError *error;
	
	switch (returnCode) {
		case NSAlertFirstButtonReturn:
			
			range = [(NSString *)contextInfo rangeOfString:@".app"];
			if (range.location != NSNotFound) {
				path = [(NSString *)contextInfo substringToIndex:range.location + 4];
				
				// get app id out of Info.plist
				info = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Contents/Info.plist", path]]];
				appIdentifier = [info objectForKey:@"CFBundleIdentifier"];

				// remove prefix from Application Data
				path = [[NSString stringWithFormat:@"~/Library/Application Support/%@", appIdentifier] stringByExpandingTildeInPath];
				if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                    if (![[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:&error])
                        NSLog(@"Removing Application Data: %@ Error: %@", contextInfo, error);
				
				// ~/Library/preferences/
				path = [[NSString stringWithFormat:@"~/Library/Preferences/%@.plist", appIdentifier] stringByExpandingTildeInPath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                    if (![[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:&error])
                        NSLog(@"Removing Preferences: %@ Error: %@", contextInfo, error);
				
				// ~/.xinitrc.d/
				path = [[NSString stringWithFormat:@"~/.xinitrc.d/%@.sh", appIdentifier] stringByExpandingTildeInPath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path])
                    if (![[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:path] error:&error])
                        NSLog(@"Removing xinitrc.d: %@ Error: %@", contextInfo, error);
			}
			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"WineBottlerPrefixesChanged" object:nil];
			break;
		case NSAlertSecondButtonReturn:
			break;
	}
	
	[(NSString *)contextInfo release];
}


- (void) prefixShowInFinder:(NSString *)tPath
{
	NSRange range;
	NSString *path;
	
	range = [tPath rangeOfString:@".app"];
	if (range.location == NSNotFound) {
		path = tPath;
	} else {
		path = [[tPath substringToIndex:range.location + 4] stringByDeletingLastPathComponent] ;
	}
	[[NSWorkspace sharedWorkspace] openFile:path];
}



#pragma mark -
#pragma mark Getters & Setters
- (NSWindow *) bottlerWindow {return bottlerWindow;}
@end
