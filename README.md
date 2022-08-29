# TAK SERVER

![meh](img/tak.jpg "TAK logo")

This is a docker wrapper for an official 'OG' TAK server from [TAK Product Center](https://tak.gov/) intended for beginners. It will give you a turnkey TAK server with SSL which works with ATAK, iTAK, WinTAK.

The key improvements are:
 - Automatic configuration 
 - Certificate generation
 - Secure password generation
 - Updates postgres10 to postgres14
 - Updates debian 8 to debian 11

## IMPORTANT: Download the official TAK release
Before you can build this, you must download a **TAKSERVER-DOCKER-X.X-RELEASE** 

The scripts in this repository **have not** been checked against *TAKSERVER-DOCKER-HARDENED-X.X-RELEASE*, so please **do not** use them with that version of TAK Server.

Releases are now public at https://tak.gov/products/tak-server

Please follow account registration process, and once completed go to the link above. 
The integrity of the release will be checked at setup against the MD5/SHA1 checksums in this repo. These must match. If they do not match, DO NOT proceed unless you trust the release. 

![meh](img/tak-server-download.jpg "TAK release download")

## TAK server release checksums
The size blew up after 4.6 due to 900GB of DTED which was added to webtak.

| Release filename                             | Bytes | MD5 | SHA1 |
| ----------------------------------- | -- | -- | -- |
| takserver-docker-4.6-RELEASE-26.zip |  462381384 | dc63cb315f950025707dbccf05bdf183 | 7ca58221b8d35d40df906144c5834e6d9fa85b47 |
| takserver-docker-4.7-RELEASE-4.zip | 759385093 | 5b011b74dd5f598fa21ce8d737e8b3e6 | b688359659a05204202c21458132a64ec1ba0184 |
| takserver-docker-4.7-RELEASE-18.zip | 759410768 | 44b6fa8d7795b56feda08ea7ab793a3e | cd56406d3539030ab9b9b3fbae08b56b352b9b53 |
| takserver-docker-4.7-RELEASE-20.zip | 759389907 | 1cb0208c62d4551f1c3185d00a5fd8bf | f427ae3e860fddb8907047f157ada5764334c48d |


## Requirements
- Docker
- A TAK server release
- 4GB memory
- Network connection 
- unzip and netstat utilities

## Installation
Fetch the dependencies, then the git repo and cd into the directory

    apt-get install docker-compose unzip net-tools
    git clone https://github.com/Cloud-RF/tak-server.git
    cd tak-server

### Docker security

These scripts assume you don't need to sudo for `docker` and `docker-compose`.
Run as root if needed, however please have in mind that the container might be set up as _privileged container_, and for security reasons we do not recommend that.
See https://docs.docker.com/engine/install/linux-postinstall/ for details.

You can also chown the docker.sock file which isn't as recommended, but works.

    sudo chown $USER /var/run/docker.sock

### AMD64 & ARM64 (Pi4) setup 
The script will auto-detect your architecture and use the arm docker file if arch == arm64

```
cd tak-server
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup.sh script will populate config files, start up TAK server with a POSTGRES database via docker-compose and generate the required certificates.There will be prompts and some input required from the user such as certificate names. At the end of the setup the user will be given random passwords and a link to access the web interface where further settings can be applied.

For more information on using TAK server refer to [the docs on the TPC Github](https://github.com/TAK-Product-Center/Server/tree/main/src/docs).

### Network ports
TAK server needs the following port numbers to operate. Services already using these will cause a problem which the script will detect and offer a resolution for. If you're running as sudo it can kill the processes.

    8443, 8444, 8446, 8089, 9000, 9001

If you are going to expose these ports be careful. Not all of them run secure protocols. For piece of mind, and for working through firewalls and NAT routers run this on a VPN like OpenVPN or NordVPN. 


## Admin login

The login to the web interface requires the certificate created during setup. The certificate needs to be uploaded to the browser first. The name of this certificate is the one which you have typed after specifying the State, City, Company during the certificate creation. Default is admin.p12. The certificates names can be checked by:

```bash
docker exec -it tak-server_tak_1 bash 
ls /opt/tak/certs/files
exit
```

## Installing your admin Certificate

The admin.p12 certificate needs to be copied from ./tak/certs/files/ and installed in a web browser. This not only provides TLS transport security with mutual authentication (Client > Server, Server > Client) but it proves your identity and saves you having to type a tedious password each time.


**Chrome**

* Go to **"Settings"** --> **"Privacy and Security"** --> **"Security"** --> **"Manage Certificates"**
* Navigate to **"Your certificates"** 
* Press **"Import"** button and choose your *".p12"* file (pw atakatak)

The web UI should be now accessible via the address given below.

**Firefox**

* Go to **"Settings"** --> **"Privacy & Security"** --> scroll down to **"Certificates"** section.
* Click the button **"View Certificates"**
* Choose **"Your Certificates"** section and **"Import"** your *".p12"* certificate (pw atakatak)
* Choose the **"Authorities"** section
* Locate **"TAK"** line, there should be your certificate name displayed underneath it
* Click your certificate name and press button **"Edit Trust"**
* __*TICK*__ the box with **"This certificate can identify web sites"** statement, then click **"OK"**

## Web UI access
The web user interface can be only accessed via **SSL** on port **8443**.

The login prompt will not show up as the server authenticates the user based on the uploaded certificate.

The user interface is available at the below address and on all other NICs. Check your firewall as you may not want this exposed on a public NIC.

    https://localhost:8443

### Re-starting Server after shutdown
Make sure you are in the main __*"tak-server"*__ folder and append the -d flag to background the process.

```
cd tak-server
docker-compose up -d
```

### Shutting down running TAK server
Make sure you are in the main __*"tak-server"*__ folder.

```
cd tak-server
docker-compose down
```

### Logging
You can access a shell in the running docker container with this command:

    docker exec -it tak-server_tak_1 /bin/bash

To tail the server log from inside the container:

    tail -f /opt/tak/logs/takserver.log

To tail the server log from *outside* the container as the tak folder is mapped:

    tail -f ./tak/logs/takserver.log

### Clean up
```
sudo ./scripts/cleanup.sh
```

This script will stop the TAK Server container, remove the mapped database volume and remove the folder "tak" which is created in the project root directory (cloned from github) during the setup process. 

WARNING: If you have data in an existing TAK database container it will be lost.

# FAQ
See [Frequently asked questions](FAQ.md)

## Contributing
Please feel free to open merge requests. A beginner's guide to github.com is here:

 https://www.freecodecamp.org/news/how-to-make-your-first-pull-request-on-github-3/

## Authors and acknowledgment
Thanks to the TAK product center for open-sourcing and maintaining all things TAK. 

Thanks to James Wu 'wubar' on gitlab/Discord for publishing the docker wrapper on which this was built.

Thanks to protectionist dinosaurs, on both sides of the pond, who are threatened by TAK's open source model for the motivation :p

## Useful links

[TAK server on TAK.gov](https://tak.gov/products/tak-server)

[ATAK-CIV on Google Play](https://play.google.com/store/apps/details?id=com.atakmap.app.civ&hl=en_GB&gl=US)

[iTak on Apple App store](https://apps.apple.com/my/app/itak/id1561656396)

[WinTAK-CIV on TAK.gov](https://tak.gov/products/wintak-civ)

