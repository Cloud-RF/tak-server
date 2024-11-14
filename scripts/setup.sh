#!/usr/bin/env bash

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


printf "%s\n" "$success" "\nTAK server setup script sponsored by CloudRF.com - \"The API for RF\"\n"
printf "%s\n" "$info" "\nStep 1. Download the official docker image as a zip file from https://tak.gov/products/tak-server \nStep 2. Place the zip file in this tak-server folder.\n"
# printf "%s\n" "$warning" "\nYou should install this as a user. Elevated privileges (sudo) are only required to clean up a previous install eg. sudo ./scripts/cleanup.sh\n"

arch=$(dpkg --print-architecture)

DOCKERFILE=docker-compose.yml

if [ "$arch" == "arm64" ]; then
    DOCKERFILE="docker-compose.arm.yml"
    printf "%s\n" "$info" "Building for arm64..."
fi



### Check if required ports are in use by anything other than docker
netstat_check () {
	
	ports=(5432 8089 8443 8444 8446 9000 9001)
	
	for i in "${ports[@]};"
	do
		netstat -lant | grep -w $i
		if [ $? -eq 0 ];
		then
			printf "%s\n" "$warning" "\nAnother process is still using port $i. Either wait or use 'sudo netstat -plant' to find it, then 'ps aux' to get the PID and 'kill PID' to stop it and try again\n"
			exit 0
		else
			printf "%s\n" "$success" "\nPort $i is available.."
		fi
	done
	
}

tak_folder () {
	### Check if the folder "tak" exists after previous install or attempt and remove it or leave it for the user to decide
	if [ -d "./tak" ] 
	then
	    printf "%s\n" "$warning" "\nDirectory 'tak' already exists. This will be removed along with the docker volume, do you want to continue? (y/n): "
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
		printf "%s\n" "$warning" "SECURITY WARNING: Make sure the checksums match! You should only download your release from a trusted source eg. tak.gov:\n"
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
			printf "%s\n" "$danger" "SECURITY WARNING: The file is either different OR is not listed in the known releases.\nDo you really want to continue with this setup? (y/n): "
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
			printf "%s\n" "$danger" "SECURITY WARNING: The checksum is not correct, so the file is different. Do you really want to continue with this setup? (y/n): "
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
		printf "%s\n" "$danger" "\n\tPlease download the release of docker image as per instructions in README.md file. Exiting now...\n\n"
		sleep 1
		exit 0
	fi
}

netstat_check
tak_folder
if [ -d "tak" ] 
then
	printf "%s\n" "$danger" "Failed to remove the tak folder. You will need to do this as sudo: sudo ./scripts/cleanup.sh\n"
	exit 0
fi
checksum

# The actual container setup starts here

### Vars

release=$(ls -hl *.zip | awk '{print $9}' | cut -d. -f -2)

printf "%s\n" "$warning" "Pausing to let you know release version $release will be setup in 5 seconds."
printf "%s\n" "$warning" "If this is wrong, hit Ctrl-C now..."

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
	printf "%s\n" "$danger" "RTFM: You need net-tools: apt-get install net-tools"
	exit 1
fi

# unzip or 7z?
if ! command -v unzip
then
	if ! command -v 7z
	then
		printf "%s\n" "$danger" ""
		printf "%s\n" "$danger" " .----------------.  .----------------.  .----------------.  .----------------."
		printf "%s\n" "$danger" "| .--------------. || .--------------. || .--------------. || .--------------. |"
		printf "%s\n" "$danger" "| |  _______     | || |  _________   | || |  _________   | || | ____    ____ | |"
		printf "%s\n" "$danger" "| | |_   __ \    | || | |  _   _  |  | || | |_   ___  |  | || ||_   \  /   _|| |"
		printf "%s\n" "$danger" "| |   | |__) |   | || | |_/ | | \_|  | || |   | |_  \_|  | || |  |   \/   |  | |"
		printf "%s\n" "$danger" "| |   |  __ /    | || |     | |      | || |   |  _|      | || |  | |\  /| |  | |"
		printf "%s\n" "$danger" "| |  _| |  \ \_  | || |    _| |_     | || |  _| |_       | || | _| |_\/_| |_ | |"
		printf "%s\n" "$danger" "| | |____| |___| | || |   |_____|    | || | |_____|      | || ||_____||_____|| |"
		printf "%s\n" "$danger" "| |              | || |              | || |              | || |              | |"
		printf "%s\n" "$danger" "| '--------------' || '--------------' || '--------------' || '--------------' |"
		printf "%s\n" "$danger" " '----------------'  '----------------'  '----------------'  '----------------' "
		printf "%s\n" "$danger" "You require either unzip OR 7z to decompress the TAK release"
		printf "%s\n" "$danger" "https://github.com/Cloud-RF/tak-server/blob/main/README.md"
		exit 1

	else
		7z x $release.zip -o/tmp/takserver
	fi
else
	unzip $release.zip -d /tmp/takserver
fi

