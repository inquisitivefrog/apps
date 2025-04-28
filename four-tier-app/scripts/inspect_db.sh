#!/bin/bash
#
#set -x
export DB_USERNAME=dbuser
export DB_PASSWORD=G1ng3rb33r
export DB_NAME=bookdb
export DB_LOG=INFO
export HOST_IP=192.168.1.114

export MYSQL_PWD=${DB_PASSWORD}; mysqladmin --user=${DB_USERNAME} ping
export MYSQL_PWD=${DB_PASSWORD}; mysql --user=${DB_USERNAME} -e "SHOW DATABASES"
export MYSQL_PWD=${DB_PASSWORD}; mysql --user=${DB_USERNAME} --database=${DB_NAME} -e "SHOW TABLES"
export MYSQL_PWD=${DB_PASSWORD}; mysql --user=${DB_USERNAME} --database=${DB_NAME} -e "DESCRIBE TABLE book"
