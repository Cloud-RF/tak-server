#!/bin/bash

if [ -d /var/lib/postgresql/data ];
then
	rm -f /var/lib/postgresql/data/postmaster.pid
	echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
	sed -i 's/127.0.0.1\/32/0.0.0.0\/0/g' /opt/tak/db-utils/pg_hba.conf
	cp /opt/tak/db-utils/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
	su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/data -l logfile start -o '-c max_connections=2100 -c shared_buffers=2560MB'"
	tail -f /dev/null
else
	chown postgres:postgres /var/lib/postgresql/data

	su - postgres -c '/usr/lib/postgresql/14/bin/pg_ctl initdb -D /var/lib/postgresql/data'
	sed -i 's/127.0.0.1\/32/0.0.0.0\/0/g' /opt/tak/db-utils/pg_hba.conf
	cp /opt/tak/db-utils/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
	su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/data -l logfile start -o '-c max_connections=2100 -c shared_buffers=2560MB'"

	cd /opt/tak/db-utils
	./configure.sh


	tail -f /dev/null
fi