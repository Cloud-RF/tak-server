#!/bin/bash

printf "\nThis script assumes that you are working in tak-server directory cloned from github.\n"
printf "Is this the correct directory?..$(pwd), if not please change your directory.\n"

printf "Checking and Installing necessary dependencies.\n"

jar 2>/dev/null

if [ $? -ne 0 ];
then
	sudo apt-get install openjdk-11-jdk -y
fi

convert >/dev/null

if [ $? -ne 0 ];
then
	sudo apt-get install imagemagick -y
fi

printf "All dependencies satisfied.\n"

logo=$1

printf "Processing....\n"

rm -rf logo-change
mkdir logo-change

printf "Extracting neccessary tak-server files...\n"

cp ./tak/takserver.war ./logo-change

cd logo-change

jar -xvf ./takserver.war

cd ./logo

printf "Processing new logo...\n"

printf "Converting to png\n"
convert $1 -resize 200x100 RTN-BBN-primary.png
printf "Converting to jpg\n"
convert $1 -resize 200x100 RTN-BBN-primary.jpg

cd ../

printf "Updating tak-server file with new logo\n"

jar -uvf takserver.war logo/RTN-BBN-primary.png
jar -uvf takserver.war logo/RTN-BBN-primary.jpg

cp takserver.war ../tak/takserver.war

cd ../

printf "If no errors showing up, the processing has finished successfully.\n"