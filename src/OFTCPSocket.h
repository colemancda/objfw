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

#include <stdio.h>

/*
 * Headers for UNIX systems
 */
#ifndef _WIN32
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#endif

#import "OFObject.h"
#import "OFStream.h"

/*
 * Headers for Win32
 *
 * These must be imported after objc/Object and thus OFObject!
 */
#ifdef _WIN32
#define _WIN32_WINNT 0x0501
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

/**
 * The OFTCPSocket class provides functions to create and use sockets.
 */
@interface OFTCPSocket: OFObject <OFStream>
{
#ifndef _WIN32
	int		sock;
#else
	SOCKET		sock;
#endif
	struct sockaddr	*saddr;
	socklen_t	saddr_len;
	char		*cache;
	size_t		cache_len;
}

/**
 * \return A new autoreleased OFTCPSocket
 */
+ tcpSocket;

/**
 * Initializes an already allocated OFTCPSocket.
 *
 * \return An initialized OFTCPSocket
 */
- init;

/**
 * Connect the OFTCPSocket to the specified destination.
 *
 * \param host The host or IP to connect to
 * \param port The port of the host to connect to
 */
- connectTo: (const char*)host
     onPort: (uint16_t)port;

/**
 * Bind socket to the specified address and port.
 *
 * \param host The host or IP to bind to
 * \param port The port to bind to
 * \param protocol The protocol to use (AF_INET or AF_INET6)
 */
-    bindOn: (const char*)host
   withPort: (uint16_t)port
  andFamily: (int)family;

/**
 * Listen on the socket.
 *
 * \param backlog Maximum length for the queue of pending connections.
 */
- listenWithBackLog: (int)backlog;

/**
 * Listen on the socket.
 */
- listen;

/**
 * Accept an incoming connection.
 * \return An OFTCPSocket for the accepted connection, which is NOT
 *	   autoreleased!
 */
- (OFTCPSocket*)accept;

/**
 * Read until a newline or \0 occurs.
 *
 * If you want to use readNBytes afterwards again, you have to clear the cache
 * before and optionally get the cache before clearing it!
 *
 * \return The line that was read. Use freeMem: to free it!
 */
- (char*)readLine;

/**
 * Sets a specified pointer to the cache and returns the length of the cache.
 *
 * \param ptr A pointer to a pointer. It will be set to the cache.
 *	      If it is NULL, only the number of bytes in the cache is returned.
 * \return The number of bytes in the cache.
 */
- (size_t)getCache: (char**)ptr;

/**
 * Clears the cache.
 */
- clearCache;

/**
 * Enables/disables non-blocking I/O.
 */
- setBlocking: (BOOL)enable;

/**
 * Enable or disable keep alives for the connection.
 */
- enableKeepAlives: (BOOL)enable;

/**
 * Closes the socket.
 */
- close;
@end
