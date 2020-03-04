#!/usr/bin/env bash

while [ "2" -lt 3 ]
do
	killall MUDCrawler
	./.build/release/MUDCrawler snitchmine > mine.log &
	# echo "Run program"

	sleep 4

	LINE=$(tail -n 1 mine.log | grep -m 1 '.') 
	re='^-?[0-9]+$'
	if ! [[ $LINE =~ $re ]] ; then
		LINE=0
	fi
	while [ $LINE -gt -40 ]
	do
		echo "sleeping ($LINE)"
		sleep 1
		LINE=$(tail -n 1 mine.log | grep -m 1 '.') 

		if ! [[ $LINE =~ $re ]] ; then
			LINE=0
		fi		
	done
done
