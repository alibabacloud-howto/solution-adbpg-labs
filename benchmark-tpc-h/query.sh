#!/bin/bash

export ADB_PG_URL=<AnalyticDB PostgreSQL connection string>
export ADB_PG_USER=adbpg

mkdir /mnt/log/
total_cost=0

for i in {1..22}
do
        echo "begin run Q${i}, tpch_query/q$i.sql , `date`"
        begin_time=`date +%s.%N`
        /mnt/adbpg_client_package/bin/psql -h${ADB_PG_URL} -U${ADB_PG_USER} -f /mnt/solution-adbpg-labs/benchmark-tpc-h/tpch_query/q${i}.sql > /mnt/log/log_q${i}.out
        rc=$?
        end_time=`date +%s.%N`
        cost=`echo "$end_time-$begin_time"|bc`
        total_cost=`echo "$total_cost+$cost"|bc`
        if [ $rc -ne 0 ] ; then
              printf "run Q%s fail, cost: %.2f, totalCost: %.2f, `date`\n" $i $cost $total_cost
         else
              printf "run Q%s succ, cost: %.2f, totalCost: %.2f, `date`\n" $i $cost $total_cost
         fi
done