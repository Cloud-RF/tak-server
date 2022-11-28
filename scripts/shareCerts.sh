#!/bin/bash
mkdir -p share
cp tak/certs/files/*.zip share
cd share
python3 -m http.server 12345
