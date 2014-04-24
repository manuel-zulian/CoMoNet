//
//  accumunet.cpp
//  accomunet
//
//  Created by Andrea Passaglia on 13.04.14.
//  Copyright (c) 2014 Andrea Passaglia. All rights reserved.
//

#include "accumunet.h"

#include "main.h"
#include "base58.h"
#include "bitcoinrpc.h"

#include <cstdlib>
#include <openssl/sha.h>
#include <random>
#include <algorithm>
#include "../libtorrent/include/libtorrent/peer_id.hpp"
#include "../libtorrent/include/libtorrent/hasher.hpp"
#include "../libtorrent/include/libtorrent/tommath.h"

const char* admin_str = "_admin_";	///< special username representing users
									///< with special rights
//uint256 A = uint256(string("10000000000000000000000000"));
//uint256 B = uint256(string("ffffffffffffffffffffffffffffffffffffffffffffffffff"));

bool isAdmin(const char* username) {
	// TODO: should take the witness from the wallet
	// for now is not implemented
	if (!strncmp(username, "utente1", 7)) {
		return isAdmin(username, "274468099e0dd55ba713964ef7e3e9615ee105a80c912e5eb9ac1e1713");
	} else if (!strncmp(username, "utente2", 7)) {
		return isAdmin(username, "5dc3a454041473865172530bc232161889a06c5dcb460810a53bddc4cd");
	} else if (!strncmp(username, "utente3", 7)) {
		return isAdmin(username, "5237fce1af54c2895cddf5b3bff63f9dab0c538b3c432778b48940605a");
	} else {
		cout << "not implemented";
		return false;
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
	
	mp_int accum;
	mp_init(&accum);
	
	std::vector< std::vector<unsigned char> > vAccData;
    if( txAccumulator.accumulator.ExtractPushData(vAccData) ) {
		std::vector<unsigned char> vch = vAccData[0];
		mp_read_unsigned_bin(&accum, vch.data(), vch.end()-vch.begin());
    } else {
		// TODO: gestione errori
	}
	
	
	// now I know that the specified user is registered and
	// I got his witness, I have the last accumulator for
	// admins, I have to actually check if the user is in
	// the accumulator
	
	//string u_str("32bd4e6bcb51878e3cd48e3984f73406eeaaed4278dfde9153b2611930");
	
	mp_int prime_image;
	mp_init(&prime_image);
	mapToPrime(&prime_image, username_str);
	
	mp_int modulo;
	mp_init(&modulo);
	mp_read_radix(&modulo, "723729e19858d97387306afa280dcdc6274f024078dde94f12ff7842bd", 16);
		
	mp_int witness_int;
	mp_init(&witness_int);
	mp_read_radix(&witness_int, witness, 16);
	
	mp_int result;
	mp_init(&result);
	mp_exptmod_fast(&witness_int, &prime_image, &modulo, &result, 0);
	char *witness_h = (char*)malloc(65);
	char *prime_h = (char*)malloc(65);
	char *modulo_h = (char*)malloc(65);
	char *result_h = (char*)malloc(65);
	char *last_h = (char*)malloc(65);
	mp_tohex(&witness_int, witness_h);
	mp_tohex(&prime_image, prime_h);
	mp_tohex(&modulo, modulo_h);
	mp_tohex(&result, result_h);
	mp_tohex(&accum, last_h);
	printf( RED "%s to the %s modulo %s = %s" RESET "\n", witness_h, prime_h, modulo_h, result_h);
	
	// qui controlla se result è uguale all'accumulatore
	
	int cmp_result = mp_cmp(&result, &accum);
	bool ret = (cmp_result == MP_EQ) ? true : false;
	printf( RED "the last accumulator was %s so the result is %d" RESET "\n", last_h, (int)ret);
	return ret;
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
	unsigned seed = static_cast<unsigned>(hash.Get64());
	std::minstd_rand0 generator (seed);
	
	// 3) prime generation
	const int dim_bit = 256; // dimensione numero primo in bit
	const int safetyp = 8; // parametro per il miller-rabin (?)
	mp_prime_random_ex(prime_image, safetyp, dim_bit, LTM_PRIME_SAFE, cb, &generator);
	return 0;
}

/**
 dest must be initialized, may actually not work!
 */
bool uint256tomp_int(mp_int* dest, uint256* src){
	mp_read_unsigned_bin(dest, src->begin(), src->size()); //?? size()??
	return true;
}

bool mp_intTouint256(uint256* dest, mp_int* src){
	mp_to_unsigned_bin(src, dest->begin());
	return true;
}

using namespace std;
using namespace json_spirit;

extern vector<unsigned char> ParseHexV(const Value& v, string strName);
Value createrawaccumulatortransaction(const Array& params, bool fHelp)
{
	if (fHelp || params.size() != 3)
        throw runtime_error(
							"createrawaccumulatortransaction <username> <pubKey> <accumulator>\n"
							"Create a transaction registering a new group username\n"
							"pubKey and accumulator must be in hex format\n"
							"Returns hex-encoded raw transaction.\n"
							"it is not stored in the wallet or transmitted to the network.");
	
    CTransaction rawTx; // transazione da compilare
	
    if (params[0].type() != str_type)
		throw JSONRPCError(RPC_INVALID_PARAMETER, "username must be string");
    string username = params[0].get_str();
    rawTx.userName = CScript() << vector<unsigned char>((const unsigned char*)username.data(), (const unsigned char*)username.data() + username.size());
	
	/// v0.1 per adesso tutto questo codice per la pubKey non serve a niente
    vector<unsigned char> vch(ParseHexV(params[1], "pubkey"));
	//CPubKey pubkey(vch);
    //if( !pubkey.IsValid() )
	//	throw JSONRPCError(RPC_INTERNAL_ERROR, "pubkey is not valid");
	
    rawTx.pubKey << vch;
    //if( params.size() > 2) {
    //    vector<unsigned char> vchSign(ParseHexV(params[2], "signedByOldKey"));
    //    rawTx.pubKey << vchSign;
    //}
	
	vector<unsigned char> ach(ParseHexV(params[2], "accumulator"));
	rawTx.accumulator = CScript() << ach;
	
    DoTxProofOfWork(rawTx);
	
    CDataStream ss(SER_NETWORK, PROTOCOL_VERSION);
    ss << rawTx;
    return HexStr(ss.begin(), ss.end());
}