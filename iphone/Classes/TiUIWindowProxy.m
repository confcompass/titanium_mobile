/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIWindowProxy.h"
#import "Webcolor.h"
#import "TiUIViewProxy.h"
#import "ImageLoader.h"
#import "TiComplexValue.h"

@implementation TiUIWindowProxy

-(void)_destroy
{
	RELEASE_TO_NIL(context);
	if (context!=nil)
	{
		[context shutdown];
		RELEASE_TO_NIL(context);
	}
	[super _destroy];
}

-(void)booted:(id)arg
{
	// nothing to do, in the future we might show and hide indicator on a context load 
	// but for now, nothing...
	contextReady = YES;
	[self open:nil];
}

#pragma mark Public

-(BOOL)_handleOpen:(id)args
{
	// this is a special case that calls open again above to cause the event lifecycle to
	// happen after the JS context is fully up and ready
	if (contextReady && context!=nil)
	{
		return YES;
	}
	
	//
	// at this level, open is top-level since this is a window.  if you want 
	// to open a window within a tab, you'll need to call tab.open(window)
	//
	
	NSURL *url = [TiUtils toURL:[self valueForKey:@"url"] proxy:self];
	
	//TODO: modal, etc
	
	if (url!=nil)
	{
		// Window based JS can only be loaded from local filesystem within app resources
		if ([url isFileURL] && [[[url absoluteString] lastPathComponent] hasSuffix:@".js"])
		{
			// since this function is recursive, only do this if we haven't already created the context
			if (context==nil)
			{
				//TODO: add activity indicator until booted
				RELEASE_TO_NIL(context);
				// set our new base
				[self _setBaseURL:url];
				contextReady=NO;
				context = [[KrollBridge alloc] initWithHost:[self _host]];
				NSDictionary *preload = [NSDictionary dictionaryWithObjectsAndKeys:self,@"currentWindow",[self.tab tabGroup],@"currentTabGroup",self.tab,@"currentTab",nil];
				[context boot:self url:url preload:preload];
				return NO;
			}
		}
		else 
		{
			id firstarg = args!=nil && [args count] > 0 ? [args objectAtIndex:0] : nil;
			NSMutableDictionary *args_ = [firstarg isKindOfClass:[NSDictionary class]] ? [NSMutableDictionary dictionaryWithDictionary:firstarg] : [NSMutableDictionary dictionary];
			[args_ setObject:url forKey:@"url"];
			
			// we need to create a webview implicitly if a url is passed to a window
			/*TiUIWebViewProxy *webview = [[TiUIWebViewProxy alloc] _initWithPageContext:[self pageContext] args:[NSArray arrayWithObject:args_]];
			[self add:[NSArray arrayWithObject:webview]];
			[webview open:args];
			[webview release];*/
		}
	}
	
	return YES;
}

-(void)windowDidClose
{
	if (context!=nil)
	{
		[context shutdown];
		RELEASE_TO_NIL(context);
	}
	[super windowDidClose];
}

-(BOOL)_handleClose:(id)args
{
	if (tab!=nil)
	{
		BOOL animate = args!=nil && [args count]>0 ? [TiUtils boolValue:@"animate" properties:[args objectAtIndex:0] def:YES] : YES;
		[tab windowClosing:self animated:animate];
	}
	return YES;
}

-(void)showNavBar:(NSArray*)args
{
	ENSURE_UI_THREAD(showNavBar,args);
	[self replaceValue:[NSNumber numberWithBool:NO] forKey:@"navBarHidden" notification:NO];
	if (controller!=nil)
	{
		id properties = (args!=nil && [args count] > 0) ? [args objectAtIndex:0] : nil;
		BOOL animated = [TiUtils boolValue:@"animated" properties:properties def:YES];
		[navbar setNavigationBarHidden:NO animated:animated];
	}
}

-(void)hideNavBar:(NSArray*)args
{
	ENSURE_UI_THREAD(hideNavBar,args);
	[self replaceValue:[NSNumber numberWithBool:YES] forKey:@"navBarHidden" notification:NO];
	if (controller!=nil)
	{
		id properties = (args!=nil && [args count] > 0) ? [args objectAtIndex:0] : nil;
		BOOL animated = [TiUtils boolValue:@"animated" properties:properties def:YES];
		[navbar setNavigationBarHidden:YES animated:animated];
		//TODO: need to fix height
	}
}

-(void)setBarColor:(id)colorString
{
	ENSURE_UI_THREAD(setBarColor,colorString);
	NSString *color = [TiUtils stringValue:colorString];
	[self replaceValue:color forKey:@"barColor" notification:NO];
	if (controller!=nil)
	{
		//TODO: do we need to be more flexible in the bar styles?
		
		if ([color isEqualToString:@"transparent"])
		{
			navbar.navigationBar.barStyle = UIBarStyleBlackTranslucent;
			navbar.navigationBar.translucent = YES;
		}
		else 
		{
			UIColor *acolor = UIColorWebColorNamed(color);
			navbar.navigationBar.tintColor = acolor;
			navbar.toolbar.tintColor = acolor;
			navbar.navigationBar.barStyle = UIBarStyleDefault;
		}
	}
}

