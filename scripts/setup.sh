#!/bin/bash

color() {
    STARTCOLOR="\e[$2";
    ENDCOLOR="\e[0m";
    export "$1"="$STARTCOLOR%b$ENDCOLOR" 
}
color info 96m
color success 92m 
color warning 93m 
color danger 91m 

docker compose 2> /dev/null
if [ $? -eq 0 ];
then
	echo "alias docker-compose='docker compose'" >> ~/.bashrc
	source ~/.bashrc
fi

printf $success "\nTAK server setup script"
printf $info "\nStep 1. Download the official docker image as a zip file from https://tak.gov/products/tak-server \nStep 2. Place the zip file in this tak-server folder.\n"
printf $warning "\nElevated privileges are required to enumerate process names which may be holding open TCP ports.\nPlease enter your password when prompted.\n"

arch=$(dpkg --print-architecture)

DOCKERFILE=docker-compose.yml

if [ $arch == "arm64" ];
then
	DOCKERFILE=docker-compose.arm.yml
	printf "\nBuilding for arm64...\n" "info"
fi


### Check if required ports are in use by anything other than docker
netstat_check () {
	
	ports=(5432 8443 8444 8446 9000 9001)
	
	for i in ${ports[@]};
	do
		sudo netstat -plant | grep $i
		if [ $? -eq 0 ];
		then
			proc=$(netstat -plant | grep $i | awk '{print $7}' | cut -d/ -f1,2)
			prockill=$(netstat -plant | grep $i | awk '{print $7}' | cut -d/ -f1)
			printf $info "\nThis process $proc is using port $i which is required for TAK server to operate. Do you want me to kill the process (y/n): " 
			read choice
			if [ $choice == "y" ];
			then
				sudo kill -15 $prockill

			elif [ $choice == "yes" ];
			then
				sudo kill -15 $prockill
			else
				printf $danger "Please repeat the process once the port $i is not in use. Exiting now..\n" 
				sleep 1
				exit 0
			fi
		else
			printf $success "\nPort $i is available.."
		fi
	done
	
}

tak_folder () {
	### Check if the folder "tak" exists after previous install or attempt and remove it or leave it for the user to decide
	if [ -d "./tak" ] 
	then
	    printf $warning "\nDirectory 'tak' already exists. This will be removed along with the docker volume, do you want to continue? (y/n): "
	    read dirc
	    if [ $dirc == "n" ];
	    then
	    	printf "Exiting now.."
	    	sleep 1
	    	exit 0
	    elif [ $dirc == "no" ];
	    then
	    	printf "Exiting now.."
	    	sleep 1
	    	exit 0
	   	fi
		rm -rf tak
		rm -rf /tmp/takserver
		docker volume rm --force tak-server_db_data
	fi 
}


checksum () {
	printf "\nChecking for TAK server release files (..RELEASE.zip) in the directory....\n"
	sleep 1

	if [ "$(ls -hl *-RELEASE-*.zip 2>/dev/null)" ];
	then
		printf $warning "SECURITY WARNING: Make sure the checksums match! You should only download your release from a trusted source eg. tak.gov:\n"
		for file in *.zip;
		do
			printf "Computed SHA1 Checksum: "
			sha1sum $file 
			printf "Computed MD5 Checksum: "
			md5sum $file
		done
		printf "\nVerifying checksums against known values for $file...\n"
		sleep 1
		printf "SHA1 Verification: "
		sha1sum --ignore-missing -c tak-sha1checksum.txt
		if [ $? -ne 0 ];
		then
			printf $danger "SECURITY WARNING: The file is either different OR is not listed in the known releases.\nDo you really want to continue with this setup? (y/n): "
			read check
			if [ "$check" == "n" ];
			then
				printf "\nExiting now..."
				exit 0
			elif [ "$check" == "no" ];
			then
				printf "Exiting now..."
				exit 0
			fi
		fi
		printf "MD5 Verification: "
		md5sum --ignore-missing -c tak-md5checksum.txt
		if [ $? -ne 0 ];
		then
			printf $danger "SECURITY WARNING: The checksum is not correct, so the file is different. Do you really want to continue with this setup? (y/n): "
			read check
			if [ "$check" == "n" ];
			then
				printf "\nExiting now..."
				exit 0
			elif [ "$check" == "no" ];
			then
				printf "Exiting now..."
				exit 0
			fi
		fi
	else
		printf $danger "\n\tPlease download the release of docker image as per instructions in README.md file. Exiting now...\n\n"
		sleep 1
		exit 0
	fi
}

