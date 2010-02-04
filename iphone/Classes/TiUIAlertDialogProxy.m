/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIAlertDialogProxy.h"
#import "TiUtils.h"

@implementation TiUIAlertDialogProxy

-(void)dealloc
{
	// we release our reteain in the show below but then
	// set it to nil so that our subclass doesn't jack with it
	[pageContext release];
	pageContext = nil;
	[super dealloc];
}

-(void)show:(id)args
{
	ENSURE_UI_THREAD(show,args);
	
	// we retain during our modal dialog and then release after its done.
	// this prevents crash on cleaning up the proxy/context while modal is completing
	[pageContext retain];
	[self retain];
	
	NSMutableArray *buttonNames = [self valueForKey:@"buttonNames"];
	if (buttonNames==nil || (id)buttonNames == [NSNull null])
	{
		buttonNames = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
		[buttonNames addObject:NSLocalizedString(@"OK",@"Alert OK Button")];
	}
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[self valueForKey:@"title"]
											message:[self valueForKey:@"message"] 
											delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
	for (id btn in buttonNames)
	{
		NSString * thisButtonName = [TiUtils stringValue:btn];
		[alert addButtonWithTitle:thisButtonName];
	}

	[alert setCancelButtonIndex:[TiUtils intValue:[self valueForKey:@"cancel"] def:-1]];
	
	[alert show];
}

#pragma mark AlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// cause this proxy to be cleaned up from retain above
	[self autorelease];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ([self _hasListeners:@"click"])
	{
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:buttonIndex],@"index",
							   [NSNumber numberWithInt:[alertView cancelButtonIndex]],@"cancel",
							   nil];
		[self fireEvent:@"click" withObject:event];
	}
}

@end
