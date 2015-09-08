#!/bin/bash

function coloredEcho(){
    local exp=$1;
    local color=$2;
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput setaf $color;
    echo -e $exp;
    tput sgr0;
}

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
coloredEcho "starting miner..." yellow
$BIN cmd 1 setgenerate true 1
sleep 0.5
coloredEcho "Creating structure" yellow
# Transazione di struttura
$BIN cmd 1 sendrawtransaction 01000000000d0c5f7374727563747572655f3108077574656e74653129287b22726f7773223a332c22636f6c756d6e73223a332c226f72646572223a227574656e746531227dc59b0000
coloredEcho "\nwait a moment for the dht to be ready" red
sleep 5
coloredEcho "\nPress any button when the dht is loaded" blue
read -n1
coloredEcho "Publishing order for structure" yellow
$BIN cmd 1 dhtput utente1 order s '["utente1","utente2"]' utente1 0
coloredEcho "Publishing signatures for accumulator" yellow
$BIN cmd 1 dhtput utente1 signature s '{"utente1":"HwctHmA3eskXqU8XZvZ5UYOuv6kLyPvfk440kpfXQXaXtjhb/CQuzg+bUscIQc9vNk7eXPH46Xkmq7ICQ8dnePw=","utente2":"IPyAistijtTqgXLTmC1Z1w4er5EZAEDlCRGDScfV+uQbImH4p3agJ8xHsD/OiyCdclevSo2kFCDBE0HaepIiSYM="}' utente1 0
$BIN cmd 1 dhtput utente2 signature s '{"utente1":"H8EmLQjjAwjtYzSldmKi/SqCx4wBvfxqZsCW9Td4+GFdCG1BQluI293q4WEPZMtZnAfiNBwbyfZx40t80bXTxpo=","utente2":"IPrI4rpbaoVuuDu4hMAJ8m9B8ec0pxm5XjCEkbiwErnBqSn1tPzBTS82o8i+qh2mNjEpwNjiQR9/g6cKdIIrfhI="}' utente2 0
sleep 2
$BIN cmd 1 newpostmsg utente1 1 \"Primo_post_utente1\"
$BIN cmd 1 newpostmsg utente1 2 \"Vendo_vino_buono\"
$BIN cmd 2 newpostmsg utente2 1 \"Ciao_sono_utente2\"
$BIN cmd 2 newpostmsg utente2 2 \"Vendo_vino_buonissimo\"
$BIN cmd 3 newpostmsg utente3 1 \"test_di_messaggio\"
$BIN cmd 1 follow utente1 [\"utente1\",\"utente2\",\"utente3\"]
$BIN cmd 2 follow utente2 [\"utente1\",\"utente2\"]
$BIN cmd 3 follow utente3 [\"utente1\",\"utente2\"] 
$BIN cmd 1 dhtput utente1 home s [\"utente1\",\"utente2\"] utente1 0

coloredEcho "\nPress a button to publish the new accumulator with related signatures" blue
read -n1
$BIN cmd 1 dhtput utente1 order s [\"utente1\",\"utente2\",\"utente3\"] utente1 1
sleep 2
$BIN cmd 1 sendrawtransaction 010000000009085f61646d696e5f3208077574656e746532212007eedc174ba9061088bc764189ecb85d351a615f0ca5781c77436735f23224c5afed0000
coloredEcho "\nWait for the transaction to be included in the blockchain" red
read -n1
$BIN cmd 3 newpostmsg utente3 1 \"test_di_messaggio\"
$BIN cmd 1 follow utente1 [\"utente1\",\"utente2\",\"utente3\"]

echo "done!"