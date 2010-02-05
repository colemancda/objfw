/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "macros.h"

#if defined(OF_THREADS) && !defined(OF_HAVE_GCC_ATOMIC_OPS) && \
    !defined(OF_HAVE_LIBKERN_OSATOMIC_H)
# error No atomic operations available!
#endif

#ifdef OF_HAVE_LIBKERN_OSATOMIC_H
# include <libkern/OSAtomic.h>
#endif

static OF_INLINE int32_t
of_atomic_add_32(volatile int32_t *p, int32_t i)
{
#if !defined(OF_THREADS)
	return (*p += i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, i);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicAdd32Barrier(i, p);
#endif
}

static OF_INLINE int32_t
of_atomic_sub_32(volatile int32_t *p, int32_t i)
{
#if !defined(OF_THREADS)
	return (*p -= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, i);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicAdd32Barrier(-i, p);
#endif
}

static OF_INLINE int32_t
of_atomic_inc_32(volatile int32_t *p)
{
#if !defined(OF_THREADS)
	return ++*p;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_add_and_fetch(p, 1);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicIncrement32Barrier(p);
#endif
}

static OF_INLINE int32_t
of_atomic_dec_32(volatile int32_t *p)
{
#if !defined(OF_THREADS)
	return --*p;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_sub_and_fetch(p, 1);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicDecrement32Barrier(p);
#endif
}

static OF_INLINE uint32_t
of_atomic_or_32(volatile uint32_t *p, uint32_t i)
{
#if !defined(OF_THREADS)
	return (*p |= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_or_and_fetch(p, i);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicOr32Barrier(i, p);
#endif
}

static OF_INLINE uint32_t
of_atomic_and_32(volatile uint32_t *p, uint32_t i)
{
#if !defined(OF_THREADS)
	return (*p &= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_and_and_fetch(p, i);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicAnd32Barrier(i, p);
#endif
}

static OF_INLINE uint32_t
of_atomic_xor_32(volatile uint32_t *p, uint32_t i)
{
#if !defined(OF_THREADS)
	return (*p ^= i);
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_xor_and_fetch(p, i);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicXor32Barrier(i, p);
#endif
}

static OF_INLINE BOOL
of_atomic_cmpswap_32(volatile int32_t *p, int32_t o, int32_t n)
{
#if !defined(OF_THREADS)
	if (*p == o) {
		*p = n;
		return YES;
	}

	return NO;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicCompareAndSwap32Barrier(o, n, p);
#endif
}

static OF_INLINE BOOL
of_atomic_cmpswap_ptr(void* volatile *p, void *o, void *n)
{
#if !defined(OF_THREADS)
	if (*p == o) {
		*p = n;
		return YES;
	}

	return NO;
#elif defined(OF_HAVE_GCC_ATOMIC_OPS)
	return __sync_bool_compare_and_swap(p, o, n);
#elif defined(OF_HAVE_LIBKERN_OSATOMIC_H)
	return OSAtomicCompareAndSwapPtrBarrier(o, n, p);
#endif
}
