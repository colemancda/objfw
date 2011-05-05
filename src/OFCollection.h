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

#import "OFEnumerator.h"

/**
 * \brief A protocol with methods common for all collections.
 */
@protocol OFCollection <OFObject>
#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t count;
#endif

/**
 * \brief Returns the number of objects in the collection.
 *
 * \return The number of objects in the collection
 */
- (size_t)count;

/**
 * \brief Returns an OFEnumerator to enumerate through all objects of the
 *	  collection.
 *
 * \returns An OFEnumerator to enumerate through all objects of the collection
 */
- (OFEnumerator*)objectEnumerator;

/**
 * \brief Checks whether the collection contains an object equal to the
 *	  specified object.
 *
 * \param The object which is checked for being in the collection
 * \return A boolean whether the collection contains the specified object
 */
- (BOOL)containsObject: (id)object;

/**
 * \brief Checks whether the collection contains an object with the specified
 *	  address.
 *
 * \param The object which is checked for being in the collection
 * \return A boolean whether the collection contains an object with the
 *	   specified address.
 */
- (BOOL)containsObjectIdenticalTo: (id)object;
@end
