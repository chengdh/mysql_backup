#!/bin/sh
#you should run as root
#echo "Bin Logs backed up"
FULL_DUMPS_DIR="/var/mysql_dumps"
BIN_DUMPS_DIR="/var/log/mysql"
USER="root"
PASSWD="root"

if [`date +%A` == "Sunday"] && [`date +%H` == "06"] || ["$1" == "dump"]; then
  echo "Weekly Backup started `date`"
  echo "Full mysql database dump started"
  echo 'All existing full backups and binary log files will be removed'
  PREFIX='mysql-dump.'
  DT=`date "+%m%d%y"`
  DBFN=$PREFIX$DT'.sql'
  DATABASES="il_yanzhao_new_production il_yanzhao_lite_production yanzhao-mis_production"
  mkdir -p $FULL_DUMPS_DIR
  rm -f $FULL_DUMPS_DIR/*.bz2

  mysqldump -u$USER -p$PASSWD --flush-logs --delete-master-logs --master-data=2 --add-drop-table --lock-all-tables --databases $DATABASES > $FULL_DUMPS_DIR/$DBFN
  bzip2 $FULL_DUMPS_DIR/$DBFN
  echo "mysql dump complete"
else
  echo "starting new bin log $USER"
  mysqladmin -u$USER -p$PASSWD flush-logs
fi
newestlog=`ls -d $BIN_DUMPS_DIR/mysql-bin.?????? | sed 's/^.*\.//' | sort -g | tail -n 1`
for file in `ls /$BIN_DUMPS_DIR/mysql-bin.??????`
do
  if [ "$BIN_DUMPS_DIR/mysql-bin.$newestlog" != "$file" ]; then
    bzip2 "$file"
  fi
done

#sftp -u 'ftpuser,ftppassword' backupspace.rimuhosting.com -e "set ftp:ssl-protect-data true; mirror -er --reverse -I *.bz2 -X $newestlog /var/lib/mysql /myvar/lib/mysql; mput /var/lib/mysql/mybinlog.index -O /myvar/lib/mysql; exit;"
#echo "Bin Logs backed up"
