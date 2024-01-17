#!/bin/bash

CH_HOST=localhost
CH_PORT=9000
CH_URL="clickhouse://$CH_HOST:$CH_PORT"
CH_DEV_URL="docker://clickhouse/23.11"
MIGRATION_DIR="file://migrations"
SCHEMA_FILE="file://schema.sql"
PROJECT_NAME="clickhouse-sandbox"

if [ "$1" = "init" ]; then
    echo "Initializing Database..."
    docker run -d --name $PROJECT_NAME -p $CH_PORT:$CH_PORT -d clickhouse/clickhouse-server:latest
    exit 0
fi
# --url/-u = the URL of the database to connect to
# --to = a list of URLS to the desired state of the database
# --dev-url = the URL of the database for temporary and locally running database for Atlas to use to process and validate users' schemas, migrations, etc.
# --format = the format to use when printing the schema (in Go template format)
if [ "$1" = "inspect" ]; then
    atlas schema inspect -u $CH_URL --format '{{ sql . }}'
    exit 0
fi
if [ "$1" = "web" ]; then
    atlas schema inspect -u $CH_URL --web
    exit 0
fi


if [ "$1" = "diff" ]; then
    if [ "$2" = "" ]; then
        echo "Please provide a schema file to compare from"
        exit 1
    fi
    if [ "$3" = "" ]; then
        echo "Please provide a schema file to compare to"
        exit 1
    fi

    FROM="file://$2"
    if [ "$2" = "ch" ]; then
        FROM=$CH_URL
    fi

    TO="file://$3"
    if [ "$3" = "ch" ]; then
        TO=$CH_URL
    fi

    atlas schema diff --from $FROM --to $TO --dev-url $CH_DEV_URL
    exit 0
fi

if [ "$1" = "migrate" ]; then
    if [ "$2" = "" ]; then
      atlas migrate diff --dir $MIGRATION_DIR --to $SCHEMA_FILE --dev-url $CH_DEV_URL
      exit 0
    fi
    atlas migrate diff $2 --dir $MIGRATION_DIR --to $SCHEMA_FILE --dev-url $CH_DEV_URL
    exit 0
fi


if [ "$1" = "push" ]; then
    atlas migrate push $PROJECT_NAME --dev-url $CH_DEV_URL
    exit 0
fi

if [ "$1" = "check" ]; then
    atlas migrate lint --dir $MIGRATION_DIR --dev-url $CH_DEV_URL
    exit 0
fi
if [ "$1" = "cweb" ]; then
    atlas migrate lint --dir $MIGRATION_DIR --dev-url $CH_DEV_URL --web
    exit 0
fi

if [ "$1" = "apply" ]; then
    atlas schema apply -u $CH_URL --to $MIGRATION_DIR --dev-url $CH_DEV_URL
    exit 0
fi