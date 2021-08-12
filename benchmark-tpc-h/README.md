# Running TPC-H benchmark on AnalyticDB PostgreSQL

---
### Overview

#### About TPC-H

TPC-H is a test set developed by the Transaction Processing Performance Council (TPC) to simulate decision support applications. At present, it is widely used in academia and industry to evaluate the performance of decision support technology applications. TPC-H is modeled according to the real production operating environment, and simulates a data warehouse of a sales system. It contains a total of 8 basic relationships, and the amount of data can be set from 1GB to 30TB. The benchmark test contains a total of 22 queries, and the main evaluation indicators are the response time of each query, that is, the time from submitting the query to the return of the result. The test results can comprehensively reflect the system's ability to process queries. For details, refer to the [TPC-H Specification](http://www.tpc.org/tpch/).

This is the ER(Entity Relationship) diagram of 8 tables in TPC-H.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tpch-er.png)

#### About the TPC-H benchmark data

In TPC-H, SF (Scale Factor) is used to describe the amount of data, and 1 SF corresponds to 1GB unit. 100 SF is 100GB. The data volume corresponding to 1 SF is only the total data volume of the 8 tables, excluding the space occupation such as indexes, and more space needs to be reserved when preparing data. The data volume of each table under the 100GB data set is as follows:

| Table Name | Row Count |
| :--------: | :-------: |
| customer | 15,000,000 |
| lineitem | 600,037,902 |
| nation | 25 |
| orders | 150,000,000 |
| part | 20,000,000 |
| partsupp | 80,000,000 |
| region | 5 |
| supplier | 1,000,000 |

#### Deployment architecture:

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/archi.png)

---
### Index

- [Step 1. Use Terraform to provision ECS and AnalyticDB PostgreSQL on Alibaba Cloud](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/main/benchmark-tpc-h#step-1-use-terraform-to-provision-ecs-and-database-on-alibaba-cloud)
- [Step 2. Config and mount data disk on ECS for TPC-H data set](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/main/benchmark-tpc-h#step-2-config-and-mount-data-disk-on-ecs-for-tpc-h-data-set)
- [Step 3. Generate TPC-H 100GB data set and upload to OSS](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/main/benchmark-tpc-h#step-3-generate-tpc-h-100gb-data-set-and-upload-to-oss)
- [Step 4. Create TPC-H schema in AnalyticDB PostgreSQL and load data from OSS](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/main/benchmark-tpc-h#step-4-create-tpc-h-schema-in-analyticdb-postgresql-and-load-data-from-oss)
- [Step 5. Run TPC-H query benchmark](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/main/benchmark-tpc-h#step-5-run-tpc-h-query-benchmark)

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tf-done.png)

### Step 2. Config and mount data disk on ECS for TPC-H data set

Initialize and mount the data disk.

```bash
fdisk -u /dev/vdb
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/fdisk.png)

```
fdisk -lu /dev/vdb

mkfs -t ext4 /dev/vdb1
cp /etc/fstab /etc/fstab.bak
echo `blkid /dev/vdb1 | awk '{print $2}' | sed 's/\"//g'` /mnt ext4 defaults 0 0 >> /etc/fstab
mount /dev/vdb1 /mnt
df -h
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/data-disk-mount-done.png)

### Step 3. Generate TPC-H 100GB data set and upload to OSS

Install GIT, clone the project and generate TPC-H data set.

```
yum install -y git
cd /mnt
git clone https://github.com/alibabacloud-howto/solution-adbpg-labs.git
sh /mnt/solution-adbpg-labs/benchmark-tpc-h/data_gen_100gb.sh
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/dbgen-top.png)

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/dbgen-top-done.png)

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/dbgen-done.png)

Create bucket in OSS.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/oss-1.png)

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/oss-2.png)

Upload TPC-H data files to OSS bucket for parallel loading to AnalyticDB PostgreSQL later.

```bash
cd /mnt
wget http://gosspublic.alicdn.com/ossutil/1.7.3/ossutil64
chmod 755 ossutil64
sh /mnt/solution-adbpg-labs/benchmark-tpc-h/upload_tpch_oss.sh
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tpchdata2oss-done-1.png)

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tpchdata2oss-done-2.png)

### Step 4. Create TPC-H schema in AnalyticDB PostgreSQL and load data from OSS

Download and setup AnalyticDB for PostgreSQL client.

```bash
cd /mnt
wget http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/compat-openssl10-1.0.2o-3.el8.x86_64.rpm
rpm -i compat-openssl10-1.0.2o-3.el8.x86_64.rpm
```

Create user account in AnalyticDB PostgreSQL, adbpg/N1cetest

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/adbpg-account.png)

```bash
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/181125/cn_zh/1598426198114/adbpg_client_package.el7.x86_64.tar.gz
tar -xzvf adbpg_client_package.el7.x86_64.tar.gz
cd adbpg_client_package/bin

vim ~/.pgpass
```

``<AnalyticDB PostgreSQL connection string>:5432:adbpg:adbpg:N1cetest``

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/pgpass.png)

```
chmod 0600 ~/.pgpass
cd adbpg_client_package/bin
./psql -h<AnalyticDB PostgreSQL connection string> -Uadbpg adbpg -f /mnt/solution-adbpg-labs/benchmark-tpc-h/tpch-ddl.sql
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/psql-ddl.png)

Load TPC-H data set from OSS into AnalyticDB PostgreSQL.

```
./psql -h<AnalyticDB PostgreSQL connection string> -Uadbpg adbpg -f /mnt/solution-adbpg-labs/benchmark-tpc-h/load_tpch_oss_data.sql
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/load-done.png)

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/load-done-verify.png)

### Step 5. Run TPC-H query benchmark

```
sh /mnt/solution-adbpg-labs/benchmark-tpc-h/query.sh
```