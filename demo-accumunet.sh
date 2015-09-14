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

sleep 5

~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addnode 192.168.56.3:28333 add
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addnode 192.168.56.2:28333 add
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addnode 192.168.56.3:28333 add

~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
sleep 0.5
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
sleep 0.5
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
sleep 0.5
coloredEcho "starting miner..." yellow
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd setgenerate true 1
sleep 0.5
coloredEcho "Creating structure" yellow
# Transazione di struttura
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd sendrawtransaction 01000000000d0c5f7374727563747572655f3108077574656e74653129287b22726f7773223a332c22636f6c756d6e73223a332c226f72646572223a227574656e746531227dc59b0000
coloredEcho "\nwait a moment for the dht to be ready" red
sleep 5
coloredEcho "\nPress any button when the dht is loaded" blue
read -n1
coloredEcho "Publishing order for structure" yellow
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 order s '["utente1","utente2"]' utente1 0
coloredEcho "Publishing signatures for accumulator" yellow
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 signature s '{"utente1":"HwctHmA3eskXqU8XZvZ5UYOuv6kLyPvfk440kpfXQXaXtjhb/CQuzg+bUscIQc9vNk7eXPH46Xkmq7ICQ8dnePw=","utente2":"IPyAistijtTqgXLTmC1Z1w4er5EZAEDlCRGDScfV+uQbImH4p3agJ8xHsD/OiyCdclevSo2kFCDBE0HaepIiSYM="}' utente1 0
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente2 signature s '{"utente1":"H8EmLQjjAwjtYzSldmKi/SqCx4wBvfxqZsCW9Td4+GFdCG1BQluI293q4WEPZMtZnAfiNBwbyfZx40t80bXTxpo=","utente2":"IPrI4rpbaoVuuDu4hMAJ8m9B8ec0pxm5XjCEkbiwErnBqSn1tPzBTS82o8i+qh2mNjEpwNjiQR9/g6cKdIIrfhI="}' utente2 0
sleep 2
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente1 1 \"Primo post utente1\"
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente1 2 \"Vendo_vino_buono\"
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente2 1 \"Ciao_sono_utente2\"
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente2 2 \"Vendo_vino_buonissimo\"
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente3 1 \"test_di_messaggio\"
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente1 [\"utente1\",\"utente2\",\"utente3\"]
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente2 [\"utente1\",\"utente2\"]
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente3 [\"utente1\",\"utente2\"] 
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 home s [\"utente1\",\"utente2\"] utente1 0

coloredEcho "\nPress a button to publish the new accumulator with related signatures" blue
read -n1
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 order s [\"utente1\",\"utente2\",\"utente3\"] utente1 1
sleep 2
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd sendrawtransaction 010000000009085f61646d696e5f3208077574656e746532212007eedc174ba9061088bc764189ecb85d351a615f0ca5781c77436735f23224c5afed0000
coloredEcho "\nWait for the transaction to be included in the blockchain" red
read -n1
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente3 1 \"test_di_messaggio\"
~/accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente1 [\"utente1\",\"utente2\",\"utente3\"]

echo "done!"