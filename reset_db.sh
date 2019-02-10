#!/usr/bin/env bash

TOP=$(dirname "$0")
mysql -uroot -pcontrail123 -h 127.0.0.1 -e "drop database if exists tong_test;"
mysql -uroot -pcontrail123 -h 127.0.0.1  -e "create database tong_test;"
mysql -uroot -pcontrail123 -h 127.0.0.1 tong_test < $TOP/init.sql
