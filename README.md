# Installation
- Install `atlasgo` using this link: https://atlasgo.io/getting-started/#installation
- Install `Docker`

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
echo -e 'CREATE TABLE `test`.`orders_log` (\n  `before.id` Int64,\n  `before.date` DateTime,\n  `before.price` Int64,\n  `before.cancelled` Bool,\n\n  `after.id` Int64,\n  `after.date` DateTime,\n  `after.price` Int64,\n  `after.cancelled` Bool,\n\n  `source.lsn` UInt64,\n  op String \n) engine = MergeTree order by (`source.lsn`);' >> schema.sql

# schema migration
./run.sh migrate create_log_table

# apply the changes from the desired state to the actual DB
./run.sh apply
```
## Add cdc table
```
# append the creation of the cdc table
echo -e 'CREATE TABLE `test`.`orders_cdc` (\n  id Int64,\n  date DateTime,\n  price Int64,\n  cancelled Bool,\n\n  version UInt64,\n  deleted UInt8 \n) engine = ReplacingMergeTree(version, deleted) order by (id);' >> schema.sql

# schema migration
./run.sh migrate create_cdc_table

# apply the changes from the desired state to the actual DB
./run.sh apply
```

## Inspect the changes on the web
```
./run.sh web
```

## Modify the tables within `schema.sql`
```
# modify `schema.sql` (e.g. add `before.note` and `after.note` columns to `orders_log` then add `note` column to `orders_cdc`)

# apply the changes from the desired state to the actual DB
./run.sh apply

# schema migration
./run.sh migrate updated_tables
```