if [ ! -d "/tmp/takserver/$release/tak" ] 
then
	printf "%s\n" "$danger" ""
	printf "%s\n" "$danger" " .----------------.  .----------------.  .----------------.  .----------------."
	printf "%s\n" "$danger" "| .--------------. || .--------------. || .--------------. || .--------------. |"
	printf "%s\n" "$danger" "| |  _______     | || |  _________   | || |  _________   | || | ____    ____ | |"
	printf "%s\n" "$danger" "| | |_   __ \    | || | |  _   _  |  | || | |_   ___  |  | || ||_   \  /   _|| |"
	printf "%s\n" "$danger" "| |   | |__) |   | || | |_/ | | \_|  | || |   | |_  \_|  | || |  |   \/   |  | |"
	printf "%s\n" "$danger" "| |   |  __ /    | || |     | |      | || |   |  _|      | || |  | |\  /| |  | |"
	printf "%s\n" "$danger" "| |  _| |  \ \_  | || |    _| |_     | || |  _| |_       | || | _| |_\/_| |_ | |"
	printf "%s\n" "$danger" "| | |____| |___| | || |   |_____|    | || | |_____|      | || ||_____||_____|| |"
	printf "%s\n" "$danger" "| |              | || |              | || |              | || |              | |"
	printf "%s\n" "$danger" "| '--------------' || '--------------' || '--------------' || '--------------' |"
	printf "%s\n" "$danger" " '----------------'  '----------------'  '----------------'  '----------------' "
	printf "%s\n" "$danger" "A decompressed folder was NOT found at /tmp/takserver/$release"
	printf "%s\n" "$danger" "https://github.com/Cloud-RF/tak-server/blob/main/README.md"
	exit 1
fi

mv -f /tmp/takserver/$release/tak ./
chown -R $USER:$USER tak

# Not needed since they fixed the crappy configs in 5.x

#cp ./scripts/configureInDocker1.sh ./tak/db-utils/configureInDocker.sh
#cp ./postgresql1.conf ./tak/postgresql.conf
#cp ./scripts/takserver-setup-db-1.sh ./tak/db-utils/takserver-setup-db.sh

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

printf "%s\n" "$info" "\nProceeding with IP address: $IP\n"
sed -i "s/password=\".*\"/password=\"${pgpassword}\"/" tak/CoreConfig.xml
# Replaces HOSTIP for rate limiter and Fed server. Database URL is a docker alias of tak-database
sed -i "s/HOSTIP/$IP/g" tak/CoreConfig.xml

# Replaces takserver.jks with $IP.jks
sed -i "s/takserver.jks/$IP.jks/g" tak/CoreConfig.xml

# Better memory allocation:
# By default TAK server allocates memory based upon the *total* on a machine. 
# In the real world, people not on a gov budget use a server for more than one thing.
# Instead we allocate a fixed amount of memory
read -p "Enter the amount of memory to allocate, in kB. Default 4000000 (4GB): " mem
if [ -z "$mem" ];
then
	mem="4000000"
fi

sed -i "s%\`awk '/MemTotal/ {print \$2}' /proc/meminfo\`%$mem%g" tak/setenv.sh

## Set variables for generating CA and client certs
printf "%s\n" "$warning" "SSL setup. Hit enter (x4) to accept the defaults:\n"
read -p "Country (for cert generation). Default [US] : " country
read -p "State (for cert generation). Default [state] : " state
read -p "City (for cert generation). Default [city]: " city
read -p "Organizational Unit (for cert generation). Default [org]: " orgunit

if [ -z "$country" ];
then
	country="US"
fi

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
sed -i -e 's/COUNTRY=US/COUNTRY=${COUNTRY:-US}/' $PWD/tak/certs/cert-metadata.sh

### Runs through setup, starts both containers
$DOCKER_COMPOSE --file $DOCKERFILE up  --force-recreate -d

### Checking if the container is set up and ready to set the certificates

while :
do
	sleep 10 # let the PG stderr messages conclude...
	printf "%s\n" "$warning" "------------CERTIFICATE GENERATION--------------"
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
				$DOCKER_COMPOSE exec tak bash -c "useradd $USER && chown -R $USER:$USER /opt/tak/certs/"
				$DOCKER_COMPOSE stop tak
				break
			else 
				sleep 5
			fi
		else
			sleep 5
		fi
	fi
done

printf "%s\n" "$info" "Creating certificates for 2 users in tak/certs/files for a quick setup via TAK's import function\n"

# Make 2 users
cd tak/certs
./makeCert.sh client user1
./makeCert.sh client user2


# Make 2 data packages
cd ../../
./scripts/certDP.sh $IP user1
./scripts/certDP.sh $IP user2

printf "%s\n" "$info" "Waiting for TAK server to go live. This should take <1m with an AMD64, ~2min on an ARM64 (Pi)"
$DOCKER_COMPOSE start tak
sleep 10

### Checks if java is fully initialised
while :
do
	sleep 10
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
				sleep 10
			fi
		else
			sleep 10
		fi
	else
		printf "%s\n" "$info" "No joy with DB at $IP, will retry in 10s. If this loops more than 6 times, go and get some fresh air..." 
	fi
done

cp ./tak/certs/files/$user.p12 .

### Post-installation message to user including randomly generated passwrods to use for account and PostgreSQL
docker container ls

printf "%s\n\n" "$warning" "Import the $user.p12 certificate from this folder to your browser as per the README.md file"
printf "%s\n" "$success" "Login at https://$IP:8443 with your admin account. No need to run the /setup step as this has been done."
printf "%s\n\n" "$info" "Certificates and *CERT DATA PACKAGES* are in tak/certs/files"
printf "%s\n\n" "$success" "Setup script sponsored by CloudRF.com - \"The API for RF\""
printf "%s\n\n" "$danger" "---------PASSWORDS----------------"
printf "%s\n" "$danger" "Admin user name: $user" # Web interface default user name
printf "%s\n" "$danger" "Admin password: $password" # Web interface default random password created during setup
printf "%s\n\n" "$danger" "PostgreSQL password: $pgpassword" # PostgreSQL password randomly generated during setup
printf "%s\n\n" "$danger" "---------PASSWORDS----------------"
printf "%s\n" "$warning" "MAKE A NOTE OF YOUR PASSWORDS. THEY WON'T BE SHOWN AGAIN."
printf "%s\n" "$warning" "You have a database listening on TCP 5432 which requires a login. You should still block this port with a firewall"
printf "%s\n" "$info" "Docker containers should automatically start with the Docker service from now on."
