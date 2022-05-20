FROM ubuntu:bionic-20220427

RUN useradd -s /sbin/nologin mysql

RUN apt-get update \
    && apt-get install -y mysql-server-5.7 \
    && apt-get clean

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld","--user=mysql"]