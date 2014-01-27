/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFString.h"

#import "socket.h"

/*! @file */

/*!
 * @brief A struct representing one result from the resolver.
 */
typedef struct of_resolver_result_t {
	int family, type, protocol;
	struct sockaddr *address;
	socklen_t addressLength;
	void *private;
} of_resolver_result_t;

#ifdef __cplusplus
extern "C" {
#endif
/*!
 * @brief Resolves the specified host.
 *
 * @param host The host to resolve
 * @param port The port that should be inserted into the resulting address
 *	       struct
 * @param protocol The protocol that should be inserted into the resulting
 *		   address struct
 *
 * @return An array of results. The list is terminated by NULL and should be
 *	   free'd after use.
 */
extern of_resolver_result_t** of_resolve_host(OFString *host, uint16_t port,
    int protocol);

/*!
 * @brief Converts the specified address to a string.
 *
 * @param address The address to convert to a string
 * @param addressLength The length of the address to convert to a string
 * @return The address as a string
 */
extern OFString* of_address_to_string(struct sockaddr *address,
    socklen_t addressLength);

/*!
 * @brief Frees the results returned by @ref of_resolve_host.
 *
 * @param results The results returned by @ref of_resolve_host
 */
extern void of_resolver_free(of_resolver_result_t **results);
#ifdef __cplusplus
}
#endif