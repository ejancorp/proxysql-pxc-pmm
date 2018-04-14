#!/bin/bash

set -e

host="$1"
shift
cmd="$@"

service proxysql start

until nc -zv proxysql 6032; do
  >&2 echo "$(date) - proxysql is unavailable - sleeping"
  sleep 3
done

yes | proxysql-admin --config-file=/etc/proxysql-admin.cnf --enable

## add pmm server
pmm-admin config --server $PMM_SERVER
pmm-admin add proxysql:metrics

>&2 echo "proxysql is up - executing command"
exec $cmd
