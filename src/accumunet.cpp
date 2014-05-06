//
//  accumunet.cpp
//  accomunet
//
//  Created by Andrea Passaglia on 13.04.14.
//  Copyright (c) 2014 Andrea Passaglia. All rights reserved.
//

#include "accumunet.h"

#include "main.h"
#include "init.h"
#include "base58.h"
#include "bitcoinrpc.h"
#include "twister.h"

#include <cstdlib>
#include <openssl/sha.h>
#include <random>
#include <algorithm>
#include "libtorrent/include/libtorrent/peer_id.hpp"
#include "libtorrent/include/libtorrent/hasher.hpp"
#include "libtorrent/include/libtorrent/tommath.h"
#include "libtorrent/entry.hpp"
#include "libtorrent/session.hpp"

extern libtorrent::session *ses;
const char* admin_str = "_admin_";	///< special username representing users
									///< with special rights
mp_int last_accumulator_cache = {};
// TODO: potrebbe diventare una mappa in cui ad ogni "gruppo"
// associo una cache del suo accumulatore.

//uint256 A = uint256(string("10000000000000000000000000"));
//uint256 B = uint256(string("ffffffffffffffffffffffffffffffffffffffffffffffffff"));

bool isAdmin(const char* username) {
	// TODO: should take the witness from the dht
	// for now is not implemented
	CKeyID keyid;
	pwalletMain->GetKeyIdFromUsername(username, keyid);
	string witness = pwalletMain->mapKeyMetadata[keyid].witness;
	return isAdmin(username, witness.c_str());
}

bool isAdmin(const char* username, const char* witness) {
	std::string username_str(username);
	CTransaction txOut;
	uint256 hashBlock;
	
	if (!GetTransaction(username_str, txOut, hashBlock)) {
		printf( RED "Not only this is not an admin, this username is not even in the chain" RESET "\n");
		return false;
	}
	
	// TODO: decidere quando usare la cache invece di effettuare una nuova query
	// magari aggiungendo un nuovo argomento: force_update
	bool force_update = true;
	if (force_update || mp_iszero(&last_accumulator_cache)) {
		updateAccumulator();
	}
			
	// now I know that the specified user is registered and
	// I got his witness, I have the last accumulator for
	// admins, I have to actually check if the user is in
	// the accumulator
	
	mp_int prime_image;
	mp_init(&prime_image);
	mapToPrime(&prime_image, username_str);
	
	mp_int modulo;
	mp_init(&modulo);
	mp_read_radix(&modulo, "625db8b14abe99dd61d65eb05742e10916148354c764b58d6f0e84dda9fa9b77", 16);
		
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
	mp_tohex(&last_accumulator_cache, last_h);
	printf( RED "%s to the %s modulo %s = %s" RESET "\n", witness_h, prime_h, modulo_h, result_h);
	
	// qui controlla se result è uguale all'accumulatore
	
	int cmp_result = mp_cmp(&result, &last_accumulator_cache);
	bool ret = (cmp_result == MP_EQ) ? true : false;
	printf( RED "the last accumulator was %s so the result is %d" RESET "\n", last_h, (int)ret);
	return ret;
}

int updateAccumulator() {
	CTransaction txAccumulator;
	uint256 acc_hashBlock;
	
	if (!GetTransaction(admin_str, txAccumulator, acc_hashBlock)) {
		printf( RED "Can't retrieve the accumulator, aborting" RESET "\n");
		return ACC_ERROR;
	}
	
	mp_int new_acc;
	mp_init(&new_acc);
	
	std::vector< std::vector<unsigned char> > vAccData;
	if( txAccumulator.accumulator.ExtractPushData(vAccData) ) {
		std::vector<unsigned char> vch = vAccData[0];
		if (mp_iszero(&last_accumulator_cache))
			mp_init(&last_accumulator_cache);
		mp_read_unsigned_bin(&new_acc, vch.data(), vch.end()-vch.begin());
		if (mp_cmp(&last_accumulator_cache, &new_acc) == MP_EQ) {
			return ACC_UNCHANGED;
		} else {
			mp_copy(&new_acc, &last_accumulator_cache);
			return ACC_CHANGED;
		}
	} else {
		printf( RED "Can't decode the accumulator, aborting" RESET "\n");
		return ACC_ERROR;
	}
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

Value addwitnesstouser(const Array& params, bool fHelp)
{
	if (fHelp || params.size() != 2) {
		throw runtime_error(
							"addwitnesstouser <username> <new-witness>\n"
							"Update the wallet with the new witness for the user.");
	}
	
	if (params[0].type() != str_type)
		throw JSONRPCError(RPC_INVALID_PARAMETER, "username must be string");
    string username = params[0].get_str();
	if (params[1].type() != str_type)
		throw JSONRPCError(RPC_INVALID_PARAMETER, "witness must be string");
    string witness = params[1].get_str();
	
	libtorrent::entry v = witness; // TODO: [AP] ovviamente ci andrebbe anche la firma!
	
	// publish witness to dht
	ses->dht_putData(username, string("witness"), RES_T_SINGLE,
                     v, username, GetAdjustedTime(), 0); ///<-- [AP] se abbiamo il tempo k può essere 0?
	
	if (!pwalletMain->AddWitnessTo(username, witness))
		throw runtime_error(
						   "addwitnesstouser() : could not addWitnessTo\n");
	return witness;
}