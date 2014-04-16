//
//  accumunet.cpp
//  accomunet
//
//  Created by Andrea Passaglia on 13.04.14.
//  Copyright (c) 2014 Andrea Passaglia. All rights reserved.
//

#include "accumunet.h"

#include "main.h"

#include <cstdlib>
#include <openssl/sha.h>
#include "../libtorrent/include/libtorrent/peer_id.hpp"
#include "../libtorrent/include/libtorrent/hasher.hpp"
#include "../libtorrent/include/libtorrent/tommath.h"

const char* admin_str = "_admin_";	///< special username representing users
									///< with special rights
uint256 n = uint256(string("723729e19858d97387306afa280dcdc6274f024078dde94f12ff7842bd"));
uint256 u = uint256(string("32bd4e6bcb51878e3cd48e3984f73406eeaaed4278dfde9153b2611930"));
uint256 A = uint256(string("10000000000000000000000000"));
uint256 B = uint256(string("ffffffffffffffffffffffffffffffffffffffffffffffffff"));

bool isAdmin(const char* username, const char* witness) {
	std::string const username_str = username;
	CTransaction txOut;
	uint256 hashBlock;
	
	if (!GetTransaction(username_str, txOut, hashBlock)) {
		printf( RED "Not only this is not an admin, this username is not even in the chain" RESET "\n");
		return false;
	}
	
	CTransaction txAccumulator;
	uint256 acc_hashBlock;
	
	if (!GetTransaction(admin_str, txAccumulator, acc_hashBlock)) {
		printf( RED "Can't retrieve the accumulator, aborting" RESET "\n");
		return false;
	}
	
	uint256 lastAccumulator(txAccumulator.accumulator.ExtractSmallString());
	
	// now I know that the specified user is registered and
	// I got his witness, I have the last accumulator for
	// admins, I have to actually check if the user is in
	// the accumulator
	
	uint256 prime_image;
	int err = mapToPrime(&prime_image, username_str);
	mp_int prime_user = uint256tomp_int(&prime_image);
	mp_int modulo = uint256tomp_int(&n);
	mp_int accum = uint256tomp_int(&lastAccumulator);
	mp_int result;
	mp_init(&result);
	mp_exptmod_fast(&accum, &prime_user, &modulo, &result, 0);
	// qui controlla se result è uguale all'accumulatore
	return false;
}

int cb(unsigned char *dst, int len, void* dat) {
	dst = (unsigned char*) dat;
	return 0;
}

int mapToPrime(uint256* prime_image, const std::string username) {
    libtorrent::sha1_hash h = libtorrent::hasher(username.c_str(),username.length()).final();
	mp_int mapped_prime;
	mp_init(&mapped_prime);
	const int dim_byte = 32; // dimensione numero primo in byte
	mp_prime_random(&mapped_prime, 5, dim_byte, 0, cb, &h[0]);
	char bin_mapped_prime[32];
	mp_tohex(&mapped_prime, bin_mapped_prime);
	prime_image->SetHex(bin_mapped_prime);
	return 0;
}

mp_int uint256tomp_int(uint256* src){
	mp_int ret;
	mp_init(&ret);
	std::string hex_str = src->GetHex();
	mp_read_radix(&ret, hex_str.c_str(), 16);
	return ret;
}

uint256 mp_intTouint256(mp_int* src){
	char hex_str[32];
	mp_tohex(src, hex_str);
	uint256 ret;
	ret.SetHex(hex_str);
	return ret;
}

void test1() {
	std::cout << "hello world";
	exit(0);
}