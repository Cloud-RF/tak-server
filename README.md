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

| Release filename                             | Bytes | MD5 | SHA1 |
| ----------------------------------- | -- | -- | -- |
| takserver-docker-4.6-RELEASE-26.zip |  462381384 | dc63cb315f950025707dbccf05bdf183 | 7ca58221b8d35d40df906144c5834e6d9fa85b47 |
| takserver-docker-4.7-RELEASE-4.zip | 759385093 | 5b011b74dd5f598fa21ce8d737e8b3e6 | b688359659a05204202c21458132a64ec1ba0184 |
| takserver-docker-4.7-RELEASE-18.zip | 759410768 | 44b6fa8d7795b56feda08ea7ab793a3e | cd56406d3539030ab9b9b3fbae08b56b352b9b53 |



## Requirements
- Docker
- A TAK server release
- 4GB memory
- Network connection 

## Installation
Fetch the git repo and cd into the directory

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

    8443, 8444, 8446, 8087, 8088, 8089, 9000, 9001, 8080

If you are going to expose these ports be careful. Not all of them run secure protocols. For piece of mind, and for working through firewalls and NAT routers run this on a VPN like OpenVPN or NordVPN. 


## Admin login
Use your new random admin login to access the interface in a web browser at:

    http://localhost:8080

A successful login will trigger an old security warning which you can ignore as this software is now open source.

![meh](img/warning.jpg "A warning")

### Logging
You can access a shell in the running docker container with this command:

    docker exec -it tak-server_tak_1 /bin/bash

To tail the server log from inside the container:

    tail -f /opt/tak/logs/takserver.log

### Changing the logo at the footer of the web page

The logo can be changed **without** stopping or setting up the TAK Server again.

![meh](img/banana.png "A banana")

The script takes one command line argument which is the full path to the **PNG** or **JPG** image of new logo. Sudo permission may not be needed depending on your docker permissions.

```
chmod +x scripts/logo-replacement.sh
sudo ./scripts/logo-replacement.sh /home/eric/banana.jpg
````

The script will check for all dependencies required, and if not present, the script will attempt to install them for you. The dependencies needed are __*openJDK*__ (JAVA environment is required to be able to repack the jar correctly) and ImageMagick for conversion.

## Administration and support

You can find the PDF manual in the tak/docs folder and get help from *community volunteers* via the TAK Discord server. If you ask a bone FAQ already covered in the manual, or demand urgent assistance, expect to get some grief. **RTFM and be patient**.

### Clean up
```
sudo ./scripts/cleanup.sh
```

This script will stop the TAK Server container, remove the mapped database volume and remove the folder "tak" which is created in the project root directory (cloned from github) during the setup process. 

WARNING: If you have data in an existing TAK database container it will be lost.

 ## Known issues
  ### Loads of repeat java exceptions eg java.lang.RuntimeException...
One or two is expected behaviour due to the time the backend processes take to start up. If you get lots or it's still ongoing after 2 minutes, run the cleanup script as sudo to prune stale images.

  ### Failed to initialize pool: Connection to tak-database:5432 refused
This indicates a docker network issue. Run the clean up script as sudo to prune stale networks.

 ### The login screen doesn't take my password?
 Just wait a minute or two. This is expected behaviour due to the time the backend processes take to start up.

 ### Running the /setup wizard breaks the database?
 This script **is the wizard** so it gets you past the setup wizard (Section 4.4 in the configuration guide) and populates the database tables. Only run the wizard if you know what you're doing as **this will break your database connection** - at which point you should set this up the hard way.

### ERROR: could not find an available, non-overlapping IPv4 address pool among the defaults to assign to the network
Stop your vpn, prune your networks
```
service openvpn stop
docker network prune
```

## My custom logo doesn't show up
If the script ran as sudo and completed ok, refresh your browser's cache with Ctrl-F5

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

