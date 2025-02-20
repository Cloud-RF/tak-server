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


printf $success "\nTAK server setup script sponsored by CloudRF.com - \"The API for RF\"\n"
printf $info "\nStep 1. Download the official docker image as a zip file from https://tak.gov/products/tak-server \nStep 2. Place the zip file in this tak-server folder.\n"
printf $warning "\nYou should install this as a user. Elevated privileges (sudo) are only required to clean up a previous install eg. sudo ./scripts/cleanup.sh\n"

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
		netstat -lant | grep -w $i
		if [ $? -eq 0 ];
		then
			printf $warning "\nAnother process is still using port $i. Either wait or use 'sudo netstat -plant' to find it, then 'ps aux' to get the PID and 'kill PID' to stop it and try again\n"
			exit 0
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
	printf $danger "Failed to remove the tak folder. You will need to do this as sudo: sudo ./scripts/cleanup.sh\n"
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

# ifconfig?
export PATH=$PATH:/sbin
if ! command -v ifconfig
then
	printf $danger "\nRTFM: You need net-tools: apt-get install net-tools\n"
	exit 1
fi

# unzip or 7z?
if ! command -v unzip
then
	if ! command -v 7z
	then
		printf $danger "\n .----------------.  .----------------.  .----------------.  .----------------.\n" 
		printf $danger "| .--------------. || .--------------. || .--------------. || .--------------. |\n"
		printf $danger "| |  _______     | || |  _________   | || |  _________   | || | ____    ____ | |\n"
		printf $danger "| | |_   __ \    | || | |  _   _  |  | || | |_   ___  |  | || ||_   \  /   _|| |\n"
		printf $danger "| |   | |__) |   | || | |_/ | | \_|  | || |   | |_  \_|  | || |  |   \/   |  | |\n"
		printf $danger "| |   |  __ /    | || |     | |      | || |   |  _|      | || |  | |\  /| |  | |\n"
		printf $danger "| |  _| |  \ \_  | || |    _| |_     | || |  _| |_       | || | _| |_\/_| |_ | |\n"
		printf $danger "| | |____| |___| | || |   |_____|    | || | |_____|      | || ||_____||_____|| |\n"
		printf $danger "| |              | || |              | || |              | || |              | |\n"
		printf $danger "| '--------------' || '--------------' || '--------------' || '--------------' |\n"
		printf $danger " '----------------'  '----------------'  '----------------'  '----------------' \n"
		printf $danger "You require either unzip OR 7z to decompress the TAK release\n"
		printf $danger "https://github.com/Cloud-RF/tak-server/blob/main/README.md\n"
		exit 1
	else
		7z x $release.zip -o/tmp/takserver
	fi
else
	unzip $release.zip -d /tmp/takserver
fi

if [ ! -d "/tmp/takserver/$release/tak" ] 
then
	printf $danger "\n .----------------.  .----------------.  .----------------.  .----------------.\n" 
	printf $danger "| .--------------. || .--------------. || .--------------. || .--------------. |\n"
	printf $danger "| |  _______     | || |  _________   | || |  _________   | || | ____    ____ | |\n"
	printf $danger "| | |_   __ \    | || | |  _   _  |  | || | |_   ___  |  | || ||_   \  /   _|| |\n"
	printf $danger "| |   | |__) |   | || | |_/ | | \_|  | || |   | |_  \_|  | || |  |   \/   |  | |\n"
	printf $danger "| |   |  __ /    | || |     | |      | || |   |  _|      | || |  | |\  /| |  | |\n"
	printf $danger "| |  _| |  \ \_  | || |    _| |_     | || |  _| |_       | || | _| |_\/_| |_ | |\n"
	printf $danger "| | |____| |___| | || |   |_____|    | || | |_____|      | || ||_____||_____|| |\n"
	printf $danger "| |              | || |              | || |              | || |              | |\n"
	printf $danger "| '--------------' || '--------------' || '--------------' || '--------------' |\n"
	printf $danger " '----------------'  '----------------'  '----------------'  '----------------' \n"
	printf $danger "A decompressed folder was NOT found at /tmp/takserver/$release\n"
	printf $danger "https://github.com/Cloud-RF/tak-server/blob/main/README.md\n"
	exit 1
fi

mv -f /tmp/takserver/$release/tak ./
chown -R $USER:$USER tak

# This config uses a docker alias of postgresql://tak-database:5432/
cp ./CoreConfig.xml ./tak/CoreConfig.xml

## Set admin username and password and ensure it meets validation criteria
user="admin"
pwd=$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-11} | head -n 1)
password=$pwd"Meh1!"

## Set postgres password and ensure it meets validation criteria
pgpwd="$(cat /dev/urandom | tr -dc '[:alpha:][:digit:]' | fold -w ${1:-11} | head -n 1)"
pgpassword=$pgpwd"Meh1!"

# get IP
NIC=$(route | grep default | awk '{print $8}' | head -n 1)
IP=$(ip addr show $NIC | grep -m 1 "inet " | awk '{print $2}' | cut -d "/" -f1)

printf $info "\nProceeding with IP address: $IP\n"
sed -i "s/password=\".*\"/password=\"${pgpassword}\"/" tak/CoreConfig.xml
# Replaces HOSTIP for rate limiter and Fed server. Database URL is a docker alias of tak-database
sed -i "s/HOSTIP/$IP/g" tak/CoreConfig.xml

