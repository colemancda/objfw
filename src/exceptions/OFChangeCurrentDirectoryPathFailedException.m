/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "config.h"

#import "OFChangeCurrentDirectoryPathFailedException.h"
#import "OFString.h"

@implementation OFChangeCurrentDirectoryPathFailedException
+ (instancetype)exceptionWithPath: (OFString*)path
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path
				     errNo: errNo] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPath: (OFString*)path
	 errNo: (int)errNo
{
	self = [super init];

	@try {
		_path = [path copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_path release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"Failed to change the current directory path to %@: %@",
	    _path, of_strerror(_errNo)];
}

- (OFString*)path
{
	OF_GETTER(_path, true)
}

- (int)errNo
{
	return _errNo;
}
@end
