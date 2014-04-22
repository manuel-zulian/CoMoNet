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
#include <random>
#include "../libtorrent/include/libtorrent/peer_id.hpp"
#include "../libtorrent/include/libtorrent/hasher.hpp"
#include "../libtorrent/include/libtorrent/tommath.h"

const char* admin_str = "_admin_";	///< special username representing users
									///< with special rights
uint256 n = uint256(string("723729e19858d97387306afa280dcdc6274f024078dde94f12ff7842bd"));
uint256 u = uint256(string("32bd4e6bcb51878e3cd48e3984f73406eeaaed4278dfde9153b2611930"));
uint256 A = uint256(string("10000000000000000000000000"));
uint256 B = uint256(string("ffffffffffffffffffffffffffffffffffffffffffffffffff"));

bool isAdmin(const char* username) {
	// TODO: should take the witness from the wallet
	// for now is not implemented
	if (!strncmp(username, "utente2", 7)) {
		isAdmin(username, "2654a238e9702ad69986fea552a0cd9fe9d0684a32e7454ce8337ca624");
	} else {
		cout << "not implemented";
		exit(1);
	}
}

bool isAdmin(const char* username, const char* witness) { // should take the witness from the wallet actually
	std::string username_str(username);
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
	
	mp_int prime_image;
	mp_init(&prime_image);
	mapToPrime(&prime_image, username_str);
	
	mp_int modulo;
	mp_init(&modulo);
	uint256tomp_int(&modulo, &n);
	
	mp_int accum;
	mp_init(&accum);
	uint256tomp_int(&accum, &lastAccumulator);
	
	mp_int witness_int;
	mp_init(&witness_int);
	mp_read_radix(&witness_int, witness, 16);
	
	mp_int result;
	mp_init(&result);
	mp_exptmod_fast(&witness_int, &prime_image, &modulo, &result, 0);
	
	// qui controlla se result è uguale all'accumulatore
	
	int cmp_result = mp_cmp(&result, &accum);
	return (cmp_result == MP_EQ) ? true : false;
}

int cb(unsigned char *dst, int len, void* dat) {
	std::minstd_rand0* point = (std::minstd_rand0*)dat;
	int i;
	for (i = 0; i < len; i++) {
		dst[i]=static_cast<unsigned char>(point->operator()());
	}
	return i;
}

/**
 prime_image must be initialized
 */
int mapToPrime(mp_int* prime_image, const std::string username) {
	// 1) hashing
    uint256 hash = SerializeHash(username);
	
	// 2) seeding
	unsigned seed = static_cast<unsigned>(h.Get64());
	std::minstd_rand0 generator (seed);
	
	// 3) prime generation
	const int dim_bit = 256; // dimensione numero primo in bit
	const int safetyp = 8; // parametro per il miller-rabin (?)
	mp_prime_random_ex(prime_image, safetyp, dim_bit, LTM_PRIME_SAFE, cb, &generator);
	return 0;
}

/**
 dest must be initialized
 */
bool uint256tomp_int(mp_int* dest, uint256* src){
	mp_read_unsigned_bin(dest, src->begin(), src->size());
	return true;
}

bool mp_intTouint256(uint256* dest, mp_int* src){
	mp_to_unsigned_bin_n(src, dest->begin(), dest->size());
	return true;
}

void test1() {
	isAdmin("utente2", "2654a238e9702ad69986fea552a0cd9fe9d0684a32e7454ce8337ca624");
	exit(0);
}