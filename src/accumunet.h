//
//  accumunet.h
//  accomunet
//
//  Created by Andrea Passaglia on 13.04.14.
//  Copyright (c) 2014 Andrea Passaglia. All rights reserved.
//

#ifndef __accomunet__accumunet__
#define __accomunet__accumunet__

#include "bignum.h"
#include "script.h"
#include "../libtorrent/include/libtorrent/tommath.h"

bool isAdmin(const char* username);

bool isAdmin(const char* username, const char* witness);

int cb(unsigned char *dst, int len, void* dat);

int mapToPrime(mp_int* prime_image, const std::string username);

bool uint256tomp_int(mp_int* dest, uint256* src);

bool mp_intTouint256(uint256* dest, mp_int* src);

void test1();

#endif /* defined(__accomunet__accumunet__) */