# Prerequests....
- Install `Docker`
- Install `atlasgo` using this link: https://atlasgo.io/getting-started/#installation
- From your terminal, login to `atlasgo` using `atlas login` and follow the instructions

# Commands
```
# Start ClickHouse DB Server
./run.sh init

# Inspect what is inside the DB
./run.sh inspect

# Inspect what is inside the DB on the web
./run.sh web

# Declarative approach (from desired schema)
./run.sh apply

# Versioned migrations (change-based migrations)
# replace `NAME` with a proper title
./run.sh migrate NAME
```

# Walkthough Example
## Create a new Database
```
# Start ClickHouse DB Server
./run.sh init

# inspect DB to see the initial state (you should see default table only)
./run.sh inspect

# create test database
echo -e 'CREATE DATABASE `test` ENGINE Atomic;' > schema.sql

# show the difference between desired state and actual DB state
./run.sh diff ch schema.sql

# Create `migrations` directory
mkdir migrations

# schema migration
./run.sh migrate create_test_db

# show the difference between desired state and the latest migrations state
./run.sh diff migrations schema.sql

# apply the changes from the migrations state to the actual DB
./run.sh apply

# show the difference between desired state and the latest migrations state
./run.sh diff ch schema.sql

# inspect DB
./run.sh inspect
```
## Add log table
```
# append the creation of the log table
echo "CREATE TABLE \`test\`.\`orders_log\` (  
  \`before.id\` Int64,
  \`before.date\` DateTime,
  \`before.price\` Int64,
  \`before.cancelled\` Bool,
  
  \`after.id\` Int64,
  \`after.date\` DateTime,
  \`after.price\` Int64,
  \`after.cancelled\` Bool,
  
  \`source.lsn\` UInt64,
  op String
) engine = MergeTree order by (\`source.lsn\`);" >> schema.sql

# schema migration
./run.sh migrate create_log_table

# apply the changes from the desired state to the actual DB
./run.sh apply
```
## Add cdc table
```
# append the creation of the cdc table
echo "CREATE TABLE \`test\`.\`orders_cdc\` (
  id Int64,
  date DateTime,
  price Int64,
  cancelled Bool,
  
  version UInt64,
  deleted UInt8
) engine = ReplacingMergeTree(version, deleted) order by (id);" >> schema.sql

# schema migration
./run.sh migrate create_cdc_table

# apply the changes from the desired state to the actual DB
./run.sh apply
```

## Add cdc table's materialized view
```
# append the creation of the cdc table
echo "CREATE MATERIALIZED VIEW \`test\`.\`mview_orders_cdc\`
TO \`test\`.\`orders_cdc\`
AS SELECT
  if(op = 'd', \`before.id\`, \`after.id\`) AS id,
  if(op = 'd', \`before.date\`, \`after.date\`) AS date,
  if(op = 'd', \`before.price\`, \`after.price\`) AS price,
  if(op = 'd', \`before.cancelled\`, \`after.cancelled\`) AS cancelled,
  
  \`source.lsn\` AS version,
  if(op = 'd', 1, 0) AS deleted
FROM \`test\`.\`orders_log\`
WHERE (op = 'c' or op = 'u' or op = 'd');" >> schema.sql

# schema migration
./run.sh migrate create_mview_cdc

# apply the changes from the desired state to the actual DB
./run.sh apply
```

## Inspect the changes on the web
```
./run.sh web
```

## Modify the tables within `schema.sql`
```
# modify `schema.sql` (e.g. add `before.note` and `after.note` columns to `orders_log`, add `note` column to `orders_cdc`, and update `mview_orders_cdc` to insert `note` correctly and rename it to `mview_orders_cdc_new`)

# schema migration
./run.sh migrate updated_tables_and_mview

# apply the changes from the desired state to the actual DB
./run.sh apply

# rename `mview_orders_cdc_new` to `mview_orders_cdc`

# schema migration
./run.sh migrate rename_mview

# apply the changes from the desired state to the actual DB
./run.sh apply
```

## Testing

I have included a Jupyter Notebook to test whether the setup actually working using `clickhouse_driver` and some custome methods. Feel free to check out the notebook!