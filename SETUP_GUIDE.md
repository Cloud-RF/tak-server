# TAK Server Setup Guide

## Prerequisites Completed ✓

The following prerequisites have been installed:
- Docker and Docker Compose
- net-tools (for netstat)
- unzip utility
- All setup scripts are now executable

## Next Steps to Complete Setup

### 1. Download TAK Server Release

You need to download an official TAK Server Docker release from:
**https://tak.gov/products/tak-server**

#### Available Releases:
- `takserver-docker-5.2-RELEASE-43.zip` (517MB) - Latest recommended
- `takserver-docker-5.2-RELEASE-30.zip` (517MB)
- `takserver-docker-5.1-RELEASE-50.zip` (615MB)
- `takserver-docker-5.0-RELEASE-58.zip` (660MB)

### 2. Place the ZIP File

After downloading, place the ZIP file in this directory:
```bash
/home/user/tak-server/
```

### 3. Ensure Docker is Running

On a system with proper Docker support, start the Docker daemon:
```bash
# On systemd-based systems:
sudo systemctl start docker
sudo systemctl enable docker

# Or on systems using service:
sudo service docker start

# Verify Docker is running:
docker ps
```

### 4. Run the Setup Script

Once Docker is running and the ZIP file is in place:
```bash
cd /home/user/tak-server
./scripts/setup.sh
```

The setup script will:
- Verify the checksums of your TAK Server release
- Check that required ports (5432, 8089, 8443, 8444, 8446, 9000, 9001) are available
- Extract and configure the TAK Server
- Start Docker containers for TAK Server and PostgreSQL
- Generate SSL certificates for secure connections
- Create admin user with random password
- Generate data packages for client devices (user1, user2)

### 5. During Setup

You'll be prompted for:
- **Memory allocation**: Default is 4GB (4000000 kB)
- **Country**: Default is US
- **State**: Default is state
- **City**: Default is city
- **Organizational Unit**: Default is org

You can press Enter to accept defaults.

### 6. After Setup Completes

The script will provide:
- **Admin username** (default: admin)
- **Admin password** (randomly generated)
- **PostgreSQL password** (randomly generated)
- **Web interface URL**: https://YOUR_IP:8443

**IMPORTANT**: Save these passwords - they won't be shown again!

### 7. Install Admin Certificate

To access the web interface:

1. The `admin.p12` certificate will be in the project root directory
2. Install it in your browser (password: `atakatak`)

#### Chrome:
Settings → Privacy and Security → Security → Manage Certificates → Your certificates → Import

#### Firefox:
Settings → Privacy & Security → Certificates → View Certificates → Your Certificates → Import
Then: Authorities → TAK → Edit Trust → Check "This certificate can identify web sites"

### 8. Access Web Interface

Navigate to: `https://YOUR_IP:8443`

The certificate will authenticate you automatically.

### 9. Connect ATAK/iTAK Devices

Data packages for client connections are in:
```
/home/user/tak-server/tak/certs/files/
```

Files include:
- `user1-YOUR_IP.dp.zip`
- `user2-YOUR_IP.dp.zip`

Import these on your mobile devices via ATAK/iTAK's "Import" → "Local SD" function.

## Managing TAK Server

### Start Server
```bash
cd /home/user/tak-server
docker compose up -d
```

### Stop Server
```bash
cd /home/user/tak-server
docker compose down
```

### View Logs
```bash
docker exec -it tak-server-tak-1 tail -f /opt/tak/logs/takserver.log
# Or from outside the container:
tail -f /home/user/tak-server/tak/logs/takserver.log
```

### Clean Installation (Remove Everything)
```bash
cd /home/user/tak-server
sudo ./scripts/cleanup.sh
```

## Required Ports

Ensure these ports are available and not blocked by firewall:
- 5432 - PostgreSQL database
- 8089 - TAK Server API
- 8443 - Web interface (HTTPS)
- 8444 - Federation
- 8446 - Certificate enrollment
- 9000 - TAK Server streaming
- 9001 - TAK Server streaming

## Troubleshooting

### Port Already in Use
```bash
sudo netstat -plant | grep <PORT_NUMBER>
ps aux | grep <PID>
kill <PID>
```

### Docker Not Running
```bash
sudo systemctl status docker
sudo systemctl restart docker
```

### Need to Regenerate Certificates
See the TAK Product Center documentation: https://github.com/TAK-Product-Center/Server/tree/main/src/docs

## Security Notes

- The PostgreSQL database listens on port 5432 - block this port with a firewall
- Only expose necessary ports to the internet
- Consider using a VPN (OpenVPN, WireGuard, etc.) for secure remote access
- Keep your certificates secure
- Regularly update your TAK Server to the latest release

## Additional Resources

- [TAK Server Documentation](https://github.com/TAK-Product-Center/Server/tree/main/src/docs)
- [Setup Video Tutorial](https://www.youtube.com/watch?v=h4PA9NN-cDk)
- [TAK.gov](https://tak.gov)
- [ATAK on Google Play](https://play.google.com/store/apps/details?id=com.atakmap.app.civ)
- [iTAK on App Store](https://apps.apple.com/my/app/itak/id1561656396)

---

**Setup prepared by Claude Code**
**Original project by CloudRF.com - "The API for RF"**
