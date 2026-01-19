#!/bin/bash

# Makes an ATAK / iTAK friendly data package containing CA, user cert, user key
if [ $# -lt 2 ] ; then
    echo "Usage: $0 <IP> <USER>"
    exit 1
fi

IP=$1
USER=$2

# server.pref

echo "<?xml version='1.0' encoding='ASCII' standalone='yes'?>" > server.pref
echo "<preferences>" >> server.pref
echo "  <preference version=\"1\" name=\"cot_streams\">" >> server.pref
echo "    <entry key=\"count\" class=\"class java.lang.Integer\">1</entry>" >> server.pref
echo "    <entry key=\"description0\" class=\"class java.lang.String\">TAK Server</entry>" >> server.pref
echo "    <entry key=\"enabled0\" class=\"class java.lang.Boolean\">true</entry>" >> server.pref
echo "    <entry key=\"connectString0\" class=\"class java.lang.String\">$IP:8089:ssl</entry>" >> server.pref
echo "  </preference>" >> server.pref
echo "  <preference version=\"1\" name=\"com.atakmap.app_preferences\">" >> server.pref
echo "    <entry key=\"displayServerConnectionWidget\" class=\"class java.lang.Boolean\">true</entry>" >> server.pref
echo "    <entry key=\"caLocation\" class=\"class java.lang.String\">certs/$IP.p12</entry>" >> server.pref
echo "    <entry key=\"caPassword\" class=\"class java.lang.String\">atakatak</entry>" >> server.pref
echo "    <entry key=\"clientPassword\" class=\"class java.lang.String\">atakatak</entry>" >> server.pref
echo "    <entry key=\"certificateLocation\" class=\"class java.lang.String\">certs/$USER.p12</entry>" >> server.pref
echo "  </preference>" >> server.pref
echo "</preferences>" >> server.pref


# manifest.xml

echo "<MissionPackageManifest version=\"2\">" > manifest.xml
echo "  <Configuration>" >> manifest.xml
echo "    <Parameter name=\"uid\" value=\"sponsored-by-cloudrf-the-api-for-rf\"/>" >> manifest.xml
echo "    <Parameter name=\"name\" value=\"$USER DP\"/>" >> manifest.xml
echo "    <Parameter name=\"onReceiveDelete\" value=\"true\"/>" >> manifest.xml
echo "  </Configuration>" >> manifest.xml
echo "  <Contents>" >> manifest.xml
echo "    <Content ignore=\"false\" zipEntry=\"certs\\server.pref\"/>" >> manifest.xml
echo "    <Content ignore=\"false\" zipEntry=\"certs\\$IP.p12\"/>" >> manifest.xml
echo "    <Content ignore=\"false\" zipEntry=\"certs\\$USER.p12\"/>" >> manifest.xml
echo "  </Contents>" >> manifest.xml
echo "</MissionPackageManifest>" >> manifest.xml

mkdir -p certs
mv server.pref certs/
cp tak/certs/files/$IP.p12 certs/
cp tak/certs/files/$USER.p12 certs/
zip -r tak/certs/files/$USER-$IP.dp.zip manifest.xml certs
rm -rf certs server.pref manifest.xml
echo "-------------------------------------------------------------"
echo "Created certificate data package for $USER @ $IP as tak/certs/files/$USER-$IP.dp.zip"
