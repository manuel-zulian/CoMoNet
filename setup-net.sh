#!/bin/bash

BIN=./aLaunch
$BIN start 1 2
$BIN connect 1 2
$BIN cmd 2 createwalletuser utente1
$BIN cmd 2 createwalletuser utente2
$BIN cmd 2 createwalletuser utente3
$BIN cmd 2 sendnewusertransaction utente1
$BIN cmd 2 sendnewusertransaction utente2
$BIN cmd 2 sendnewusertransaction utente3
$BIN cmd 2 sendrawtransaction 010000000008075f61646d696e5f0403ffffff2120450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e76e330000
$BIN cmd 2 addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7 
$BIN cmd 2 addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
$BIN cmd 2 addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
$BIN cmd 1 setgenerate true -1
echo "done!"
