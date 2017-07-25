#!/bin/bash
USERNAME="root"
HOST="localhost"
PORT="3306"
BACKUP_DIR="/vagrant/vagrant-files/databases"
BACKUP_SUFFIX=$1

if [ ! -d "$BACKUP_DIR" ]
then
   echo "Destination does not exist: $BACKUP_DIR"
   exit 1
fi

mysql -u"$USERNAME" -h"$HOST" -P"$PORT" -e "show databases" \
| grep -Ev 'Database|information_schema|performance_schema|mysql' \
| while read dbname;
do
mysqldump -u"$USERNAME" --events -h"$HOST" -P"$PORT" $dbname | gzip -c > "${BACKUP_DIR}/${dbname}-${BACKUP_SUFFIX}.sql.gz"
done
