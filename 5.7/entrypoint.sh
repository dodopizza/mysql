#!/bin/bash
set -e

MYSQL_DIR=/var/lib/mysql
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"dodoPizza_2022"}

mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld
chmod 755 /var/run/mysqld

echo "[entrypoint][~] Start redirecting mysql logs to stdout"
LOG_PATHS=(
  '/var/log/mysql/error.log'
)
for LOG_PATH in "${LOG_PATHS[@]}"; do
  ( umask 0 && truncate -s0 "$LOG_PATH" )
  tail --pid $$ -n0 -F "$LOG_PATH" &
done

echo "[entrypoint][~] Cleanup ${MYSQL_DIR}"
rm -rf ${MYSQL_DIR}/*

echo "[entrypoint][~] Init empty database"
mysqld --user=mysql --initialize-insecure --explicit_defaults_for_timestamp --skip-networking
mysqld --user=mysql --skip-networking &
while ! mysqladmin ping --silent; do sleep 5; done # wait for mysql

echo '[entrypoint][~] Setup root password'
mysql --user=root --skip-password --execute "
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; 
    CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; 
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
    SHUTDOWN;"

echo "[entrypoint][+] Init completed"

# https://serverfault.com/questions/870568/fatal-error-cant-open-and-lock-privilege-tables-table-storage-engine-for-use
chown -R mysql:mysql ${MYSQL_DIR} /var/run/mysqld || true

echo "[entrypoint][~] Run command"
exec "$@"
