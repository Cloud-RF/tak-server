# TAK server

## About
![alt text](img/tak.jpg "TAK logo")

This is a docker wrapper for an official 'OG' TAK server from Tak Product Center. It will give you a turnkey TAK server with SSL.


## Download a TAK release
Before you can build this, you must download a TAKSERVER-DOCKER-X.X-RELEASE 

Releases are now public at https://tak.gov/products/tak-server
Please follow account registration process, and once completed go to the link above. 

![alt text](img/tak-server-download.jpg "TAK release download")


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

### AMD64 setup

```
cd tak-server
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup.sh script will ppopulate config files, start up TAK server with a POSTGRES database via docker-compose, and generate the required certificates.There will be prompts and some inputs required from user such as certificate names.
At the end of the setup user will be given the information how to access the web interface where further settings can be applied.

### TCP/IP ports
TAK server needs the following port numbers to operate. Services already using these will cause a problem which the script will detect and offer a resolution for.

    8443, 8444, 8446, 8087, 8088, 9000, 9001, 8080

## Passwords
The Java setup **can take several minutes**. Please be patient. When it's done you will be shown random passwords which you need to login. You can change these later from the admin interface.

![alt text](img/takserverpasswords.jpg "TAK server passwords")

## Login
Use your admin login to access the interface in a web browser at:

    http://localhost:8080

If it hangs, reload the page after a minute and expect a big scary legal warning about US Gov export controls on a piece of open source software. Be confused for a second and then click ok...

### ARM64 setup
```
cd tak-server
chmod +x scripts/setup.sh
./scripts/setup-arm.sh
```

The script for arm64 architecture follows the same steps as in the case of amd64 architecture, therefore for more details please refer to above

### Clean up
```
./scripts/cleanup.sh
```

This script will stop the TAK Server container, remove the mapped volumes, and remove the folder "tak" which normally is created in project root directory (cloned directory from git) during setup process. 

## Contributing
Please feel free to open merge requests. A beginner's guide to github.com is here:

 https://www.freecodecamp.org/news/how-to-make-your-first-pull-request-on-github-3/

## Authors and acknowledgment
Thanks to the TAK product center for open-sourcing and maintaining all things TAK. 

Thanks to James Wu 'wubar' on gitlab/Discord for publishing the docker wrapper on which this was built.

Thanks to protectionist dinosaurs, on both sides of the pond, who are threatened by TAK's open source model for the motivation :p