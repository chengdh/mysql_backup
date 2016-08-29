#!/bin/sh
#you should run as root
#echo "Bin Logs backed up"
FULL_DUMPS_DIR="/var/mysql_dumps"
BIN_DUMPS_DIR="/var/log/mysql"

REMOTE_FULL_DUMPS_DIR="/var/mysql_dumps"
REMOTE_BIN_DUMPS_DIR="/var/mysql/log_dumps"

USER="root"
PASSWD="root"


DATABASES="il_yanzhao_new_production il_yanzhao_lite_production yanzhao-mis_production"

if [ `date +%A` = "Sunday" -a `date +%H` = "03" -o "$1" = "dump" ]; then
  echo "Weekly Backup started `date`"
  echo "Full mysql database dump started"
  echo 'All existing full backups and binary log files will be removed'
  PREFIX='mysql-dump.'
  DT=`date "+%m%d%y"`
  DBFN=$PREFIX$DT'.sql'
  mkdir -p $FULL_DUMPS_DIR
  rm -f $FULL_DUMPS_DIR/*.bz2
  rm -f $BIN_DUMPS_DIR/*.bz2

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

lftp sftp://lmis:lmis@122.0.76.160 -e "set ftp:ssl-protect-data true;mirror -er --reverse -I *.bz2 -X $FULL_DUMPS_DIR $REMOTE_FULL_DUMPS_DIR;mirror -er --reverse -I *.bz2 -X $newestlog $BIN_DUMPS_DIR $REMOTE_BIN_DUMPS_DIR;mput $BIN_DUMPS_DIR/mysql-bin.index -O $REMOTE_BIN_DUMPS_DIR; exit;"
#lftp sftp://lmis:lmis@122.0.76.160 -e "set ftp:ssl-protect-data true;mirror -er --reverse -I *.bz2 /home/lmis/db_backup /home/lmis/db_backupt; exit;"
#echo "Bin Logs backed up"
