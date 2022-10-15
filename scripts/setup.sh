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

DOCKER_COMPOSE="docker-compose"

if ! command -v docker-compose
then
	DOCKER_COMPOSE="docker compose"
	echo "Docker compose command set to new style $DOCKER_COMPOSE"
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
	
	ports=(5432 8089 8443 8444 8446 9000 9001)
	
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
pwd=$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-11} | head -n 1)
password=$pwd"Meh1!"

## Set postgres password
pgpwd="$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-11} | head -n 1)"
pgpassword=$pgpwd"Meh1!"
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

# Update local env
export STATE=$state
export CITY=$city
export ORGANIZATIONAL_UNIT=$orgunit


# Writes variables to a .env file for docker-compose
cat << EOF > .env
STATE=$state
CITY=$city
ORGANIZATIONAL_UNIT=$orgunit
EOF

### Runs through setup, starts both containers
$DOCKER_COMPOSE --file $DOCKERFILE build
$DOCKER_COMPOSE --file $DOCKERFILE up  --force-recreate &

### Checking if the container is set up and ready to set the certificates

while :
do
	sleep 10 # let the PG stderr messages conclude...
	printf $warning "------------CERTIFICATE GENERATION--------------\n"
	$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeRootCa.sh"
	if [ $? -eq 0 ];
	then
		$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh server takserver"
		if [ $? -eq 0 ];
		then
			$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh client $user"	
			if [ $? -eq 0 ];
			then
				#$DOCKER_COMPOSE stop tak
				break
			else 
				sleep 5
			fi
		else
			sleep 5
		fi
	fi
done

printf $info "Creating certificates for 2 users in tak/certs/files since nobody can read a fucking manual\n"

# Set permissions so user can write to certs/files
$DOCKER_COMPOSE exec tak bash -c "useradd $USER && chown -R $USER:$USER /opt/tak/certs/"

# get IP
NIC=$(route | grep default | awk '{print $8}')
IP=$(ip addr show $NIC | grep "inet " | awk '{print $2}' | cut -d "/" -f1)

# Make 2 users
cd tak/certs
./makeCert.sh client user1
./makeCert.sh client user2

# Make 2 data packages
cd ../../
./scripts/certDP.sh $IP user1
./scripts/certDP.sh $IP user2


printf $info "Waiting for TAK server to go live. This should take < 30s with an AMD64, ~1min on a ARM64 (Pi)\n"
### Checks if java is fully initialised
while :
do
	sleep 10
	# docker-compose exec tak bash -c "java -jar /opt/tak/db-utils/SchemaManager.jar upgrade"
	$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/ && java -jar /opt/tak/utils/UserManager.jar usermod -A -p $password $user"
	if [ $? -eq 0 ];
	then
		# docker-compose exec tak bash -c "cd /opt/tak/ && java -jar /opt/tak/utils/UserManager.jar usermod -A -p $password $user"
		$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/ && java -jar utils/UserManager.jar certmod -A certs/files/$user.pem"
		if [ $? -eq 0 ]; 
		then
			# docker-compose exec tak bash -c "cd /opt/tak/ && java -jar utils/UserManager.jar certmod -A certs/files/$user.pem"
			$DOCKER_COMPOSE exec tak bash -c "java -jar /opt/tak/db-utils/SchemaManager.jar upgrade"
			if [ $? -eq 0 ];
			then

				break
			else
				sleep 5
			fi
		else
			sleep 5
		fi
	else
		printf $info "No joy with DB, will retry in 10...\n" 
	fi
done

cp ./tak/certs/files/$user.p12 .

### Post-installation message to user including randomly generated passwrods to use for account and PostgreSQL

printf $success "\n\nIf the database was updated OK (eg. Successfully applied 64 update(s)), \n"
printf $warning "Import the $user.p12 certificate from this folder to your browser as per the README.md file\n"
printf $success "Login at https://$IP:8443 with your admin account. No need to run the /setup step as this has been done.\n" 
printf $info "Certificates and *CERT DATA PACKAGES* are in tak/certs/files \n\n" 
printf $success "Setup script sponsored by CloudRF.com - \"The API for RF\"\n\n"
printf $danger "---------PASSWORDS----------------\n\n"
printf $danger "Admin user name: $user\n" # Web interface default user name
printf $danger "Admin password: $password\n" # Web interface default random password created during setup
printf $danger "Postgresql password: $pgpassword\n\n" # PostgreSQL password randomly generated during set up
printf $danger "---------PASSWORDS----------------\n\n"
printf $warning "MAKE A NOTE OF YOUR PASSWORDS. THEY WON'T BE SHOWN AGAIN.\n"
printf $info "To start the containers next time you login, execute from this folder: $DOCKER_COMPOSE up\n"
