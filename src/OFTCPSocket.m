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

#define __NO_EXT_QNX

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>

#include <assert.h>

#ifndef _WIN32
# include <netinet/in.h>
# include <arpa/inet.h>
# include <netdb.h>
#endif

#import "OFTCPSocket.h"
#import "OFTCPSocket+SOCKS5.h"
#import "OFString.h"

#import "OFAcceptFailedException.h"
#import "OFAlreadyConnectedException.h"
#import "OFAddressTranslationFailedException.h"
#import "OFBindFailedException.h"
#import "OFConnectionFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFListenFailedException.h"
#import "OFNotConnectedException.h"
#import "OFNotImplementedException.h"
#import "OFSetOptionFailedException.h"

#import "macros.h"

#ifndef INVALID_SOCKET
# define INVALID_SOCKET -1
#endif

#if defined(OF_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
# import "OFThread.h"
# import "OFDataArray.h"

static OFMutex *mutex = nil;
#endif

#ifdef _WIN32
# define close(sock) closesocket(sock)
#endif

/* References for static linking */
void _references_to_categories_of_OFTCPSocket(void)
{
	_OFTCPSocket_SOCKS5_reference = 1;
}

static OFString *defaultSOCKS5Host = nil;
static uint16_t defaultSOCKS5Port = 1080;

@implementation OFTCPSocket
#if defined(OF_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
+ (void)initialize
{
	if (self == [OFTCPSocket class])
		mutex = [[OFMutex alloc] init];
}
#endif

+ (void)setSOCKS5Host: (OFString*)host
{
	id old = defaultSOCKS5Host;
	defaultSOCKS5Host = [host copy];
	[old release];
}

+ (OFString*)SOCKS5Host
{
	return [[defaultSOCKS5Host copy] autorelease];
}

+ (void)setSOCKS5Port: (uint16_t)port
{
	defaultSOCKS5Port = port;
}

+ (uint16_t)SOCKS5Port
{
	return defaultSOCKS5Port;
}