netstat_check
tak_folder
if [ -d "tak" ] 
then
	printf $danger "Failed to remove the tak folder. You will need to do this as sudo: sudo rm -rf tak\n"
	exit 0
fi
checksum

# The actual container setup starts here

### Vars

release=$(ls -hl *.zip | awk '{print $9}' | cut -d. -f -2)

printf $warning "\nPausing to let you know release version $release will be setup in 5 seconds.\nIf this is wrong, hit Ctrl-C now..." 
sleep 5


## Set up directory structure
if [ -d "/tmp/takserver" ] 
then
	rm -rf /tmp/takserver
fi

unzip $release.zip -d /tmp/takserver
mv -f /tmp/takserver/$release/tak ./
chown -R $USER:$USER tak
clear

cp ./scripts/configureInDocker1.sh ./tak/db-utils/configureInDocker.sh
cp ./postgresql1.conf ./tak/postgresql.conf
cp ./scripts/takserver-setup-db-1.sh ./tak/db-utils/takserver-setup-db.sh
cp ./CoreConfig.xml ./tak/CoreConfig.xml

## Set admin username and password
user="admin"
pwd=$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-18} | head -n 1)
password=$pwd"!"

## Set postgres password
pgpwd="$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-18} | head -n 1)"
pgpassword=$pgpwd"!"
sed -i "s/password=\".*\"/password=\"${pgpassword}\"/" tak/CoreConfig.xml

## Set variables for generating CA and client certs
printf $warning "SSL setup. Hit enter (x4) to accept the defaults:\n"
read -p "State (for cert generation). Default [state] :" state
read -p "City (for cert generation). Default [city]:" city
read -p "Organizational Unit (for cert generation). Default [org]:" orgunit

if [ -z "$state" ];
then
	state="state"
fi

if [ -z "$city" ];
then
	city="city"
fi

if [ -z "$orgunit" ];
then
	orgunit="org"
fi

# Writes variables to a .env file for docker-compose
cat << EOF > .env
STATE=$state
CITY=$city
ORGANIZATIONAL_UNIT=$orgunit
EOF

### Runs through setup, starts both containers

docker-compose --file $DOCKERFILE up  --force-recreate &

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

printf $info "Waiting for TAK server to go live. This should take < 30s with an AMD64, ~1min on a ARM64 (Pi)\n"
docker-compose start tak
### Checks if java is fully initialised

while :
do
	sleep 10
	# docker-compose exec tak bash -c "java -jar /opt/tak/db-utils/SchemaManager.jar upgrade"
	docker-compose exec tak bash -c "cd /opt/tak/ && java -jar /opt/tak/utils/UserManager.jar usermod -A -p $password $user"
	if [ $? -eq 0 ];
	then
		# docker-compose exec tak bash -c "cd /opt/tak/ && java -jar /opt/tak/utils/UserManager.jar usermod -A -p $password $user"
		docker-compose exec tak bash -c "cd /opt/tak/ && java -jar utils/UserManager.jar certmod -A certs/files/$user.pem"
		if [ $? -eq 0 ]; 
		then
			# docker-compose exec tak bash -c "cd /opt/tak/ && java -jar utils/UserManager.jar certmod -A certs/files/$user.pem"
			docker-compose exec tak bash -c "java -jar /opt/tak/db-utils/SchemaManager.jar upgrade"
			if [ $? -eq 0 ];
			then

				break
			else
				sleep 10
			fi
		else
			sleep 10
		fi
	else
		sleep 10
	fi
done

### Post-installation message to user including randomly generated passwrods to use for account and PostgreSQL

printf $success "\n\nIf the database was updated OK (eg. Successfully applied 64 update(s)), \nExport relevant certificate from tak server and upload to the browser as per README.md fiel, \nlogin at https://localhost:8443 with your admin account. No need to run the /setup step as this has been done.\n" 
printf $success "You should probably remove the port 8080:8080 mapping in docker-compose.yml to secure the server afterwards.\n" 
printf $success "Admin user certs are at ./tak/certs/files \n\n" 
printf $success "Setup script sponsored by CloudRF.com - \"The API for RF\"\n\n"
printf $danger "---------PASSWORDS----------------\n\n"
printf $danger "Admin user name: $user\n" # Web interface default user name
printf $danger "Admin password: $password\n" # Web interface default random password created during setup
printf $danger "Postgresql password: $pgpassword\n\n" # PostgreSQL password randomly generated during set up
printf $danger "---------PASSWORDS----------------\n\n"
printf $warning "MAKE A NOTE OF YOUR PASSWORDS. THEY WON'T BE SHOWN AGAIN.\n"
printf $info "To start the containers next time you login, execute from this folder: docker-compose up\n"
