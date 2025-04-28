#!/bin/bash
#
#set -x
export DB_USERNAME=dbuser
export DB_PASSWORD=G1ng3rb33r
export DB_NAME=bookdb
export HOST_IP=192.168.1.114

export MYSQL_PWD=${DB_PASSWORD}; mysqladmin --user=${DB_USERNAME} ping
export MYSQL_PWD=${DB_PASSWORD}; mysql --user=${DB_USERNAME} -e "SHOW DATABASES"

docker build -t bookorderapp .
docker image ls
docker run --rm --name book-order -p 8080:8080 bookorderapp
docker ps
