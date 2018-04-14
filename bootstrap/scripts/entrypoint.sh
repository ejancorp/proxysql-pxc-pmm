#!/bin/bash

set -e

host="$1"
shift
cmd="$@"

service mysql stop

/etc/init.d/mysql bootstrap-pxc

## Admin Accounts
ROOT_PASSWORD=${ROOT_PASSWORD:-password}
DB_POWER_USER=${DB_USER:-admin}
DB_POWER_PASS=${DB_PASS:-password}

## snapshot state transfer account for replication
SST_USER="sstuser"
SST_PASS="password"

## Database accounts
DB_NAME=${DB_NAME:-drupal_db}
DB_USER=${DB_USER:-drupal}
DB_PASS=${DB_PASS:-password}

__setup_root() {
    echo "Setting up root password."
    mysqladmin -u root password $ROOT_PASSWORD
}

__setup_power_credentials() {
    echo "Setting up new power user credentials."
    mysql --user=root --password=$ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_POWER_USER'@'%' IDENTIFIED BY '$DB_POWER_PASS' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql --user=root --password=$ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_POWER_USER'@'%' IDENTIFIED BY '$DB_POWER_PASS' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql --user=root --password=$ROOT_PASSWORD -e "select user, host FROM mysql.user;"
}

__setup_sst_credentials() {
    echo "Setting up new power user credentials."
    mysql --user=root --password=$ROOT_PASSWORD -e "CREATE USER '$SST_USER'@'localhost' IDENTIFIED BY '$SST_PASS'; FLUSH PRIVILEGES;"
    mysql --user=root --password=$ROOT_PASSWORD -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '$SST_USER'@'localhost'; FLUSH PRIVILEGES;"
    mysql --user=root --password=$ROOT_PASSWORD -e "select user, host FROM mysql.user;"
}

__setup_credentials() {
    echo "Setting up new DB and user credentials."
    mysql --user=root --password=$ROOT_PASSWORD -e "CREATE DATABASE $DB_NAME"
    mysql --user=root --password=$ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;"
    mysql --user=root --password=$ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;"
    mysql --user=root --password=$ROOT_PASSWORD -e "select user, host FROM mysql.user;"
}

__setup_root
__setup_power_credentials
__setup_sst_credentials
__setup_credentials

until nc -zv bootstrap-cluster 3306; do
  >&2 echo "$(date) - bootstrap-cluster is unavailable - sleeping"
  sleep 3
done

## add pmm server
pmm-admin config --server $PMM_SERVER
pmm-admin add mysql

>&2 echo "bootstrap-cluster is up - executing command"
exec $cmd
