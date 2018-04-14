#!/bin/bash

set -e

host="$1"
shift
cmd="$@"

service mysql stop

/etc/init.d/mysql start

until nc -zv first-node-cluster 3306; do
  >&2 echo "$(date) - first-node-cluster is unavailable - sleeping"
  sleep 3
done

## add pmm server
pmm-admin config --server $PMM_SERVER
pmm-admin add mysql

>&2 echo "first-node-cluster is up - executing command"
exec $cmd
