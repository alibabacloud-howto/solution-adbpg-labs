COPY nation
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/nation/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;

COPY region
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/region/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;

COPY customer
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/customer/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;

COPY lineitem
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/lineitem/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;

-- Since we have "ORDER BY(L_SHIPDATE)" defined in DDL of lineitem, sort for clustering
sort lineitem;

COPY orders
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/orders/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;

-- Since we have "ORDER BY(O_ORDERDATE)" defined in DDL of orders, sort for clustering
sort orders;

COPY part
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/part/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;


COPY supplier
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/supplier/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;

COPY partsupp
FROM 'oss://adbpg-tpch-bechmark-hongkong/tpch-100g/partsupp/'
ACCESS_KEY_ID '<ACCESS KEY>'
SECRET_ACCESS_KEY '<ACCESS SECRET>'
FORMAT AS text
"delimiter" '|'
ENDPOINT 'oss-cn-hongkong-internal.aliyuncs.com'
FDW 'oss_fdw'
;

