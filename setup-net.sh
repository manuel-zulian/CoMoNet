#!/bin/bash

BIN=./aLaunch

echo "Do you want to restart all? [y/N]"
read -n1 answer
if [ "$answer" == "y" ]
then
    $BIN delete 1 3
else
    if [ "$answer" != "n" ]
    then
	echo -e "\nAssuming NO\n\n\n"
    fi
fi

$BIN lboot 1 3
$BIN rhtml 1 3
$BIN start 1 3
sleep 5
$BIN connect 1 2
$BIN connect 2 1
$BIN connect 3 2
$BIN cmd 1 addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
$BIN cmd 2 addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
$BIN cmd 3 addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
sleep 0.5
$BIN cmd 2 addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
$BIN cmd 1 addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
$BIN cmd 3 addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
sleep 0.5
$BIN cmd 2 addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
$BIN cmd 1 addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
$BIN cmd 3 addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
sleep 0.5
$BIN cmd 1 setgenerate true 1
sleep 0.5
echo "starting miner..."
echo "wait a moment for the dht to be ready"
sleep 5
echo -e "\nPress any button when the dht is loaded"
read -n1
$BIN cmd 1 dhtput utente1 signature s '{"utente1":"HwctHmA3eskXqU8XZvZ5UYOuv6kLyPvfk440kpfXQXaXtjhb/CQuzg+bUscIQc9vNk7eXPH46Xkmq7ICQ8dnePw=","utente2":"IPyAistijtTqgXLTmC1Z1w4er5EZAEDlCRGDScfV+uQbImH4p3agJ8xHsD/OiyCdclevSo2kFCDBE0HaepIiSYM="}' utente1 0
$BIN cmd 1 newpostmsg utente1 1 \"Primo_post_utente1\"
$BIN cmd 1 newpostmsg utente1 2 \"Vendo_vino_buono\"
$BIN cmd 2 newpostmsg utente2 1 \"Ciao_sono_utente2\"
$BIN cmd 2 newpostmsg utente2 2 \"Vendo_vino_buonissimo\"
$BIN cmd 3 newpostmsg utente3 1 \"test_di_messaggio\"
$BIN cmd 1 follow utente1 [\"utente1\",\"utente2\",\"utente3\"]
$BIN cmd 2 follow utente2 [\"utente1\",\"utente2\"]
$BIN cmd 3 follow utente3 [\"utente1\",\"utente2\"] 
$BIN cmd 1 dhtput utente1 home s [\"utente1\",\"utente2\"] utente1 0

echo "Press a button to publish the new accumulator with related signatures"
read -n1
$BIN cmd 1 dhtput utente1 signature s '{"utente1":"H8EmLQjjAwjtYzSldmKi/SqCx4wBvfxqZsCW9Td4+GFdCG1BQluI293q4WEPZMtZnAfiNBwbyfZx40t80bXTxpo=","utente2":"IPrI4rpbaoVuuDu4hMAJ8m9B8ec0pxm5XjCEkbiwErnBqSn1tPzBTS82o8i+qh2mNjEpwNjiQR9/g6cKdIIrfhI="}' utente1 1
sleep 2
$BIN cmd 1 sendrawtransaction 010000000009085f61646d696e5f3208077574656e746531212007eedc174ba9061088bc764189ecb85d351a615f0ca5781c77436735f23224c5b6500000
echo "Wait for the transaction to be included in the blockchain"
read -n1
$BIN cmd 3 newpostmsg utente3 1 \"test_di_messaggio\"
$BIN cmd 1 follow utente1 [\"utente1\",\"utente2\",\"utente3\"]
$BIN cmd 1 dhtput utente1 home s [\"utente1\",\"utente2\",\"utente3\"] utente1 1

#in futuro l'utente che firma può essere diverso dall'utente specificato, tipo _admin_ mette il nome e utente1, che è accumulato può firmare a nome di tutti.
echo "done!"
