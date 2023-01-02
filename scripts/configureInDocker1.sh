#!/bin/bash

# Added for 4.7 REL 18 where they broke DB auth with TCP/IP hardening
# Commented out when they relaxed it in REL 4.7 20 because folks docker systems stopped working..
# Re-added for 4.8 REL 31 because they got hard again. I can do this all day.
sed -i 's/127.0.0.1\/32/0.0.0.0\/0/g' /opt/tak/db-utils/pg_hba.conf

# Removed inline options because these belong in postgres.conf
if [ -f "/var/lib/postgresql/data/postgresql.conf" ];
then
	echo "-------DB Exists-------"
	rm -f /var/lib/postgresql/data/postmaster.pid
	echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
	cp /opt/tak/db-utils/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
	su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/data -l logfile start"

else

	echo "-------NO DB-------"
	chown postgres:postgres /var/lib/postgresql/data
	su - postgres -c '/usr/lib/postgresql/14/bin/pg_ctl initdb -D /var/lib/postgresql/data'
	cp /opt/tak/db-utils/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
	su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/data -l logfile start"	

	cd /opt/tak/db-utils
	./configure.sh
fi


tail -f /dev/null
