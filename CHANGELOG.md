# CloudRF TAK Server Wrapper Changelog

## Upcoming

- Check for active ports during setup no longer false flagging ephemeral ports.
- Changelog converted to markdown.
- Improvements to README.

## 24/11/2022 - 4.7 REL 20

- Added 7zip support.
- Added warnings to prevent 
- Increased Postgres connection limits to 400 for slower boxes which loop the setup and accumulate stale Postgres connections.
- Improved setup messages.
- Automatic CA generation. CA is `LOL` and CN is `takserver`.
- No more "Do you want to kill this process as sudo etc". If a port is used - the script stops.
- Tested against TAK Server 4.7 REL 20 on AMD64 architecture.

## 23/11/2022 - 4.7 REL 20

- Edited Posgres configuration to reduce memory requirement.
- Removed hardcoded Postgres memory options in startup scripts.
- Added mini web server to deploy setup data packages.
- Updated `CoreConfig.xml` IP addresses to enable rate limiter and federation server.
- Fixed startup race condition which caused HTTPS `8443` to fail to HTTP `8080`.

## 18/10/2022 - 4.7 REL 20

- Automatic generation of user certificates.
- Automatic generation of certificate data packages for users.
- Streamlined setup with removal of a bogus Docker start/stop.
- Fixed issue with random passwords failing to meet complexity requirement.
- Tested against ATAK 4.7 and iTAK 2.3.

## 17/08/2022 - 4.7 REL 18

- Automatic SSL setup
- Removes insecure protocols
- Fixes broken Docker database authentication in upstream release.
- Enforces HTTPS only.
