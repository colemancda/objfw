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

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

#import "macros.h"
#import "resolver.h"

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
# include "OFMutex.h"
#endif

#import "OFAddressTranslationFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"
#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
# import "OFLockFailedException.h"
# import "OFUnlockFailedException.h"
#endif

#import "socket_helpers.h"

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
static of_mutex_t mutex;

static void __attribute__((constructor))
init(void)
{
	if (!of_mutex_new(&mutex))
		@throw [OFInitializationFailedException exception];
}
#endif

of_resolver_result_t**
of_resolve_host(OFString *host, uint16_t port, int type)
{
	of_resolver_result_t **ret, **retIter;
	of_resolver_result_t *results, *resultsIter;
	size_t count;
#ifdef HAVE_THREADSAFE_GETADDRINFO
	struct addrinfo hints = { 0 }, *res, *res0;
	char portCString[7];

	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = type;
	hints.ai_flags = AI_NUMERICSERV;
	snprintf(portCString, 7, "%" PRIu16, port);

	if (getaddrinfo([host UTF8String], portCString, &hints, &res0))
		@throw [OFAddressTranslationFailedException
		    exceptionWithHost: host];

	count = 0;
	for (res = res0; res != NULL; res = res->ai_next)
		count++;

	if (count == 0) {
		freeaddrinfo(res0);
		@throw [OFAddressTranslationFailedException
		    exceptionWithHost: host];
	}

	if ((ret = calloc(count + 1, sizeof(*ret))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: (count + 1) * sizeof(*ret)];

	if ((results = malloc(count * sizeof(*results))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: count * sizeof(*results)];

	for (retIter = ret, resultsIter = results, res = res0;
	    res != NULL; retIter++, resultsIter++, res = res->ai_next) {
		resultsIter->family = res->ai_family;
		resultsIter->type = res->ai_socktype;
		resultsIter->protocol = res->ai_protocol;
		resultsIter->address = res->ai_addr;
		resultsIter->addressLength = res->ai_addrlen;
		resultsIter->private = NULL;

		*retIter = resultsIter;
	}
	*retIter = NULL;

	ret[0]->private = res0;
#else
	struct hostent *he;
	in_addr_t s_addr;
	char **ip;
	struct sockaddr_in *addrs, *addrsIter;

	/*
	 * If the host is an IP address, don't try resolving it.
	 * On the Wii for example, the resolver will return an error if you
	 * specify an IP address.
	 */
	if ((s_addr = inet_addr([host UTF8String])) != INADDR_NONE) {
		of_resolver_result_t *tmp;
		struct sockaddr_in *addr;

		if ((ret = calloc(2, sizeof(*ret))) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: 2 * sizeof(*ret)];

		if ((tmp = malloc(sizeof(*tmp))) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: sizeof(*tmp)];

		if ((addr = calloc(1, sizeof(*addr))) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: sizeof(*addr)];

		addr->sin_family = AF_INET;
		addr->sin_port = OF_BSWAP16_IF_LE(port);
		addr->sin_addr.s_addr = s_addr;

		tmp->family = AF_INET;
		tmp->type = type;
		tmp->protocol = 0;
		tmp->address = (struct sockaddr*)addr;
		tmp->addressLength = sizeof(*addr);

		ret[0] = tmp;
		ret[1] = NULL;

		return ret;
	}

# ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];
# endif

	if ((he = gethostbyname([host UTF8String])) == NULL ||
	    he->h_addrtype != AF_INET) {
# ifdef OF_HAVE_THREADS
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
# endif

		@throw [OFAddressTranslationFailedException
		    exceptionWithHost: host];
	}

	count = 0;
	for (ip = he->h_addr_list; *ip != NULL; ip++)
		count++;

	if (count == 0)
		@throw [OFAddressTranslationFailedException
		    exceptionWithHost: host];

	if ((ret = calloc(count + 1, sizeof(*ret))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: (count + 1) * sizeof(*ret)];

	if ((results = malloc(count * sizeof(*results))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: count * sizeof(*results)];

	if ((addrs = calloc(count, sizeof(*addrs))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: count * sizeof(*addrs)];

	for (retIter = ret, resultsIter = results, addrsIter = addrs,
	    ip = he->h_addr_list; *ip != NULL; retIter++, resultsIter++,
	    addrsIter++, ip++) {
		addrsIter->sin_family = he->h_addrtype;
		addrsIter->sin_port = OF_BSWAP16_IF_LE(port);

		if (he->h_length > sizeof(addrsIter->sin_addr.s_addr))
			@throw [OFOutOfRangeException exception];

		memcpy(&addrsIter->sin_addr.s_addr, *ip, he->h_length);

		resultsIter->family = he->h_addrtype;
		resultsIter->type = type;
		resultsIter->protocol = 0;
		resultsIter->address = (struct sockaddr*)addrsIter;
		resultsIter->addressLength = sizeof(*addrsIter);

		*retIter = resultsIter;
	}

# ifdef OF_HAVE_THREADS
	if (!of_mutex_unlock(&mutex))
		@throw [OFUnlockFailedException exception];
# endif
#endif

	return ret;
}

OFString*
of_address_to_string(struct sockaddr *address, socklen_t addressLength)
{
#ifdef HAVE_THREADSAFE_GETADDRINFO
	char host[NI_MAXHOST];

	if (getnameinfo(address, addressLength, host, NI_MAXHOST, NULL, 0,
	    NI_NUMERICHOST | NI_NUMERICSERV))
		@throw [OFAddressTranslationFailedException exception];

	return [OFString stringWithUTF8String: host];
#else
	OFString *ret;
	char *host;

	if (address->sa_family != AF_INET)
		@throw [OFInvalidArgumentException exception];

# if OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];
# endif

	host = inet_ntoa(((struct sockaddr_in*)(void*)address)->sin_addr);
	if (host == NULL)
		@throw [OFAddressTranslationFailedException exception];

	ret = [OFString stringWithUTF8String: host];

# if OF_HAVE_THREADS
	if (!of_mutex_unlock(&mutex))
		@throw [OFUnlockFailedException exception];
# endif

	return ret;
#endif
}

void
of_resolver_free(of_resolver_result_t **results)
{
#ifdef HAVE_THREADSAFE_GETADDRINFO
	freeaddrinfo(results[0]->private);
#else
	free(results[0]->address);
#endif
	free(results[0]);
	free(results);
}