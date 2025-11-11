# TAK Server Quick Start

This guide will help you get your TAK Server up and running quickly.

## Step 1: Check System Readiness

Run the readiness checker to see if your system is ready:

```bash
./check-ready.sh
```

This will check:
- Docker installation
- Docker Compose installation
- Docker daemon status
- Required utilities (unzip, netstat, ifconfig)
- TAK Server release file presence
- Port availability
- Disk space
- Available memory

## Step 2: Download TAK Server Release (if needed)

If you don't have a release file yet:

1. Visit **https://tak.gov/products/tak-server**
2. Create an account / login
3. Download one of these releases:
   - `takserver-docker-5.2-RELEASE-43.zip` (Latest - 517MB) ⭐ Recommended
   - `takserver-docker-5.1-RELEASE-50.zip` (615MB)
   - `takserver-docker-5.0-RELEASE-58.zip` (660MB)
4. Place the ZIP file in the `tak-server` directory

## Step 3: Run Setup

Once your system is ready and the ZIP file is in place:

```bash
./scripts/setup.sh
```

### During Setup

You'll be asked for:

1. **Memory allocation** (default: 4GB)
   ```
   Enter the amount of memory to allocate, in kB. Default 4000000 (4GB):
   ```
   Press Enter to accept the default.

2. **Certificate information** (for SSL):
   ```
   Country (for cert generation). Default [US]:
   State (for cert generation). Default [state]:
   City (for cert generation). Default [city]:
   Organizational Unit (for cert generation). Default [org]:
   ```
   Press Enter for each to accept defaults, or enter your values.

The setup will take 5-10 minutes depending on your system.

## Step 4: Save Your Passwords

At the end of setup, you'll see:

```
---------PASSWORDS----------------

Admin user name: admin
Admin password: <RANDOM_PASSWORD>
Postgresql password: <RANDOM_PASSWORD>

---------PASSWORDS----------------

MAKE A NOTE OF YOUR PASSWORDS. THEY WON'T BE SHOWN AGAIN.
```

**⚠️ IMPORTANT**: Copy and save these passwords securely!

## Step 5: Install Admin Certificate

To access the web interface, install the admin certificate in your browser:

### The certificate file
The `admin.p12` file is in the project root directory.
Default password: `atakatak`

### Chrome / Edge
1. Settings → Privacy and Security → Security
2. Manage Certificates → Your certificates
3. Import → Select `admin.p12`
4. Enter password: `atakatak`

### Firefox
1. Settings → Privacy & Security → Certificates → View Certificates
2. Your Certificates tab → Import
3. Select `admin.p12` and enter password
4. Go to Authorities tab → Find "TAK" → Edit Trust
5. Check "This certificate can identify web sites" → OK

## Step 6: Access Web Interface

Open your browser and navigate to:

```
https://YOUR_IP_ADDRESS:8443
```

You'll be automatically authenticated with your certificate!

## Step 7: Connect Mobile Devices

Data packages for ATAK/iTAK devices are ready:

```
tak/certs/files/user1-YOUR_IP.dp.zip
tak/certs/files/user2-YOUR_IP.dp.zip
```

### To connect a device:

1. Copy a data package to your device's storage
2. Open ATAK or iTAK
3. Go to Settings → Import
4. Select "Local SD"
5. Choose the `.dp.zip` file
6. The server connection will be configured automatically!

## Managing Your Server

### Start the server
```bash
docker compose up -d
```

### Stop the server
```bash
docker compose down
```

### View logs
```bash
tail -f tak/logs/takserver.log
```

### Check container status
```bash
docker ps
```

## Troubleshooting

### "Port already in use"
Find and stop the process using the port:
```bash
sudo netstat -plant | grep <PORT>
sudo kill <PID>
```

### "Docker daemon not running"
Start Docker:
```bash
sudo systemctl start docker
# or
sudo service docker start
```

### Need more help?
See the comprehensive `SETUP_GUIDE.md` in this directory.

## Next Steps

- Create additional user certificates: `cd tak/certs && ./makeCert.sh client username`
- Generate data packages: `./scripts/certDP.sh YOUR_IP username`
- Configure federation with other TAK servers
- Review security settings in `CoreConfig.xml`
- Set up firewall rules to protect your server

## Resources

- 📖 [Full Setup Guide](SETUP_GUIDE.md)
- 📖 [FAQ](FAQ.md)
- 📹 [Video Tutorial](https://www.youtube.com/watch?v=h4PA9NN-cDk)
- 🌐 [TAK.gov](https://tak.gov)
- 📚 [TAK Documentation](https://github.com/TAK-Product-Center/Server/tree/main/src/docs)

---

**Ready to begin? Run `./check-ready.sh` to verify your system!**
