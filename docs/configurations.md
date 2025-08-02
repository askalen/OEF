# Configurations

Configuration options for OEF models, covering both builder-specified settings and framework-managed configurations.

## Builder-Specified Configurations

These configurations are set by engineers building tables and control data processing behavior. Set these in your model's `config()` block.

**Note:** Configurations with underscore prefixes (`_initial_date`, `_delta_limit`, `_rollback_days`) are custom configurations added by the OEF package. Standard dbt configurations like `unique_key` use the normal dbt format.

### unique_key

**Purpose:** Defines the primary key constraint for incremental processing and ensures proper merge behavior.

**Required For:** H, R, AX, SX, C table types  
**Optional For:** E table types  
**Format:** Array of string field names in standard dbt format

**Requirements by Table Type:**
- **H tables:** Must include primary object ID(s) AND `valid_from`
- **R tables:** Must include primary object ID (single object only) AND `valid_from`  
- **AX tables:** Must include primary object ID(s) AND `period_begin`
- **SX tables:** Must include primary object ID(s) AND `valid_at`
- **C tables:** Must include primary object ID(s) only (no time field)

**Examples:**
```sql
-- Single primary key H table
{{ config(
  unique_key = ['customer_id', 'valid_from']
) }}

-- Multi-key relationship H table  
{{ config(
  unique_key = ['customer_id', 'account_id', 'valid_from']
) }}

-- AX aggregate table
{{ config(
  unique_key = ['user_id', 'event_type', 'period_begin']
) }}

-- SX snapshot table
{{ config(
  unique_key = ['customer_id', 'valid_at']
) }}

-- C current state table
{{ config(
  unique_key = ['customer_id']
) }}
```

### _initial_date

**Purpose:** Overrides the automatic starting point for data processing when building a table for the first time.

**Required For:** None  
**Optional For:** H, R, E, AX, SX table types  
**Format:** String date in "YYYY-MM-DD" format

**Behavior:**
- By default, tables start processing from the latest common start date among their upstream sources
- This config allows you to set a later start date to avoid processing unnecessary historical data
- Used only on the first run when no existing data exists
- Ignored on subsequent runs - the system uses cursor tracking instead

**Usage Guidelines:**
- Use when you don't need the full available history from source systems
- Can significantly reduce initial processing time for tables with long source histories
- Should align with business requirements for historical data retention
- Consider downstream dependencies that may need the earlier data

**Examples:**
```sql
-- Skip early history and start from business milestone
-- (even if sources have data back to 2010)
{{ config(
  _initial_date = '2020-01-01'
) }}

-- Start from recent date for performance reasons
{{ config(
  _initial_date = '2023-01-01'
) }}
```

### _delta_limit

**Purpose:** Limits the amount of data processed in a single run to manage performance and prevent timeouts.

**Required For:** None  
**Optional For:** H, R, E, AX, SX table types  
**Format:** Positive integer representing days

**Behavior:**
- **SRC tables:** Limits forward progress to X days from current cursor position
- **Non-SRC tables:** Limits forward progress based on upstream dependencies
- **SX tables:** Must be greater than or equal to the period length (e.g., 7+ for weekly tables)
- Processing continues from where it left off on subsequent runs
- Creates backfilling behavior when processing large historical periods
- Tables that haven't caught up yet are flagged for backfilling and can run in separate backfill processes

**Usage Guidelines:**
- Should be larger than the time period between runs, or the table will never catch up
- Use for tables that take longer than 5-10 minutes on large clusters for better efficiency
- Generally, 3 runs at 10 minutes can process more data than 1 run at 30 minutes
- Once the table catches up, the limit remains as a maximum processing window
- If left empty, the entire available period processes in a single run (fine for smaller tables)
- Consider balancing run frequency with processing efficiency

**Examples:**
```sql
-- Process 30 days at a time for large volume table
{{ config(
  _delta_limit = 30
) }}

-- Weekly table must process at least 7 days
{{ config(
  _delta_limit = 14
) }}
```

### _rollback_days

**Purpose:** Controls automatic rollback behavior to handle late-arriving data, ensure period completeness, and provide safety mechanisms.

**Required For:** None  
**Optional For:** H, R, E, AX, SX table types  
**Format:** Positive integer representing days (can be 0)  
**Default:** 0 for AX and SX tables (always have some rollback), no default for others

**Behavior:**
- **0 (recommended for most tables):** Rolls back to the last effective timestamp in the meta table
  - **Non-X tables:** Safety mechanism in case meta cursor gets adjusted unexpectedly
  - **X tables:** Rolls back to start of last complete period to avoid leaving incomplete historical records
- **Positive integer:** Rolls back X days from current processing cursor, extending beyond the safety rollback
- Applied before each run to ensure data consistency
- Larger values provide wider windows for late-arriving data but increase processing time

**Usage Guidelines:**
- Use 0 for most tables as a safety mechanism and period completeness guarantee
- Use positive values when source systems have known patterns of late-arriving data
- Higher values increase processing time but improve data completeness for out-of-order scenarios
- Consider using separate periodic rollback jobs instead of rolling back on every run
- Balance late-data handling needs with processing efficiency requirements

**Examples:**
```sql
-- Standard safety rollback for most tables
{{ config(
  _rollback_days = 0
) }}

-- Handle known 3-day late arriving data pattern
{{ config(
  _rollback_days = 3
) }}

-- Weekly aggregate with extended rollback for data quality
{{ config(
  _rollback_days = 7,
  _delta_limit = 30
) }}
```

## Framework Configurations

The following configurations are set automatically by the OEF framework in `dbt_project.yml` and should not be modified in individual models. These ensure consistent behavior across all tables of the same type.

**Automatically Set Configurations:**
- `materialized` - Table materialization strategy
- `incremental_strategy` - Merge vs insert strategies
- `cluster_by` - Snowflake clustering keys for performance
- `incremental_predicates` - Optimization predicates for incremental processing
- `pre-hook` - Framework processing hooks
- `post-hook` - Framework metadata management
- Database and schema assignments

**Layer-Specific Configurations:**

### SRC Layer
- **H tables:** Merge strategy with clustering on `date(valid_to)`, incremental predicates for current records
- **E tables:** Insert strategy with clustering on `date(event_time)`

### VLTX Layer
- **R tables:** Full refresh strategy (registries rebuilt each run)
- **H tables:** Merge strategy optimized for business object processing
- **E tables:** Insert strategy with business object clustering

### VLT Layer
- **H tables:** Merge strategy with cross-source consolidation optimization
- **E tables:** Insert strategy with consolidated event processing

### WHX Layer
- **H tables:** Merge strategy optimized for denormalization
- **E tables:** Insert strategy with dimensional context

### WH Layer
- **H tables:** Merge strategy with embedded metrics
- **E tables:** Insert strategy with enriched dimensional data
- **AX tables:** Merge strategy with period-based clustering
- **HX tables:** Merge strategy with period-based change detection

**Important:** Do not override these configurations in your model config blocks. They are carefully designed to work with the OEF processing framework and changing them may cause data integrity issues or processing failures.