# Running TPC-H benchmark on AnalyticDB PostgreSQL

---
### Overview

#### About TPC-H

As stated in the [TPC Benchmark™ H (TPC-H)](http://www.tpc.org/tpch/?spm=a2c63.p38356.879954.3.61ad2e2azV5uLJ) specification:

“TPC-H is a decision support benchmark. It consists of a suite of business-oriented ad hoc queries and concurrent data modifications. The queries and the data populating the database have been chosen to have broad industry-wide relevance. This benchmark illustrates decision support systems that examine large volumes of data, execute queries with a high degree of complexity, and give answers to critical business questions.”

For more information, see [TPC-H specifications](https://yq.aliyun.com/go/articleRenderRedirect?spm=a2c63.p38356.879954.4.61ad2e2azV5uLJ&url=http%3A%2F%2Fwww.tpc.org%2Ftpc_documents_current_versions%2Fpdf%2Ftpc-h_v2.17.3.pdf).

- Note:

``This implementation of TPC-H is derived from the TPC-H Benchmark and is not comparable to published TPC-H Benchmark results, as this implementation does not comply with all the requirements of the TPC-H Benchmark``.

This is the ER(Entity Relationship) diagram of 8 tables in TPC-H.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tpch-er.png)

(source: [TPC Benchmark H Standard Specification](http://www.tpc.org/tpc_documents_current_versions/pdf/tpc-h_v2.17.1.pdf?spm=a2c63.p38356.879954.5.61ad2e2azV5uLJ&file=tpc-h_v2.17.1.pdf))

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

- [Step 1. Use Terraform to provision ECS and AnalyticDB PostgreSQL on Alibaba Cloud](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/master/benchmark-tpc-h#step-1-use-terraform-to-provision-ecs-and-database-on-alibaba-cloud)
- [Step 2. Config and mount data disk on ECS for TPC-H data set](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/master/benchmark-tpc-h#step-2-config-and-mount-data-disk-on-ecs-for-tpc-h-data-set)
- [Step 3. Generate TPC-H 100GB data set and upload to OSS](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/master/benchmark-tpc-h#step-3-generate-tpc-h-100gb-data-set-and-upload-to-oss)
- [Step 4. Create TPC-H schema in AnalyticDB PostgreSQL and load data from OSS](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/master/benchmark-tpc-h#step-4-create-tpc-h-schema-in-analyticdb-postgresql-and-load-data-from-oss)
- [Step 5. Run TPC-H query benchmark](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/master/benchmark-tpc-h#step-5-run-tpc-h-query-benchmark)

---
### Step 1. Use Terraform to provision ECS and database on Alibaba Cloud

If you are the 1st time to use Terraform, please refer to [https://github.com/alibabacloud-howto/terraform-templates](https://github.com/alibabacloud-howto/terraform-templates) to learn how to install and use the Terraform on different operating systems.

Run the [terraform script](https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/deployment/terraform/main.tf) to initialize the resources (in this tutorial, we use ECS and AnalyticDB PostgreSQL. OSS bucket will also be used for storing big TPC-H data set, and we will manually create the bucket later). Please specify the necessary information and region to deploy.

After the Terraform script execution finished, the ECS and AnalyticDB PostgreSQL instance information are listed as below.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tf-done.png)

---
### Step 2. Config and mount data disk on ECS for TPC-H data set

Please log on to ECS with ``ECS EIP``. By default, the password is ``N1cetest``, which is preset in the terraform provision script in Step 1. If you've already changed it, please update accordingly.

```bash
ssh root@<ECS_EIP>
```

Initialize and mount the data disk.

```bash
fdisk -u /dev/vdb
```

There will be some promote for the configuration, please follow the guide as shown in the image below.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/fdisk.png)

Then input the following commands to finish the data disk mount.

```
fdisk -lu /dev/vdb

mkfs -t ext4 /dev/vdb1
cp /etc/fstab /etc/fstab.bak
echo `blkid /dev/vdb1 | awk '{print $2}' | sed 's/\"//g'` /mnt ext4 defaults 0 0 >> /etc/fstab
mount /dev/vdb1 /mnt
df -h
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/data-disk-mount-done.png)

---
### Step 3. Generate TPC-H 100GB data set and upload to OSS

Install GIT, clone this github project and generate TPC-H data set. [https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/data_gen_100gb.sh](https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/data_gen_100gb.sh) this file will generate 100GB data set. If you want to generate other size, please modify accordingly.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/100gb.png)

```
yum install -y git
cd /mnt
git clone https://github.com/alibabacloud-howto/solution-adbpg-labs.git
sh /mnt/solution-adbpg-labs/benchmark-tpc-h/data_gen_100gb.sh
```

Since we configured to generate the TPC-H data in 8 partitions in parallel, when input ``top`` command, there shows 8 ``dbgen`` processes generating data.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/dbgen-top.png)

It will take for a while for these ``dbgen`` processes to finish the data generation. When ``dbgen`` processes disappear in the ``top`` view, then the data generation finish successfully.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/dbgen-top-done.png)

Run the command ``df -h``, it shows that 100+G ``Used`` under ``/mnt``, which is the size of generated TPC-H data set in 100 SF.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/dbgen-done.png)

Then create bucket in OSS for TPC-H data set.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/oss-1.png)

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/oss-2.png)

Upload TPC-H data files to OSS bucket for parallel loading to AnalyticDB PostgreSQL later. Please update the parameters accordingly in the file [https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/upload_tpch_oss.sh](https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/upload_tpch_oss.sh).
- ``OSS_ENDPOINT`` : the OSS endpoint of the bucket created for TPC-H data set
- ``OSS_BUCKET`` : the bucket created for TPC-H data set
- ``AK_ID`` : your Alibaba Cloud account access key
- ``AK_SECRET`` :  your Alibaba Cloud account access secret

Then run the following commands:

```bash
cd /mnt
wget http://gosspublic.alicdn.com/ossutil/1.7.3/ossutil64
chmod 755 ossutil64
sh /mnt/solution-adbpg-labs/benchmark-tpc-h/upload_tpch_oss.sh
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tpchdata2oss-done-1.png)

After the script finished, it will show 8 folders in OSS bucket for 8 tables correspondingly.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/tpchdata2oss-done-2.png)

---
### Step 4. Create TPC-H schema in AnalyticDB PostgreSQL and load data from OSS

Create user account in AnalyticDB PostgreSQL:
- Name: ``adbpg``
- Password: ``N1cetest``

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/adbpg-account.png)

Download and setup AnalyticDB for PostgreSQL client.

```bash
cd /mnt
wget http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/compat-openssl10-1.0.2o-3.el8.x86_64.rpm
rpm -i compat-openssl10-1.0.2o-3.el8.x86_64.rpm
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/181125/cn_zh/1598426198114/adbpg_client_package.el7.x86_64.tar.gz
tar -xzvf adbpg_client_package.el7.x86_64.tar.gz
cd /mnt/adbpg_client_package/bin

vim ~/.pgpass
```

Input the following line in ``~/.pgpass`` file, ``<AnalyticDB PostgreSQL connection string>`` is the connection string of the AnalyticDB PostgreSQL cluster.

``<AnalyticDB PostgreSQL connection string>:5432:adbpg:adbpg:N1cetest``

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/pgpass.png)

Then run the commands to create TPC-H tables.

```
chmod 0600 ~/.pgpass
cd /mnt/adbpg_client_package/bin
./psql -h<AnalyticDB PostgreSQL connection string> -Uadbpg adbpg -f /mnt/solution-adbpg-labs/benchmark-tpc-h/tpch-ddl.sql
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/psql-ddl.png)

Load TPC-H data set from OSS into AnalyticDB PostgreSQL. Please update the parameters accordingly in the file [https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/load_tpch_oss_data.sql](https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/load_tpch_oss_data.sql) before executing the following commands.
- ``oss://adbpg-tpch-bechmark-hongkong`` : change to your target TPC-H bucket accordingly
- ``<ACCESS KEY>`` : your Alibaba Cloud account access key
- ``<ACCESS SECRET>`` : your Alibaba Cloud account access secret
- ``oss-cn-hongkong-internal.aliyuncs.com`` : change to the endpoint of your target TPC-H bucket accordingly

```
cd /mnt/adbpg_client_package/bin
./psql -h<AnalyticDB PostgreSQL connection string> -Uadbpg adbpg -f /mnt/solution-adbpg-labs/benchmark-tpc-h/load_tpch_oss_data.sql
```

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/load-done.png)

After loading finished, run the ``SELECT COUNT(*)`` to verify the row count in 8 tables.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/load-done-verify.png)

And please also run ``ANALYZE`` to collect statistics for tables for optimizer to generate better query execution plan.

![image.png](https://github.com/alibabacloud-howto/solution-adbpg-labs/raw/master/benchmark-tpc-h/images/analyze.png)

---
### Step 5. Run TPC-H query benchmark

Please update the parameters accordingly in the file [https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/query.sh](https://github.com/alibabacloud-howto/solution-adbpg-labs/blob/master/benchmark-tpc-h/query.sh) before execution.
- ``ADB_PG_URL`` : AnalyticDB PostgreSQL cluster connection string
- ``ADB_PG_USER`` : AnalyticDB PostgreSQL cluster account user name (no need to change if you follow this guide to use ``adbpg``)

```
sh /mnt/solution-adbpg-labs/benchmark-tpc-h/query.sh
```

All the TPC-H queries are located in [https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/master/benchmark-tpc-h/tpch_query](https://github.com/alibabacloud-howto/solution-adbpg-labs/tree/master/benchmark-tpc-h/tpch_query).