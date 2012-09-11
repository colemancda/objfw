/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFTimer.h"
#import "OFDate.h"
#import "OFRunLoop.h"

#import "OFInvalidArgumentException.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFTimer
+ scheduledTimerWithTimeInterval: (double)interval
			  target: (id)target
			selector: (SEL)selector
			 repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					   repeats: repeats] autorelease];

	[[OFRunLoop currentRunLoop] addTimer: timer];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ scheduledTimerWithTimeInterval: (double)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (id)object
			 repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object
					   repeats: repeats] autorelease];

	[[OFRunLoop currentRunLoop] addTimer: timer];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ scheduledTimerWithTimeInterval: (double)interval
			  target: (id)target
			selector: (SEL)selector
			  object: (id)object1
			  object: (id)object2
			 repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object1
					    object: object2
					   repeats: repeats] autorelease];

	[[OFRunLoop currentRunLoop] addTimer: timer];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ timerWithTimeInterval: (double)interval
		 target: (id)target
	       selector: (SEL)selector
		repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					   repeats: repeats] autorelease];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ timerWithTimeInterval: (double)interval
		 target: (id)target
	       selector: (SEL)selector
		 object: (id)object
		repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object
					   repeats: repeats] autorelease];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

+ timerWithTimeInterval: (double)interval
		 target: (id)target
	       selector: (SEL)selector
		 object: (id)object1
		 object: (id)object2
		repeats: (BOOL)repeats
{
	void *pool = objc_autoreleasePoolPush();
	OFDate *fireDate = [OFDate dateWithTimeIntervalSinceNow: interval];
	id timer = [[[self alloc] initWithFireDate: fireDate
					  interval: interval
					    target: target
					  selector: selector
					    object: object1
					    object: object2
					   repeats: repeats] autorelease];

	[timer retain];
	objc_autoreleasePoolPop(pool);

	return [timer autorelease];
}

- _initWithFireDate: (OFDate*)fireDate_
	   interval: (double)interval_
	     target: (id)target_
	   selector: (SEL)selector_
	     object: (id)object1_
	     object: (id)object2_
	  arguments: (uint8_t)arguments_
	    repeats: (BOOL)repeats_
{
	self = [super init];

	@try {
		fireDate = [fireDate_ retain];
		interval = interval_;
		target = [target_ retain];
		selector = selector_;
		object1 = [object1_ retain];
		object2 = [object2_ retain];
		arguments = arguments_;
		repeats = repeats_;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFireDate: (OFDate*)fireDate_
	  interval: (double)interval_
	    target: (id)target_
	  selector: (SEL)selector_
	   repeats: (BOOL)repeats_
{
	return [self _initWithFireDate: fireDate_
			      interval: interval_
				target: target_
			      selector: selector_
				object: nil
				object: nil
			     arguments: 0
			       repeats: repeats_];
}

- initWithFireDate: (OFDate*)fireDate_
	  interval: (double)interval_
	    target: (id)target_
	  selector: (SEL)selector_
	    object: (id)object
	   repeats: (BOOL)repeats_
{
	return [self _initWithFireDate: fireDate_
			      interval: interval_
				target: target_
			      selector: selector_
				object: object
				object: nil
			     arguments: 1
			       repeats: repeats_];
}

- initWithFireDate: (OFDate*)fireDate_
	  interval: (double)interval_
	    target: (id)target_
	  selector: (SEL)selector_
	    object: (id)object1_
	    object: (id)object2_
	   repeats: (BOOL)repeats_
{
	return [self _initWithFireDate: fireDate_
			      interval: interval_
				target: target_
			      selector: selector_
				object: object1_
				object: object2_
			     arguments: 2
			       repeats: repeats_];
}

- (void)dealloc
{
	[fireDate release];
	[target release];
	[object1 release];
	[object2 release];

	[super dealloc];
}

- (of_comparison_result_t)compare: (id <OFComparing>)object_
{
	OFTimer *otherTimer;

	if (![object_ isKindOfClass: [OFTimer class]])
		@throw[OFInvalidArgumentException
		    exceptionWithClass: [self class]
			      selector: _cmd];

	otherTimer = (OFTimer*)object_;

	return [fireDate compare: otherTimer->fireDate];
}

- (void)fire
{
	OF_ENSURE(arguments >= 0 && arguments <= 2);

	switch (arguments) {
	case 0:
		[target performSelector: selector];
		break;
	case 1:
		[target performSelector: selector
			     withObject: object1];
		break;
	case 2:
		[target performSelector: selector
			     withObject: object1
			     withObject: object2];
		break;
	}

	if (repeats) {
		OFDate *old = fireDate;
		fireDate = [[OFDate alloc]
		    initWithTimeIntervalSinceNow: interval];
		[old release];

		[[OFRunLoop currentRunLoop] addTimer: self];
	}
}

- (OFDate*)fireDate
{
	return [[fireDate retain] autorelease];
}
@end