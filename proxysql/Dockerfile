FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y wget \
    && apt-get install -y netcat \
    && wget https://repo.percona.com/apt/percona-release_0.1-4.xenial_all.deb \
    && dpkg -i percona-release_0.1-4.xenial_all.deb \
    && apt-get update

RUN apt-get -y remove apparmor \
    && apt-get -y install percona-xtradb-cluster-57 \
    && apt-get -y install proxysql \
    && apt-get -y install pmm-client \
    && apt-get -y install supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD proxysql/scripts/start.sh /start.sh
RUN chmod +x /start.sh

RUN mkdir -p /etc/supervisor/conf.d
ADD proxysql/configs/supervisor-mysql.conf /etc/supervisor/conf.d/mysql.conf
ADD proxysql/configs/proxysql-admin.cnf /etc/proxysql-admin.cnf

COPY proxysql/scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash", "/start.sh"]
