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
#include "libtorrent/bencode.hpp"

#include <cstdlib>
#include <openssl/sha.h>
//#include <random>
#include <boost/random.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/algorithm/hex.hpp>
#include <algorithm>
#include "libtorrent/entry.hpp"
#include "libtorrent/session.hpp"

using namespace std;
using namespace json_spirit;
using namespace libtorrent;//extern libtorrent::session *ses;
extern boost::shared_ptr<session> m_ses;
const char* admin_str = "_admin_";	///< special username representing users
									///< with special rights
mp_int last_accumulator_cache = {};
// TODO: potrebbe diventare una mappa in cui ad ogni "gruppo"
// associo una cache del suo accumulatore.

//uint256 A = uint256(string("10000000000000000000000000"));
//uint256 B = uint256(string("ffffffffffffffffffffffffffffffffffffffffffffffffff"));

bool isAdmin(const char* username, char* error) {
	*error = NO_ERROR;
	CKeyID keyid;
	string witness;
	if (pwalletMain->GetKeyIdFromUsername(username, keyid))
		witness = pwalletMain->mapKeyMetadata[keyid].witness;
	else {
		// TODO: prima di dare errore dovrebbe almeno
		// provare a cercarlo in un file dove vengono
		// memorizzati gli ultimi witness e poi se anche
		// loro non funzionano magari il client può fare
		// un'altra request se sono datati
		*error = E_MISSING_WITNESS;
		return false;
	}
	return isAdmin(username, witness.c_str(), error);
}

