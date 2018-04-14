#!/bin/bash

set -e

host="$1"
shift
cmd="$@"

service mysql stop

/etc/init.d/mysql start

until nc -zv second-node-cluster 3306; do
  >&2 echo "$(date) - second-node-cluster is unavailable - sleeping"
  sleep 3
done

## add pmm server
pmm-admin config --server $PMM_SERVER
pmm-admin add mysql

>&2 echo "second-node-cluster is up - executing command"
exec $cmd
