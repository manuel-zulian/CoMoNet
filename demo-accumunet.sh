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

if [ "$1" = "stop" ]; then
	docker stop acc1
	docker rm acc1
	docker stop acc2
	docker rm acc2
	docker stop acc3
	docker rm acc3
elif [ "$1" = "restart" ]; then
	sudo rm -fr ./acc1
	sudo rm -fr ./acc2
	sudo rm -fr ./acc3
	./$0 stop
	./$0
else

	IMAGE_NAME=twister

	if [ ! -d "acc1" ]; then
	  # Control will enter here if $DIRECTORY doesn't exist.
	  cp -r acc-01 acc1
	  cp bootstrap.dat ./acc1
	  cp twisterwallet.dat ./acc1
	fi

	if [ ! -d "acc2" ]; then
	  # Control will enter here if $DIRECTORY doesn't exist.
	  cp -r acc-02 acc2
	  cp bootstrap.dat ./acc2
	  cp twisterwallet.dat ./acc2
	fi

	if [ ! -d "acc3" ]; then
	  # Control will enter here if $DIRECTORY doesn't exist.
	  cp -r acc-03 acc3
	  cp bootstrap.dat ./acc3
	  cp twisterwallet.dat ./acc3
	fi

	# Il flag rm serve a poter riutlizzare il nome
	docker run -d -p 48001:28333 --name="acc1" -v ~/accumunet-mz/acc1:/root/.twister $IMAGE_NAME -datadir=/root/.twister -genproclimit=1
	docker run -d -p 48002:28333 --name="acc2" -v ~/accumunet-mz/acc2:/root/.twister $IMAGE_NAME -datadir=/root/.twister -genproclimit=1
	docker run -d -p 48003:28333 --name="acc3" -v ~/accumunet-mz/acc3:/root/.twister $IMAGE_NAME -datadir=/root/.twister -genproclimit=1

	sleep 5

	IP1=`docker inspect acc1 | grep IPAddress | cut -d '"' -f 4`
	echo $IP1
	IP2=`docker inspect acc2 | grep IPAddress | cut -d '"' -f 4`
	echo $IP2
	IP3=`docker inspect acc3 | grep IPAddress | cut -d '"' -f 4`
	echo $IP3

	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addnode $IP2:28333 add
	docker exec acc2 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addnode $IP1:28333 add
	docker exec acc3 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addnode $IP2:28333 add

	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
	docker exec acc2 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
	docker exec acc3 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente1 357d626250e41eb0390d60e4c33859369681fec371ab532e428b63059e97c6a7
	sleep 0.5
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
	docker exec acc2 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
	docker exec acc3 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente2 26ff76d0f66b8403bda6534fce3dbcaf47ffd5eb7e06720dd3d58aee587a39a5
	sleep 0.5
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
	docker exec acc2 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
	docker exec acc3 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd addwitnesstouser utente3 450da364ae10b42c83f180d01fecf5cbd0901d4b1b8eed22d8490d46a42a65e7
	sleep 0.5
	coloredEcho "starting miner..." yellow
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd setgenerate true 1
	sleep 0.5
	coloredEcho "Creating structure" yellow
	# Transazione di struttura
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd sendrawtransaction 01000000000d0c5f7374727563747572655f3108077574656e74653129287b22726f7773223a332c22636f6c756d6e73223a332c226f72646572223a227574656e746531227dc59b0000
	coloredEcho "\nwait a moment for the dht to be ready" red
	sleep 5
	coloredEcho "\nPress any button when the dht is loaded" blue
	read -n1
	coloredEcho "Publishing order for structure" yellow
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 order s '["utente1","utente2"]' utente1 0
	coloredEcho "Publishing signatures for accumulator" yellow
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 signature s '{"utente1":"HwctHmA3eskXqU8XZvZ5UYOuv6kLyPvfk440kpfXQXaXtjhb/CQuzg+bUscIQc9vNk7eXPH46Xkmq7ICQ8dnePw=","utente2":"IPyAistijtTqgXLTmC1Z1w4er5EZAEDlCRGDScfV+uQbImH4p3agJ8xHsD/OiyCdclevSo2kFCDBE0HaepIiSYM="}' utente1 0
	sleep 2
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente1 1 \"Primo_post_utente1\"
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente1 2 \"Vendo_vino_buono\"
	docker exec acc2 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente2 1 \"Ciao_sono_utente2\"
	docker exec acc2 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente2 2 \"Vendo_vino_buonissimo\"
	docker exec acc3 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente3 1 \"test_di_messaggio\"
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente1 [\"utente1\",\"utente2\",\"utente3\"]
	docker exec acc2 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente2 [\"utente1\",\"utente2\"]
	docker exec acc3 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente3 [\"utente1\",\"utente2\"] 
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 home s [\"utente1\",\"utente2\"] utente1 0

	coloredEcho "\nPress a button to publish the new accumulator with related signatures" blue
	read -n1
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 signature s '{"utente1":"H8EmLQjjAwjtYzSldmKi/SqCx4wBvfxqZsCW9Td4+GFdCG1BQluI293q4WEPZMtZnAfiNBwbyfZx40t80bXTxpo=","utente2":"IPrI4rpbaoVuuDu4hMAJ8m9B8ec0pxm5XjCEkbiwErnBqSn1tPzBTS82o8i+qh2mNjEpwNjiQR9/g6cKdIIrfhI="}' utente1 0
	sleep 2
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd sendrawtransaction 010000000009085f61646d696e5f3208077574656e746531212007eedc174ba9061088bc764189ecb85d351a615f0ca5781c77436735f23224c5b6500000
	coloredEcho "\nWait for the transaction to be included in the blockchain" red
	read -n1
	docker exec acc3 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd newpostmsg utente3 1 \"test_di_messaggio\"
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd follow utente1 [\"utente1\",\"utente2\",\"utente3\"]
	docker exec acc1 /accumunet/twisterd -genproclimit=1 -rpcuser=user -rpcpassword=pwd dhtput utente1 home s [\"utente1\",\"utente2\",\"utente3\"] utente1 1

	echo "done!"
fi