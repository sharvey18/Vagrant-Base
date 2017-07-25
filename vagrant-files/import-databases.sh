#!/bin/bash
FILES=/vagrant/vagrant-files/databases/*.sql
for f in $FILES
do
    echo "Importing database $(basename $f .sql) from $f"
    echo "create database $(basename $f .sql)" | mysql -u root
    mysql -u root $(basename $f .sql) < $f
done
