/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#import <stdio.h>
#import <stdlib.h>
#import <limits.h>

#import "OFObject.h"
#import "OFExceptions.h"

#define CATCH_EXCEPTION(code, exception)		\
	@try {						\
		code;					\
							\
		puts("NOT CAUGHT!");			\
		return 1;				\
	} @catch (exception *e) {			\
		puts("CAUGHT! Error string was:");	\
		puts([e cString]);			\
		puts("Resuming...");			\
	}

int
main()
{
	OFObject *obj = [OFObject new];
	void *p, *q, *r;

	/* Test freeing memory not allocated by obj */
	puts("Freeing memory not allocated by object (should throw an "
	    "exception)...");
	CATCH_EXCEPTION([obj freeMem: NULL], OFMemNotPartOfObjException)

	/* Test allocating memory */
	puts("Allocating memory through object...");
	p = [obj allocWithSize: 4096];
	puts("Allocated 4096 bytes.");

	/* Test freeing the just allocated memory */
	puts("Freeing just allocated memory...");
	[obj freeMem: p];
	puts("Free'd.");

	/* It shouldn't be recognized as part of our obj anymore */
	puts("Trying to free it again (should throw an exception)...");
	CATCH_EXCEPTION([obj freeMem: p], OFMemNotPartOfObjException)

	/* Test multiple memory chunks */
	puts("Allocating 3 chunks of memory...");
	p = [obj allocWithSize: 4096];
	q = [obj allocWithSize: 4096];
	r = [obj allocWithSize: 4096];
	puts("Allocated 3 * 4096 bytes.");

	/* Free them */
	puts("Now freeing them...");
	[obj freeMem: p];
	[obj freeMem: q];
	[obj freeMem: r];
	puts("Freed them all.");

	/* Try to free again */
	puts("Now trying to free them again...");
	CATCH_EXCEPTION([obj freeMem: p], OFMemNotPartOfObjException)
	CATCH_EXCEPTION([obj freeMem: q], OFMemNotPartOfObjException)
	CATCH_EXCEPTION([obj freeMem: r], OFMemNotPartOfObjException)
	puts("Got all 3!");

	puts("Trying to allocate more memory than possible...");
	CATCH_EXCEPTION(p = [obj allocWithSize: SIZE_MAX], OFNoMemException)

	puts("Allocating 1 byte...");
	p = [obj allocWithSize: 1];

	puts("Trying to resize that 1 byte to more than possible...");
	CATCH_EXCEPTION(p = [obj resizeMem: p
				    toSize: SIZE_MAX],
	    OFNoMemException)

	puts("Trying to resize NULL to 1024 bytes...");
	p = [obj resizeMem: NULL
		    toSize: 1024];
	[obj freeMem: p];

	puts("Trying to resize memory that is not part of object...");
	CATCH_EXCEPTION(p = [obj resizeMem: (void*)1
				    toSize: 1024],
	    OFMemNotPartOfObjException)

	/* TODO: Test if freeing object frees all memory */

	return 0;
}