- init
{
	self = [super init];

	@try {
		sock = INVALID_SOCKET;
		sockAddr = NULL;
		SOCKS5Host = [defaultSOCKS5Host copy];
		SOCKS5Port = defaultSOCKS5Port;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[SOCKS5Host release];

	[super dealloc];
}

- (void)setSOCKS5Host: (OFString*)host
{
	OF_SETTER(SOCKS5Host, host, YES, YES)
}

- (OFString*)SOCKS5Host
{
	OF_GETTER(SOCKS5Host, YES)
}

- (void)setSOCKS5Port: (uint16_t)port
{
	SOCKS5Port = port;
}

- (uint16_t)SOCKS5Port
{
	return SOCKS5Port;
}

- (void)connectToHost: (OFString*)host
		 port: (uint16_t)port
{
	OFString *destinationHost = host;
	uint16_t destinationPort = port;

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithClass: isa
								socket: self];

	if (SOCKS5Host != nil) {
		/* Connect to the SOCKS5 proxy instead */
		host = SOCKS5Host;
		port = SOCKS5Port;
	}

#ifdef HAVE_THREADSAFE_GETADDRINFO
	struct addrinfo hints, *res, *res0;
	char portCString[7];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	snprintf(portCString, 7, "%" PRIu16, port);

	if (getaddrinfo([host cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    portCString, &hints, &res0))
		@throw [OFAddressTranslationFailedException
		    exceptionWithClass: isa
				socket: self
				  host: host];

	for (res = res0; res != NULL; res = res->ai_next) {
		if ((sock = socket(res->ai_family, res->ai_socktype,
		    res->ai_protocol)) == INVALID_SOCKET)
			continue;

		if (connect(sock, res->ai_addr, res->ai_addrlen) == -1) {
			close(sock);
			sock = INVALID_SOCKET;
			continue;
		}

		break;
	}

	freeaddrinfo(res0);
#else
	BOOL connected = NO;
	struct hostent *he;
	struct sockaddr_in addr;
	char **ip;
# ifdef OF_THREADS
	OFDataArray *addrlist;

	addrlist = [[OFDataArray alloc] initWithItemSize: sizeof(char**)];
	[mutex lock];
# endif

	if ((he = gethostbyname([host cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE])) == NULL) {
# ifdef OF_THREADS
		[addrlist release];
		[mutex unlock];
# endif
		@throw [OFAddressTranslationFailedException
		    exceptionWithClass: isa
				socket: self
				  host: host];
	}

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = of_bswap16_if_le(port);

	if (he->h_addrtype != AF_INET ||
	    (sock = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) {
# ifdef OF_THREADS
		[addrlist release];
		[mutex unlock];
# endif
		@throw [OFConnectionFailedException exceptionWithClass: isa
								socket: self
								  host: host
								  port: port];
	}

# ifdef OF_THREADS
	@try {
		for (ip = he->h_addr_list; *ip != NULL; ip++)
			[addrlist addItem: ip];

		/* Add the terminating NULL */
		[addrlist addItem: ip];
	} @catch (id e) {
		[addrlist release];
		@throw e;
	} @finally {
		[mutex unlock];
	}

	for (ip = [addrlist cArray]; *ip != NULL; ip++) {
# else
	for (ip = he->h_addr_list; *ip != NULL; ip++) {
# endif
		memcpy(&addr.sin_addr.s_addr, *ip, he->h_length);

		if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) == -1)
			continue;

		connected = YES;
		break;
	}

# ifdef OF_THREADS
	[addrlist release];
# endif

	if (!connected) {
		close(sock);
		sock = INVALID_SOCKET;
	}
#endif

	if (sock == INVALID_SOCKET)
		@throw [OFConnectionFailedException exceptionWithClass: isa
								socket: self
								  host: host
								  port: port];

	if (SOCKS5Host != nil)
		[self _SOCKS5ConnectToHost: destinationHost
				      port: destinationPort];
}

- (uint16_t)bindToHost: (OFString*)host
		  port: (uint16_t)port
{
	union {
		struct sockaddr_storage storage;
		struct sockaddr_in in;
		struct sockaddr_in6 in6;
	} addr;
	socklen_t addrLen;

	if (sock != INVALID_SOCKET)
		@throw [OFAlreadyConnectedException exceptionWithClass: isa
								socket: self];

	if (SOCKS5Host != nil)
		@throw [OFNotImplementedException exceptionWithClass: isa
							    selector: _cmd];

#ifdef HAVE_THREADSAFE_GETADDRINFO
	struct addrinfo hints, *res;
	char portCString[7];

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	snprintf(portCString, 7, "%" PRIu16, port);

	if (getaddrinfo([host cStringWithEncoding: OF_STRING_ENCODING_NATIVE],
	    portCString, &hints, &res))
		@throw [OFAddressTranslationFailedException
		    exceptionWithClass: isa
				socket: self
				  host: host];

	if ((sock = socket(res->ai_family, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException exceptionWithClass: isa
							  socket: self
							    host: host
							    port: port];

	if (bind(sock, res->ai_addr, res->ai_addrlen) == -1) {
		freeaddrinfo(res);
		close(sock);
		sock = INVALID_SOCKET;
		@throw [OFBindFailedException exceptionWithClass: isa
							  socket: self
							    host: host
							    port: port];
	}

	freeaddrinfo(res);
#else
	struct hostent *he;

# ifdef OF_THREADS
	[mutex lock];
# endif

	if ((he = gethostbyname([host cStringWithEncoding:
	    OF_STRING_ENCODING_NATIVE])) == NULL) {
# ifdef OF_THREADS
		[mutex unlock];
# endif
		@throw [OFAddressTranslationFailedException
		    exceptionWithClass: isa
				socket: self
				  host: host];
	}

	memset(&addr, 0, sizeof(addr));
	addr.in.sin_family = AF_INET;
	addr.in.sin_port = of_bswap16_if_le(port);

	if (he->h_addrtype != AF_INET || he->h_addr_list[0] == NULL) {
# ifdef OF_THREADS
		[mutex unlock];
# endif
		@throw [OFAddressTranslationFailedException
		    exceptionWithClass: isa
				socket: self
				  host: host];
	}

	memcpy(&addr.in.sin_addr.s_addr, he->h_addr_list[0], he->h_length);

# ifdef OF_THREADS
	[mutex unlock];
# endif
	if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
		@throw [OFBindFailedException exceptionWithClass: isa
							  socket: self
							    host: host
							    port: port];

	if (bind(sock, (struct sockaddr*)&addr.in, sizeof(addr.in)) == -1) {
		close(sock);
		sock = INVALID_SOCKET;
		@throw [OFBindFailedException exceptionWithClass: isa
							  socket: self
							    host: host
							    port: port];
	}
#endif

	if (port > 0)
		return port;

	addrLen = sizeof(addr.storage);
	if (getsockname(sock, (struct sockaddr*)&addr, &addrLen)) {
		close(sock);
		sock = INVALID_SOCKET;
		@throw [OFBindFailedException exceptionWithClass: isa
							  socket: self
							    host: host
							    port: port];
	}

	if (addr.storage.ss_family == AF_INET)
		return of_bswap16_if_le(addr.in.sin_port);
	if (addr.storage.ss_family == AF_INET6)
		return of_bswap16_if_le(addr.in6.sin6_port);

	close(sock);
	sock = INVALID_SOCKET;
	@throw [OFBindFailedException exceptionWithClass: isa
						  socket: self
						    host: host
						    port: port];
}

- (void)listenWithBackLog: (int)backLog
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithClass: isa
							    socket: self];

	if (listen(sock, backLog) == -1)
		@throw [OFListenFailedException exceptionWithClass: isa
							    socket: self
							   backLog: backLog];

	listening = YES;
}

- (void)listen
{
	if (sock == INVALID_SOCKET)
		@throw [OFNotConnectedException exceptionWithClass: isa
							    socket: self];

	if (listen(sock, 5) == -1)
		@throw [OFListenFailedException exceptionWithClass: isa
							    socket: self
							   backLog: 5];

	listening = YES;
}

- (OFTCPSocket*)accept
{
	OFTCPSocket *newSocket;
	struct sockaddr_storage *addr;
	socklen_t addrLen;
	int newSock;

	newSocket = [[[isa alloc] init] autorelease];
	addrLen = sizeof(struct sockaddr);

	@try {
		addr = [newSocket allocMemoryWithSize: sizeof(struct sockaddr)];
	} @catch (id e) {
		[newSocket release];
		@throw e;
	}

	if ((newSock = accept(sock, (struct sockaddr*)addr,
	    &addrLen)) == INVALID_SOCKET) {
		[newSocket release];
		@throw [OFAcceptFailedException exceptionWithClass: isa
							    socket: self];
	}

	newSocket->sock = newSock;
	newSocket->sockAddr = addr;
	newSocket->sockAddrLen = addrLen;

	return newSocket;
}

- (void)setKeepAlivesEnabled: (BOOL)enable
{
	int v = enable;

	if (setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, (char*)&v, sizeof(v)))
		@throw [OFSetOptionFailedException exceptionWithClass: isa
							       stream: self];
}

