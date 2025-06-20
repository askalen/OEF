# OEF Macro Reference

## Format Macros
- **format_array_to_lines()** - Takes array and returns formatted lines with configurable prefix/suffix/separator
- **format_sql()** - Takes SQL string and returns cleanly formatted and aligned SQL

## Get Macros  
- **get_model_config()** - Pulls configuration values from model/source YAML
- **get_table_meta()** - Pulls metadata for a single actual database table (useful for sources and meta rebuild)
- **get_model_meta()** - Pulls metadata on the model and its upstream tables from dbt graph

## Generate Macros
- **generate_h_finalization()** - Generates steps 4-6 of history table pattern (previous union, row removal, finalize)
- **generate_src_model()** - Determines which SRC sub-macro to call, runs output through formatter
- **generate_src_model_h()** - Generates complete SRC history table SQL
- **generate_src_model_e()** - Generates complete SRC event table SQL

## Set Macros
- **set_model_meta_lock()** - Sets lock_id in meta.model table for concurrency control
- **set_model_meta_begin()** - Creates meta.model entry in prehook
- **set_model_meta_end()** - Finalizes meta.model entry in posthook
- **set_run_meta_begin()** - Creates run entry in meta.run table
- **set_run_meta_end()** - Finalizes run entry in meta.run table

## Operation Macros
- **operation_rollback_table()** - Rolls back table data to specified date, updates meta tables
- **operation_backup_table()** - Creates Snowflake backup of individual table
- **operation_backup_database()** - Creates Snowflake backup of entire database  
- **operation_backup_schema()** - Creates Snowflake backup of schema
- **operation_load_table()** - Restores table from backup
- **operation_load_schema()** - Restores schema from backup
- **operation_load_database()** - Restores database from backup
- **operation_drop_table()** - Drops table and cleans up meta entries
- **operation_rebuild_meta()** - Rebuilds meta.model table by querying all database tables
- **operation_deploy_functions()** - Deploys custom Snowflake functions

## Process Macros
- **process_prehook()** - Coordinates all prehook activities (locking, meta setup, variable setting)
- **process_posthook()** - Coordinates all posthook activities (meta updates, cleanup)
- **process_mergehook()** - Coordinates activities on temporary incremental table before merge

## System Macros
- **system_generate_schema_name()** - Custom schema naming logic override
- **system_openupmergehook()** - Modifies dbt to enable merge-hook functionality *(name TBD)*

## Script Files
- **script_initialize_scaffold** - Wizard that sets up fresh repository structure and templates
- **script_run_backfill** - Checks database for backfill flags and executes run commands in loop