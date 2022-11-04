#!/bin/bash


# DATABASE DEFINITION

DEFAULT_SCHEMA_SQL_FILE="./schemas_25112021.sql"
schema_file="$DEFAULT_SCHEMA_SQL_FILE"

TARGET_DB_LIST="hyu1278-act-newu
hyu1278-act-newu-efi
hyu1309-act-theta3
hyu1309-act-theta3-efi
hyu1312-act-nu
hyu1312-act-nu-efi"

# DATABSE PRODUCTION VAR
PRODUCTION_DB="production"
DEFAULT_PRODUCTION_DATA_SQL_FILE="production_data.sql"

# DUMP INFO
DEFAULT_DUMP_DIR="Dump20221022_backup_mysql_8.0.20"
DEFAULT_DUMP_DB_PREFIX="Dump20211123-"
LAST_DUMP_DIR="Dump20221022_backup_mysql_8.0.20"
export NOPAUSE=0
export DOIT=1
