# Tak Server in Docker

Clone the repository to the destination of your choice.

## Available Architectures
* amd64
* arm64

## Requirements
The set up calls for release file which is zipped. The release file can be downloaded from https://tak.gov/products/tak-server.
In order to download the latest and some previous releases the account is needed. Follow account registration process. Once completed go to the link above.
From the releases make sure that the DOCKER release is downloaded to the CLONED project directory.

## Quickstart 
**These scripts assume you don't need to sudo for `docker` and `docker-compose`.**
Run as root if needed, however please have in mind that the container might be set up as _privileged container_, and for security reasons we do not recommend that.
See https://docs.docker.com/engine/install/linux-postinstall/ for details.

### AMD64
```
./scripts/setup.sh
```
**This script is for amd64 architecture.**

The setup.sh script will go through healthchecks and steps neccessary to set up the TAK Server container. There will be prompts and some inputs required from user, although we did try to minimize that.
At the end of the setup user will be given the information how to access the web interface where further settings can be applied.

#### Details
**Healthchecks**
* Checking if ports 8443, 8444, 8446, 8087, 8088, 9000, 9001, 8080 are free
* Checking if the tak directory in the project root directory (cloned directory from git) already exists, if so informs user about the fact that it will get overriden and gives a choice of action,
* Checking if release file is present in the root directory (cloned directory from git) of the project,
* The script will calculate a checksum for the release file and then verify the checksum against the correct checksums provided. Will inform user if the checksum failed and ask for the action to perform.
* There are checks incorporated to this script which make sure that certain services are running inside the docker container once its started so further step can be performed.

**Setup Time**
The setup might take some time and it will depend on the hardware user is using.


### ARM64 (32-bit isn't supported)
```
. scripts/setup-arm.sh
```
Configure the rest through http://localhost:8080

## The Details
This project seeks to streamline the instructions in TAK server's offical docs to build and configure TAK server using Docker.

The setup script will populate config files, start up TAK server and the POSTGRES database via docker-compose, and generate the required certs.

Admin user configuration may fail if the TAK server hasn't finished starting up. If this happens, you'll need to re-run the setup script or just lines 64 and 65.

## Contributing
Please feel free to open merge requests. The setup script can definitely be improved at the the very least.

## Authors and acknowledgment
Shoutout to the TAK server team for creating the core project and open-sourcing it!