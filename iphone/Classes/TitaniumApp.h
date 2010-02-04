/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <UIKit/UIKit.h>

#import "TiHost.h"
#import "KrollBridge.h"
#import "XHRBridge.h"
#import "TitaniumViewController.h"

@interface TitaniumApp : TiHost <UIApplicationDelegate> 
{
    UIWindow *window;
	UIImageView *loadView;
	BOOL splashDone;
	
	KrollBridge *kjsBridge;
	XHRBridge *xhrBridge;
	
	NSMutableDictionary *launchOptions;
	NSTimeInterval started;
	
	NSLock *networkActivity;
	int networkActivityCount;
	
	TitaniumViewController *controller;
	NSString *userAgent;
	
	BOOL keyboardShowing;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

+(TitaniumApp*)app;

- (BOOL)isSplashVisible;
-(void)hideSplash:(id)event;

-(void)startNetwork;
-(void)stopNetwork;

-(TitaniumViewController*)controller;
-(void)showModalError:(NSString*)message;

-(void)showModalController:(UIViewController*)controller animated:(BOOL)animated;
-(void)dismissModalController:(BOOL)animated;

-(NSString*)userAgent;

-(BOOL)isKeyboardShowing;

@end

