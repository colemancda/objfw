/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFDataArray.h"
#import "OFString.h"
#import "OFMD5Hash.h"
#import "OFSHA1Hash.h"
#import "OFAutoreleasePool.h"

int _OFDataArray_Hashing_reference;

@implementation OFDataArray (Hashing)
- (OFString*)MD5Hash
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMD5Hash *hash = [OFMD5Hash MD5Hash];
	uint8_t *digest;
	char ret_c[OF_MD5_DIGEST_SIZE * 2];
	size_t i;

	[hash updateWithBuffer: data
			ofSize: count * itemSize];
	digest = [hash digest];

	for (i = 0; i < OF_MD5_DIGEST_SIZE; i++) {
		uint8_t high, low;

		high = digest[i] >> 4;
		low  = digest[i] & 0x0F;

		ret_c[i * 2] = (high > 9 ? high - 10 + 'a' : high + '0');
		ret_c[i * 2 + 1] = (low > 9 ? low - 10 + 'a' : low + '0');
	}

	[pool release];

	return [OFString stringWithCString: ret_c
				    length: 32];
}

- (OFString*)SHA1Hash
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFMD5Hash *hash = [OFSHA1Hash SHA1Hash];
	uint8_t *digest;
	char ret_c[OF_SHA1_DIGEST_SIZE * 2];
	size_t i;

	[hash updateWithBuffer: data
			ofSize: count * itemSize];
	digest = [hash digest];

	for (i = 0; i < OF_SHA1_DIGEST_SIZE; i++) {
		uint8_t high, low;

		high = digest[i] >> 4;
		low  = digest[i] & 0x0F;

		ret_c[i * 2] = (high > 9 ? high - 10 + 'a' : high + '0');
		ret_c[i * 2 + 1] = (low > 9 ? low - 10 + 'a' : low + '0');
	}

	[pool release];

	return [OFString stringWithCString: ret_c
				    length: 40];
}
@end