# Replaces takserver.jks with $IP.jks
sed -i "s/takserver.jks/$IP.jks/g" tak/CoreConfig.xml

# Better memory allocation:
# By default TAK server allocates memory based upon the *total* on a machine. 
# In the real world, people not on a gov budget use a server for more than one thing.
# Instead we allocate a fixed amount of memory
#read -p "Enter the amount of memory to allocate, in kB. Default 4000000 (4GB): " mem
if [ -z "$mem" ];
then
	mem="4000000"
fi

sed -i "s%\`awk '/MemTotal/ {print \$2}' /proc/meminfo\`%$mem%g" tak/setenv.sh

# Commented out since everyone just kept hitting enter x4. dumb=dumb

## Set variables for generating CA and client certs
#printf $warning "SSL setup. Hit enter (x4) to accept the defaults:\n"
#read -p "Country (for cert generation). Default [US] : " country
#read -p "State (for cert generation). Default [state] : " state
#read -p "City (for cert generation). Default [city]: " city
#read -p "Organizational Unit (for cert generation). Default [org]: " orgunit

if [ -z "$country" ];
then
	country="GB"
fi

if [ -z "$state" ];
then
	state="Warwickshire"
fi

if [ -z "$city" ];
then
	city="Coventry" # British joke
fi

if [ -z "$orgunit" ];
then
	orgunit="TAK"
fi

# Update local env
export COUNTRY=$country
export STATE=$state
export CITY=$city
export ORGANIZATIONAL_UNIT=$orgunit


# Writes variables to a .env file for docker-compose
cat << EOF > .env
COUNTRY=$country
STATE=$state
CITY=$city
ORGANIZATIONAL_UNIT=$orgunit
EOF

### Update cert-metadata.sh with configured country. Fallback to US if variable not set.
sed -i -e 's/COUNTRY=US/COUNTRY=${COUNTRY}/' $PWD/tak/certs/cert-metadata.sh


### Runs through setup, starts both containers
$DOCKER_COMPOSE --file $DOCKERFILE up  --force-recreate -d

### Checking if the container is set up and ready to set the certificates

while :
do
	sleep 5 # let the PG stderr messages conclude...
	printf $warning "------------CERTIFICATE GENERATION--------------\n"
	$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeRootCa.sh --ca-name CRFtakserver"
	if [ $? -eq 0 ];
	then
		$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh server $IP"
		if [ $? -eq 0 ];
		then
			$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh client $user"	
			if [ $? -eq 0 ];
			then
				# Set permissions so user can write to certs/files
				# The ubuntu user has uid 1000 which should map to our host user id 1000. Type 'id' to find yours :)
				$DOCKER_COMPOSE exec tak bash -c "chown -R 1000:1000 /opt/tak/certs/"
				#$DOCKER_COMPOSE stop tak
				break
			fi
		else
			sleep 5
		fi
	fi
done

printf $info "Creating certificates for 2 users in tak/certs/files for a quick setup via TAK's import function\n"

# Make 2 users
$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh client user1"
$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/certs && ./makeCert.sh client user2"
$DOCKER_COMPOSE exec tak bash -c "chown -R 1000:1000 /opt/tak/certs/"

./scripts/certDP.sh $IP user1
./scripts/certDP.sh $IP user2

printf $info "Waiting for TAK server to connect to DB. This should loop several times only...\n"
#$DOCKER_COMPOSE start tak
sleep 5

### Checks if java is fully initialised
while :
do
	sleep 5
	$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/ && java -jar /opt/tak/utils/UserManager.jar usermod -A -p $password $user"
	if [ $? -eq 0 ];
	then
		$DOCKER_COMPOSE exec tak bash -c "cd /opt/tak/ && java -jar utils/UserManager.jar certmod -A certs/files/$user.pem"
		if [ $? -eq 0 ]; 
		then
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
		printf $info "No joy with DB at $IP, will retry in 5s. If this loops more than 10 times give up.\n" 
	fi
done

cp ./tak/certs/files/$user.p12 .

### Post-installation message to user including randomly generated passwrods to use for account and PostgreSQL
docker container ls

printf $warning "\n\nImport the $user.p12 certificate from this folder to your browser's certificate store as per the README.md file\n"
printf $success "Login at https://$IP:8443 with your admin account. No need to run the /setup step as this has been done.\n" 
printf $info "Certificates and .zip data packages are in tak/certs/files \n\n" 
printf $success "Setup script sponsored by CloudRF.com - \"The API for RF\"\n\n"
printf $danger "---------PASSWORDS----------------\n\n"
printf $danger "Admin user name: $user\n" # Web interface default user name
printf $danger "Admin password: $password\n" # Web interface default random password created during setup
printf $danger "PostgreSQL password: $pgpassword\n\n" # PostgreSQL password randomly generated during set up
printf $danger "---------PASSWORDS----------------\n\n"
printf $warning "MAKE A NOTE OF YOUR PASSWORDS. THEY WON'T BE SHOWN AGAIN.\n"
printf $info "Docker containers should automatically start with the Docker service from now on.\n"