-(void)setTranslucent:(id)value
{
	ENSURE_UI_THREAD(setTranslucent,value);
	[self replaceValue:value forKey:@"translucent" notification:NO];
	if (controller!=nil)
	{
		navbar.navigationBar.translucent = [TiUtils boolValue:value];
	}
}

-(void)setRightNavButton:(id)proxy withObject:(id)properties
{
	ENSURE_UI_THREAD_WITH_OBJ(setRightNavButton,proxy,properties);
	if (controller!=nil)
	{
		ENSURE_TYPE_OR_NIL(proxy,TiViewProxy);
		[self replaceValue:proxy forKey:@"rightNavButton" notification:NO];
		if (proxy==nil || [proxy supportsNavBarPositioning])
		{
			// detach existing one
			UIBarButtonItem *item = controller.navigationItem.rightBarButtonItem;
			if (item!=nil && [item isKindOfClass:[TiViewProxy class]])
			{
				[(TiViewProxy*)item removeNavBarButtonView];
			}
			if (proxy!=nil)
			{
				// add the new one
				BOOL animated = [TiUtils boolValue:@"animated" properties:properties def:YES];
				[controller.navigationItem setRightBarButtonItem:[proxy barButtonItem] animated:animated];
			}
			else 
			{
				controller.navigationItem.rightBarButtonItem = nil;
			}
		}
		else
		{
			NSString *msg = [NSString stringWithFormat:@"%@ doesn't support positioning on the nav bar",proxy];
			THROW_INVALID_ARG(msg);
		}
	}
	else 
	{
		[self replaceValue:[[[TiComplexValue alloc] initWithValue:proxy properties:properties] autorelease] forKey:@"rightNavButton" notification:NO];
	}
}

-(void)setLeftNavButton:(id)proxy withObject:(id)properties
{
	ENSURE_UI_THREAD_WITH_OBJ(setLeftNavButton,proxy,properties);
	if (controller!=nil)
	{
		ENSURE_TYPE_OR_NIL(proxy,TiViewProxy);
		[self replaceValue:proxy forKey:@"leftNavButton" notification:NO];
		if (proxy==nil || [proxy supportsNavBarPositioning])
		{
			// detach existing one
			UIBarButtonItem *item = controller.navigationItem.leftBarButtonItem;
			if (item!=nil && [item isKindOfClass:[TiViewProxy class]])
			{
				[(TiViewProxy*)item removeNavBarButtonView];
			}
			if (proxy!=nil)
			{
				// add the new one
				BOOL animated = [TiUtils boolValue:@"animated" properties:properties def:YES];
				[controller.navigationItem setLeftBarButtonItem:[proxy barButtonItem] animated:animated];
			}
			else 
			{
				controller.navigationItem.leftBarButtonItem = nil;
			}
		}
		else
		{
			NSString *msg = [NSString stringWithFormat:@"%@ doesn't support positioning on the nav bar",proxy];
			THROW_INVALID_ARG(msg);
		}
	}
	else
	{
		[self replaceValue:[[[TiComplexValue alloc] initWithValue:proxy properties:properties] autorelease] forKey:@"leftNavButton" notification:NO];
	}
}

-(void)setTitleControl:(id)proxy
{
	ENSURE_UI_THREAD(setTitleControl,proxy);
	[self replaceValue:proxy forKey:@"titleControl" notification:NO];
	if (controller!=nil)
	{
		ENSURE_TYPE_OR_NIL(proxy,TiViewProxy);
		
		if (proxy!=nil)
		{
			UIView * newTitleView = [proxy view];
			if (CGRectIsEmpty([newTitleView bounds]))
			{
				CGRect f;
				f.origin = CGPointZero;
				f.size = [newTitleView sizeThatFits:[TiUtils navBarTitleViewSize]];
				[proxy view].bounds = f;
			}
			[newTitleView setAutoresizingMask:UIViewAutoresizingNone];
			controller.navigationItem.titleView = newTitleView;
		}
		else 
		{
			controller.navigationItem.titleView = nil;
		}
	}
}

-(void)setTitleImage:(id)image
{
	ENSURE_UI_THREAD(setTitleImage,image);
	[self replaceValue:image forKey:@"titleImage" notification:NO];
	if (controller!=nil)
	{
		NSURL *path = [TiUtils toURL:image proxy:self];
		if (path!=nil)
		{
			UIImage *image = [[ImageLoader sharedLoader] loadImmediateImage:path];
			if (path!=nil)
			{
				UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
				controller.navigationItem.titleView = imageView;
				[imageView release];
				return;
			}
		}
		controller.navigationItem.titleView = nil;
	}
}

-(void)setTitle:(NSString*)title_
{
	ENSURE_UI_THREAD(setTitle,title_);
	NSString *title = [TiUtils stringValue:title_];
	[self replaceValue:title forKey:@"title" notification:NO];
	if (controller!=nil)
	{
		controller.navigationItem.title = title;
	}
}

