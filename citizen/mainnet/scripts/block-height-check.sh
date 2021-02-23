#!/bin/bash

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/api/v1/avail/peer)

if [[ $HTTP_CODE -eq "503" ]]; then
	echo "503 status code. Checking if block height is increasing..."
	BH1=$(curl -s http://localhost:9000/api/v1/avail/peer | jq '.block_height')
	echo $BH1
	sleep 5
	BH2=$(curl -s http://localhost:9000/api/v1/avail/peer | jq '.block_height')
	echo $BH2
	if [[ $BH2 -gt $BH1 ]]; then
		echo "Block height is increasing, there is no problem."
	else
		echo "Block heigh is not increasing. Restarting node now..."
		cd /home/icon/prep && docker-compose down
		cd /home/icon/prep && docker-compose up -d
	fi
	else
		echo "200 status code. Exiting now..."
fi
