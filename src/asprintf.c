/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int
asprintf(char **strp, const char *fmt, ...)
{
	int size;
	va_list args;

	va_start(args, fmt);

	if ((size = vsnprintf(NULL, 0, fmt, args)) < 0)
		return size;
	if ((*strp = malloc((size_t)size + 1)) == NULL)
		return -1;

	return vsnprintf(*strp, (size_t)size + 1, fmt, args);
}
