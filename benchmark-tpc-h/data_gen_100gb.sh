#!/bin/sh

## Download and build TPC-H DBGEN tool
cd /mnt
wget https://github.com/electrum/tpch-dbgen/archive/refs/heads/master.zip
unzip master.zip
cd tpch-dbgen-master/
echo "#define EOL_HANDLING 1" >> config.h # remove the tail '|'
make

## Generate 100GB TPC-H data
for((i=1;i<=8;i++));
do
    ./dbgen -s 100 -S $i -C 8 -f &
done
