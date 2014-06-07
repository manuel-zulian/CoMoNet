#!/bin/bash

BIN=./aLaunch

echo "Do you want to restart all? [y/N]"
read -n1 answer
if [ "$answer" == "y" ]
then
    $BIN delete 1 2
else
    if [ "$answer" != "n" ]
    then
	echo -e "\nAssuming NO\n\n\n"
    fi
fi

$BIN lboot 1 2
$BIN rhtml 1 2
$BIN start 1 2
sleep 4
$BIN connect 1 2
$BIN connect 2 1
$BIN cmd 1 addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
$BIN cmd 2 addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
sleep 0.5
$BIN cmd 2 addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
$BIN cmd 1 addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
sleep 0.5
$BIN cmd 2 addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
$BIN cmd 1 addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
sleep 0.5
$BIN cmd 1 setgenerate true -1
sleep 0.5
echo "starting miner..."
echo -e "\nPress any button when the dht is loaded"
read -n1
$BIN cmd 1 newpostmsg utente1 1 \"Primo_post.in.cui-non_si.dice.nulla\"
$BIN cmd 1 newpostmsg utente1 2 \"Secondo_post.in.cui-non_si.dice.nulla\"
$BIN cmd 2 newpostmsg utente2 1 \"Ciao\"
$BIN cmd 2 newpostmsg utente2 2 \"mondo!\"
$BIN cmd 1 follow utente1 [\"utente1\",\"utente2\"]
$BIN cmd 2 follow utente2 [\"utente1\",\"utente2\"] 
$BIN cmd 1 dhtput utente1 home s [\"utente1\",\"utente2\"] utente1 0
#in futuro l'utente che firma può essere diverso dall'utente specificato, tipo _admin_ mette il nome e utente1, che è accumulato può firmare a nome di tutti.
echo "done!"
