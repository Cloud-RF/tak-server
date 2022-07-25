#!/bin/bash

printf "\n Please make sure that you have downloaded the official docker image as zip file from https://tak.gov/products/tak-server \nPlace the downloaded file to the folder where this git repository is located on your computer.\n"

### Check if required ports are in use by anything other than docker
netstat_check () {
	
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
	
}

tak_folder () {
	### Check if the folder "tak" exists after previous install or attempt and remove it or leave it for the user to decide
	if [ -d "./tak" ] 
	then
	    printf "Directory 'tak' already exists. This will be overwritten, do you want to continue? (y/n): "
	    read dirc
	    if [ $dirc == "n" ];
	    then
	    	printf "Exitting now.."
	    	sleep 1
	    	exit 0
	    elif [ $dirc == "no" ];
	    then
	    	printf "Exitting now.."
	    	sleep 1
	    	exit 0
	   	fi
	fi 
}


checksum () {
	printf "Checking if the release file is present in the directory....\n"
	sleep 1

	if [ "$(ls -hl *-RELEASE-*.zip 2>/dev/null)" ];
	then
		printf "Calculating checksum, make sure that this is the same as the published checksums for particular release:\n"
		for file in *.zip;
		do
			printf "SHA1 Checksum: "
			sha1sum $file
			printf "MD5 Checksum: "
			md5sum $file
		done
		printf "\nVerifying checksums...\n"
		sleep 1
		printf "SHA1 Veryfication: "
		sha1sum -c tak-sha1checksum.txt
		if [ $? -ne 0 ];
		then
			printf "The checksum is not correct, the file has been modified, do you want to continue with this setup? (y/n): "
			read check
			if [ "$check" == "n" ];
			then
				printf "\nExitting now..."
				exit 0
			elif [ "$check" == "no" ];
			then
				printf "Exitting now..."
				exit 0
			fi
		fi
		printf "MD5 Veryfication: "
		md5sum -c tak-md5checksum.txt
		if [ $? -ne 0 ];
		then
			printf "The checksum is not correct, the file has been modified, do you want to continue with this setup? (y/n): "
			read check
			if [ "$check" == "n" ];
			then
				printf "\nExitting now..."
				exit 0
			elif [ "$check" == "no" ];
			then
				printf "Exitting now..."
				exit 0
			fi
		fi
	else
		printf "\n\tPlease download the release of docker image as per instructions in READ.me file. Exitting now...\n\n"
		sleep 1
		exit 0
	fi
}

netstat_check
tak_folder
checksum

# The actual container setup starts here

### Vars

ls -hl *.zip | awk '{print $9}' | cut -d. -f -2

printf "\nPlease type the release version (that is a full name of the file before the .zip extension): "
read release


## Set up directory structure
unzip $release.zip -d /tmp/takserver
mv -f /tmp/takserver/$release/tak .
clear

## Set admin username and password
user="admin"
pwd=$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-16} | head -n 1)
password=$pwd"!"

## Set postgres password
export pgpwd="$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-16} | head -n 1)"
pgpassword=$pgpwd"!"
sed -i "s/password=\".*\"/password=\"${pgpassword}\"/" tak/CoreConfig.xml


## Set variables for generating CA and client certs
read -p "State (for cert generation). Default [$user] :" state
read -p "City (for cert generation). Default [$user]:" city
read -p "Organizational Unit (for cert generation). Default [$user]:" orgunit

if [ -z "$state" ];
then
	state="admin"
fi

if [ -z "$city" ];
then
	city="admin"
fi

if [ -z "$orgunit" ];
then
	orgunit="admin"
fi

# Writes variables to a .env file for docker-compose
cat << EOF > .env
STATE=$state
CITY=$city
ORGANIZATIONAL_UNIT=$orgunit
EOF

## Runs through setup
echo "Waiting for TAK Server to go live"
docker-compose --file docker-compose.arm.yml up -d

### Checking if the container is set up and ready to set the certificates

while :
do
	docker-compose exec tak bash -c "cd /opt/tak/certs && ./makeRootCa.sh"
	if [ $? -eq 0 ];
	then
		docker-compose exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh server takserver"
		if [ $? -eq 0 ];
		then
			docker-compose exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh client $user"	
			if [ $? -eq 0 ];
			then
				docker-compose stop tak
				break
			else 
				sleep 5
			fi
		else
			sleep 5
		fi
	else
		sleep 5
	fi
done

printf "waiting for TAK server to go live again (this may take longer on slower machines)"
docker-compose start tak

### Checks if java is fully initialised

while :
do
	docker-compose exec tak bash -c "cd /opt/tak/ && java -jar /opt/tak/utils/UserManager.jar usermod -A -p $password $user"
	
	if [ $? -eq 0 ]; 
	then
		docker-compose exec tak bash -c "cd /opt/tak/ && java -jar utils/UserManager.jar certmod -A certs/files/$user.pem"
		
		if [ $? -eq 0 ];
		then
			break
		else
			sleep 10
		fi
	
	else
		sleep 10
	fi
done

### Unsetting the environmental variables for random passwords

unset pwd
unset pgpwd

### Post-installation message to user including randomly generated passwrods to use for account and PostgreSQL

printf "If everything ran successfully, you should be able to hit the http address at http://localhost:8080 and configure TAK server the rest of the way."
printf "You should probably remove the port 8080:8080 mapping in docker-compose.yml to secure the server afterwards."
printf "Admin user certs should be under ./tak/certs/files \n"
printf "Your admin user name is: $user\n" # Web interface default user name
printf "Your admin password is: $password\n" # Web interface default random password created during setup
printf "Your Postgresql password is: $pgpassword\n" # PostgreSQL password randomly generated during set up