bool isAdmin(const char* username, const char* witness, char* error) {
	*error = NO_ERROR;
	if (string(witness).empty()) {
		*error = E_EMPTY_WITNESS;
		return false;
	}
    printf(YELLOW "%s", username);
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
    CTransaction previousAccumulator;
	CTransaction txAccumulator;
	uint256 acc_hashBlock;

    // Recupera la prima transazione
    string next_try;
    next_try = admin_str + itostr(1);
    printf(RED "\n%s\n", next_try.c_str());
    if (!GetTransaction(next_try, txAccumulator, acc_hashBlock)) {
            printf( RED "Can't retrieve the first accumulator, aborting" RESET "\n");
            return ACC_ERROR;
    }

    // 1024 tentativi è un numero arbitrario
    for(int i = 2; i < 1024; i++) {
        next_try = admin_str + itostr(i);

        CTransaction temp;
        uint256 temp2;

        // Se non lo trova è arrivato all'ultimo, interrompi.
        if (!GetTransaction(next_try, temp, temp2)) {
            break;
        } else {
            previousAccumulator = txAccumulator;
            txAccumulator = temp;
        }
    }

    string dht_address;
    dht_address = boost::algorithm::unhex(txAccumulator.pubKey.ToString());

    /**
     * Recupera il numero di firme necessarie, cioè metà degli utenti
     * nell'accumulatore precedente + 1. Se è la prima transazione, serve l'unanimità.
     * */
    int needed_signatures;
    printf( YELLOW "\nSearching signatures at address: %s\n", dht_address.c_str());
    if(next_try == "_admin_2") {
        printf( YELLOW "\nFirst transaction\n");
        needed_signatures = computeNeededSignatures(dht_address);
    } else {
        printf( YELLOW "\nNot first transaction\n");
        needed_signatures = computeNeededSignatures(dht_address);
    }
    printf( RED "\nNeeds %i valid signatures to accept the current accumulator\n", needed_signatures);

    /**
     * Recupera le firme dalla rete dht.
     */
    Array p;
    p.push_back(dht_address);
    p.push_back("signature");
    p.push_back("s");
    Array result = dhtget(p, false).get_array();

    if(!result.size()) {
        printf( RED "\nNo signatures found\n");
    } else {
        printf( RED "\nSignatures:\n%s\n", result[0]);
    }

    // Verifica le firme.
    for( size_t i = 0; i < result.size(); i++ ) {
        if( result.at(i).type() != obj_type )
            continue;
        Object resDict = result.at(i).get_obj();

        BOOST_FOREACH(const Pair& item, resDict) {
            if( item.name_ == "p" && item.value_.type() == obj_type ) {
                Object pDict = item.value_.get_obj();
                BOOST_FOREACH(const Pair& pitem, pDict) {
                    if( pitem.name_ == "v" && pitem.value_.type() == obj_type ) {
                        Object signatures = pitem.value_.get_obj();

                        //printf( YELLOW "\narrivo qua");

                        BOOST_FOREACH(const Pair& signature_pair, signatures) {
                            string username = signature_pair.name_;
                            string signature = signature_pair.value_.get_str();

                            printf( YELLOW "\nSignature for: %s\n", username.c_str());
                            printf( YELLOW "\nSignature length: %i\n", signature.size());

                            Array temp;
                            temp.push_back(username);
                            temp.push_back(signature);
                            string uppercase_acc = boost::to_upper_copy(txAccumulator.accumulator.ToString());
                            temp.push_back(uppercase_acc);

                            // Qui avviene l'effettiva validazione
                            Value validate = verifymessage(temp, false);
                            bool valid = validate.get_bool();
                            printf( YELLOW "\nValid: %d\n", valid);


                        }
                    }
                }
            }
        }
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

/**
 * Calcola il numero di firme necessarie a considerare valido il prossimo accumulatore.
 * @param dht_address L'indirizzo a cui recuperare le firme dell'accumulatore precedente.
 * @return Il numero di firme necessario a validare l'accumulatore.
 */
int computeNeededSignatures(string dht_address) {
    Array p;
    p.push_back(dht_address);
    p.push_back("signature");
    p.push_back("s");
    Array result = dhtget(p, false).get_array();

    if(!result.size()) {
        printf( RED "\nNo signatures found\n");
    }

    int needed = 0;
    int temp = 0;

    for( size_t i = 0; i < result.size(); i++ ) {
        if( result.at(i).type() != obj_type )
            continue;
        Object resDict = result.at(i).get_obj();

        BOOST_FOREACH(const Pair& item, resDict) {
            if( item.name_ == "p" && item.value_.type() == obj_type ) {
                Object pDict = item.value_.get_obj();
                BOOST_FOREACH(const Pair& pitem, pDict) {
                    if( pitem.name_ == "v" && pitem.value_.type() == obj_type ) {
                        Object signatures = pitem.value_.get_obj();

                        BOOST_FOREACH(const Pair& signature_pair, signatures) {
                            temp++;
                            printf( RED "\nIncrement number of sig\n");
                        }
                    }
                }
            }
        }
    }

    needed = ceil(temp / 2) + 1;

    return needed;
}

/*int cb(unsigned char *dst, int len, void* dat) {
	std::minstd_rand0* point = (std::minstd_rand0*)dat;
	int i;
	for (i = 0; i < len; i++) {
		dst[i]=static_cast<unsigned char>(point->operator()());
	}
	return i;
}*/

int cb(unsigned char *dst, int len, void* dat) {
    boost::random::minstd_rand0* gen = (boost::random::minstd_rand0*) dat;

    int i;
    for (i = 0; i < len; i++) {
        dst[i]=static_cast<unsigned char>(gen->operator ()());
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
    //std::minstd_rand0 generator (seed);
    boost::random::minstd_rand0 gen(seed);
	
	// 3) prime generation
	const int dim_bit = 256; // dimensione numero primo in bit
	const int safetyp = 8; // parametro per il miller-rabin (?)
    mp_prime_random_ex(prime_image, safetyp, dim_bit, LTM_PRIME_SAFE, cb, &gen);
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

extern vector<unsigned char> ParseHexV(const Value& v, string strName);
Value createrawaccumulatortransaction(const Array& params, bool fHelp)
{
    if (fHelp || params.size() != 4)
        throw runtime_error(
                            "createrawaccumulatortransaction <username> <pubKey> <accumulator> <address>\n"
							"Create a transaction registering a new group username\n"
							"pubKey and accumulator must be in hex format\n"
                            "address is the dht address where the signatures of the accumulator are stored\n"
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
	
    //rawTx.pubKey << vch;
    //if( params.size() > 2) {
    //    vector<unsigned char> vchSign(ParseHexV(params[2], "signedByOldKey"));
    //    rawTx.pubKey << vchSign;
    //}

    string address = params[3].get_str();
    rawTx.pubKey = CScript() << address;
	
	vector<unsigned char> ach(ParseHexV(params[2], "accumulator"));
	rawTx.accumulator = CScript() << ach;
	
    DoTxProofOfWork(rawTx);
	
    CDataStream ss(SER_NETWORK, PROTOCOL_VERSION);
    ss << rawTx;
    return HexStr(ss.begin(), ss.end());
}

Value getprimefromusername(const Array& params, bool fHelp) {
    if (fHelp || params.size() != 1) {
        throw runtime_error(
                            "getprimefromusername <username> \n"
                            "Get the prime number associated with the username.");
    }

    string username_str = params[0].get_str();

    mp_int prime_image;
    mp_init(&prime_image);
    mapToPrime(&prime_image, username_str);

    char *prime = (char*)malloc(65);
    mp_tohex(&prime_image, prime);

    return prime;
}

Value addwitnesstouser(const Array& params, bool fHelp)
{
	printf(BOLDMAGENTA "\nadding new witness" RESET);
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
	
	printf(BOLDMAGENTA "\nfilling entry" RESET);
    entry p;
    entry& target = p["target"];
    target["n"] = username;
    target["r"] = string("witness");
    target["t"] = "s";
    p["seq"] = 0;  /* TODO solo per farlo funzionare, bisognerebbe mettere il valore giusto (vedere se c'è già
    un accumulatore, incrementare etc...?) */
    p["time"] = GetAdjustedTime();
    int height = getBestHeight()-1; // be conservative
    p["height"] = height;
	libtorrent::entry v = witness; // TODO: [AP] ovviamente ci andrebbe anche la firma!
    p["v"] = v;

    // [MZ] Prova a mettere questa firma, anche se no ho ancora capito in che contesto venga usata.
    std::vector<char> pbuf;
    bencode(std::back_inserter(pbuf), p);
    std::string str_p = std::string(pbuf.data(),pbuf.size());
    std::string sig_p = createSignature(str_p, username);

    boost::shared_ptr<session> ses(m_ses);

	if (ses) {
		// publish witness to dht
		printf(BOLDMAGENTA "\npublish witness to dht:" RESET);
		printf(BOLDMAGENTA "\n[ username: %s, v: %s ]" RESET, username.c_str(), v.string().c_str());
        ses->dht_putDataSigned(username, string("witness"), false, p, sig_p, username, 0);
        /* RES_T_SINGLE era definito come false */
        /*ses->dht_putData(username, string("witness"), RES_T_SINGLE,
                         v, username, GetAdjustedTime(), 0); ///<-- [AP] se abbiamo il tempo k può essere 0?*/
	}
	
	printf(BOLDMAGENTA "\nwriting on disk" RESET);
	if (!pwalletMain->AddWitnessTo(username, witness))
		throw runtime_error(
						   "addwitnesstouser() : could not addWitnessTo\n");
	return witness;
}
