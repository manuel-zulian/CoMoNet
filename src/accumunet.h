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

bool isAdmin(const char* username, const char* witness);

int cb(unsigned char *dst, int len, void* dat);

int mapToPrime(uint256* prime_image, const std::string username);

mp_int uint256tomp_int(uint256* src);

uint256 mp_intTouint256(mp_int* src);

void test1();

#endif /* defined(__accomunet__accumunet__) */