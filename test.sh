#!/bin/bash

ports=(8443 8444 8446 8087 8088 9000 9001 8080)
for i in ${ports[@]};
do
	sudo netstat -plant | grep $i
	if [ $? -eq 0 ];
	then
		proc=$(netstat -plant | grep $i | awk '{print $7}' | cut -d/ -f1,2)
		prockill=$(netstat -plant | grep $i | awk '{print $7}' | cut -d/ -f1)
		printf "\nThis process $proc is using port $i which is required for TAK server to operate. Do you wnat me to kill the process now (y/n): "
		read choice
		if [ $choice == "y" ];
		then
			sudo kill -15 $prockill

		elif [ $choice == "yes" ];
		then
			sudo kill -15 $prockill
		else
			printf "The installation will not suceed, please repeat the process once the port $i is not in use. Exiting now..\n"
			sleep 1
			exit 0
		fi
	fi
done

