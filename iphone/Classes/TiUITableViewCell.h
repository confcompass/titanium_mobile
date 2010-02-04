/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <UIKit/UIKit.h>

@class CellDataWrapper;

@interface TiUITableViewCell : UITableViewCell 
{
	CellDataWrapper * dataWrapper;
	NSMutableArray * layoutViewsArray;
	id lastLayoutArray;	//Is not retained, and kept only as a memory value, NOT to be used as an object.
	NSString * clickedName;
	NSMutableSet * watchedBlobs;
	
	UILabel * valueLabel;
	UIWebView * htmlView;
	NSString * htmlString;
}

@property(nonatomic,readwrite,retain) CellDataWrapper * dataWrapper;
@property(nonatomic,readwrite,copy) NSString * clickedName;
@property(nonatomic,readonly)	UILabel * valueLabel;

#pragma mark Internal

- (void)flushBlobWatching;
- (void)updateDefaultLayoutViews:(BOOL) hilighted;
- (void)refreshFromDataWrapper;
- (void)updateDataInSubviews:(BOOL)hilighted;


@end
