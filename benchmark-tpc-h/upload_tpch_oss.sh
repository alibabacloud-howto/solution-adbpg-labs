#!/bin/sh

export OSS_ENDPOINT=oss-cn-hongkong-internal.aliyuncs.com
export OSS_BUCKET=oss://adbpg-tpch-bechmark-hongkong
export AK_ID=<Access Key>
export AK_SECRET=<Access Secret>

cd /mnt/tpch-dbgen-master

ls customer.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/customer/ &
done

ls lineitem.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/lineitem/ &
done

ls orders.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/orders/ &
done

ls supplier.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/supplier/ &
done

ls partsupp.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/partsupp/ &
done

ls part.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/part/ &
done

ls nation.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/nation/ &
done

ls region.tbl* | while read line;
do
    /mnt/ossutil64 -e $OSS_ENDPOINT -i $AK_ID -k $AK_SECRET cp $line $OSS_BUCKET/tpch-100g/region/ &
done