- (OFString*)remoteAddress
{
	char *host;

	if (sockAddr == NULL || sockAddrLen == 0)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

#ifdef HAVE_THREADSAFE_GETADDRINFO
	host = [self allocMemoryWithSize: NI_MAXHOST];

	@try {
		if (getnameinfo((struct sockaddr*)sockAddr, sockAddrLen, host,
		    NI_MAXHOST, NULL, 0, NI_NUMERICHOST))
			@throw [OFAddressTranslationFailedException
			    exceptionWithClass: isa];

		return [OFString stringWithCString: host
					  encoding: OF_STRING_ENCODING_NATIVE];
	} @finally {
		[self freeMemory: host];
	}
#else
# ifdef OF_THREADS
	[mutex lock];

	@try {
# endif
		host = inet_ntoa(((struct sockaddr_in*)sockAddr)->sin_addr);

		if (host == NULL)
			@throw [OFAddressTranslationFailedException
			    exceptionWithClass: isa];

		return [OFString stringWithCString: host
					  encoding: OF_STRING_ENCODING_NATIVE];
# ifdef OF_THREADS
	} @finally {
		[mutex unlock];
	}
# endif
#endif

	/* Get rid of a warning, never reached anyway */
	assert(0);
}

- (BOOL)isListening
{
	return listening;
}

- (void)close
{
	[super close];

	listening = NO;
	[self freeMemory: sockAddr];
	sockAddr = NULL;
	sockAddrLen = 0;
}
@end
