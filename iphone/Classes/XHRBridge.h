/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <Foundation/Foundation.h>
#import "Bridge.h"

@class XHRBridge;

@interface TiProtocolHandler : NSURLProtocol
{
}
+ (void) registerSpecialProtocol;
@end

@interface XHRBridge : Bridge
{

}
@end
