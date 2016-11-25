FULL_DUMPS_DIR="/home/lmis/mysql_dumps"
BIN_DUMPS_DIR="/home/lmis/mysql_binlog_dumps"

TMP_FULL_DUMPS_DIR="/tmp/mysql_dumps"
TMP_BIN_DUMPS_DIR="/tmp/mysql_binlog_dumps"

USER="root"
PASSWD="242612yesno"

#删除临时目录
echo "remove temp dir"
rm -rf $TMP_FULL_DUMPS_DIR
rm -rf $TMP_BIN_DUMPS_DIR

echo "mkdir temp dir"
mkdir -p $TMP_FULL_DUMPS_DIR
mkdir -p $TMP_BIN_DUMPS_DIR


echo "unzip full db files"
cd $TMP_FULL_DUMPS_DIR
for fn in $FULL_DUMPS_DIR/*.bz2 ; do
   bunzip2 -dkf $fn
done

echo "unzip binlog  files"
cd $TMP_BIN_DUMPS_DIR
for fn in $BIN_DUMPS_DIR/*.bz2 ; do
   bunzip2 -dkf $fn
done

#恢复数据库
echo 'recover full db file'
for fn in $TMP_FULL_DUMPS_DIR/*.sql; do
  mysql -u$USER -p$PASSWD < $fn
done

echo 'recover binlog file'
#读取mysql-bin.index
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "recover bin log from file: $line"
    mysqlbinlog $TMP_FULL_DUMPS_DIR/$line | mysql -u$USER -p$PASSWD
done < $BIN_DUMPS_DIR/mysql-bin.index