-(void)setTitlePrompt:(NSString*)title_
{
	ENSURE_UI_THREAD(setTitlePrompt,title_);
	NSString *title = [TiUtils stringValue:title_];
	[self replaceValue:title forKey:@"titlePrompt" notification:NO];
	if (controller!=nil)
	{
		controller.navigationItem.prompt = title;
	}
}

-(void)setToolbar:(id)items withObject:(id)properties
{
	ENSURE_UI_THREAD_WITH_OBJ(setToolbar,items,properties);
	if (controller!=nil)
	{
		ENSURE_TYPE_OR_NIL(items,NSArray);
		[self replaceValue:items forKey:@"toolbar" notification:NO];
		
		// detatch the current ones
		NSArray *existing = [controller toolbarItems];
		if (existing!=nil)
		{
			for (id current in existing)
			{
				if ([current isKindOfClass:[TiViewProxy class]])
				{
					[(TiViewProxy*)current removeNavBarButtonView];
				}
			}
		}
		BOOL translucent = [TiUtils boolValue:@"translucent" properties:properties def:NO];
		if (items!=nil && [items count] > 0)
		{
			NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[items count]];
			for (TiViewProxy *proxy in items)
			{
				if ([proxy supportsNavBarPositioning])
				{
					// detach existing one
					UIBarButtonItem *item = [proxy barButtonItem];
					[array addObject:item];
				}
				else
				{
					NSString *msg = [NSString stringWithFormat:@"%@ doesn't support positioning on the nav bar",proxy];
					THROW_INVALID_ARG(msg);
				}
			}
			BOOL animated = [TiUtils boolValue:@"animated" properties:properties def:YES];
			[controller setToolbarItems:array animated:animated];
			[navbar setToolbarHidden:NO animated:animated];
			[navbar.toolbar setTranslucent:translucent];
			[array release];
			hasToolbar=YES;
		}
		else
		{
			BOOL animated = [TiUtils boolValue:@"animated" properties:properties def:NO];
			[controller setToolbarItems:nil animated:animated];
			[navbar setToolbarHidden:YES animated:animated];
			[navbar.toolbar setTranslucent:translucent];
			hasToolbar=NO;
		}
	}
	else
	{
		[self replaceValue:[[[TiComplexValue alloc] initWithValue:items properties:properties] autorelease] forKey:@"toolbar" notification:NO];
	}
}

#define SETPROP(m,x) \
{\
  id value = [self valueForKey:m]; \
  if (value!=nil)\
  {\
	[self x:(value==[NSNull null]) ? nil : value];\
  }\
  else{\
	[self replaceValue:nil forKey:m notification:NO];\
  }\
}\

#define SETPROPOBJ(m,x) \
{\
id value = [self valueForKey:m]; \
if (value!=nil)\
{\
if ([value isKindOfClass:[TiComplexValue class]])\
{\
     TiComplexValue *cv = (TiComplexValue*)value;\
     [self x:(cv.value==[NSNull null]) ? nil : cv.value withObject:cv.properties];\
}\
else\
{\
	[self x:(value==[NSNull null]) ? nil : value withObject:nil];\
}\
}\
else{\
[self replaceValue:nil forKey:m notification:NO];\
}\
}\

-(void)viewDidAttach
{
	// we must do this before the tab is loaded for it to repaint correctly
	// we also must do it in tabFocus below so that it reverts when we push off the stack
	SETPROP(@"barColor",setBarColor);
	[super viewDidAttach];
}

-(void)setupWindowDecorations
{
	if (navbar!=nil)
	{
		[navbar setToolbarHidden:!hasToolbar animated:YES];
	}
	
	SETPROP(@"title",setTitle);
	SETPROP(@"titlePrompt",setTitlePrompt);
	SETPROP(@"titleImage",setTitleImage);
	SETPROP(@"titleControl",setTitleControl);
	SETPROP(@"barColor",setBarColor);
	SETPROP(@"translucent",setTranslucent);
	SETPROPOBJ(@"leftNavButton",setLeftNavButton);
	SETPROPOBJ(@"rightNavButton",setRightNavButton);
	SETPROPOBJ(@"toolbar",setToolbar);
	
	id navBarHidden = [self valueForKey:@"navBarHidden"];
	if (navBarHidden!=nil)
	{
		id properties = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"animated"]];
		if ([TiUtils boolValue:navBarHidden])
		{
			[self hideNavBar:properties];
		}
		else
		{
			[self showNavBar:properties];
		}
	}
}

-(void)_tabFocus
{
	if (focused==NO)
	{
		[self setupWindowDecorations];
		if ([self _hasListeners:@"focus"])
		{
			[self fireEvent:@"focus" withObject:nil];
		}
	}
	[super _tabFocus];
}

-(void)_tabBlur
{
	if (focused)
	{
		if ([self _hasListeners:@"blur"])
		{
			[self fireEvent:@"blur" withObject:nil];
		}
	}
	[super _tabBlur];
}


@end
