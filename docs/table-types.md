# Table Types

Standard table structures and when to use each type in the Object Evolution Framework.

## Overview

The OEF uses a suffix-based naming convention to indicate table structure and behavior. Each table name ends with a suffix that defines its type and temporal characteristics:

- **Base Type:** Single letter indicating the fundamental table structure (H, R, E, AX, SX, C)
- **Time Period:** Optional second letter for temporal variants (D, W, M, Q, Y)

Examples:
- `customer_h` - Historical table tracking customer changes
- `login_e` - Event table for login events  
- `user_activity_ad` - Daily aggregate table for user activity
- `account_snapshot_sm` - Monthly snapshot table for accounts
- `customer_hc` - Current state of customers

All tables include standardized meta fields for auditing and change tracking. Field ordering follows consistent patterns: primary keys first, time fields, foreign keys (alphabetical), attributes (alphabetical), then meta fields.

## H - Historical Tables

**Purpose:** SCD Type 2 tracking of every change to object attributes over time

**Structure:**
- **Primary Key(s):** 1 or more fields. For relationships, primary object listed first
- **valid_from:** Timestamp when this version became effective (UTC)
- **valid_to:** Timestamp when this version ended (9999-12-31 for current record, UTC)
- **Foreign Keys:** (FCT layer onwards only) Alphabetical order
- **Attributes:** Alphabetical order  
- **meta_audit:** [Link to meta fields section]
- **meta_changes:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Configurations:**

**Mandatory:**
- **unique_key:** Standard dbt format, array of string field names. Must include primary object ID(s) AND valid_from

**Optional:**
- **_initial_date:** String date (e.g., "2020-01-01")
- **_delta_limit:** Positive integer
- **_rollback_days:** Positive integer (can be 0)

**Temporal Variants:**
- **HX tables:** Same structure, but changes only checked each period instead of tracking every individual change. So HW would check at the start of each week, and if the object had any changes it would add one new row.
- **Current data handling:** HX tables include the most recent timestamp available in addition to period boundaries (e.g., HW shows weekly timestamps plus current state for maximum data currency)

**Usage Patterns:**
- **Point-in-time snapshotting:** [To be documented]
- **Point-in-time joins:** [To be documented] 
- **Change tracking with meta fields:** [To be documented]

## R - Registry Tables

**Purpose:** Combination of business vault hub and historical mapping of source objects to business objects. Defines business object existence and tracks which source system objects map to each business object over time.

**Structure:**
- **Primary Key:** The business object identifier
- **valid_from:** Timestamp when this mapping became effective (UTC)
- **valid_to:** Timestamp when this mapping ended (9999-12-31 for current record, UTC)
- **Foreign Keys:** Source IDs corresponding to this business object, one per source system, alphabetical order
- **meta_audit:** [Link to meta fields section]
- **meta_changes:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Configurations:**

**Mandatory:**
- **unique_key:** Standard dbt format, array of string field names. Must include primary object ID (only one object for R tables) AND valid_from

**Optional:**
- **_initial_date:** String date (e.g., "2020-01-01")
- **_delta_limit:** Positive integer
- **_rollback_days:** Positive integer (can be 0)

**Temporal Variants:**
- **RC tables:** Current state view of the registry, essentially a hub table. Same structure as R but without valid_to field (since it only shows current mappings)

**Layer Restrictions:**
- **Business Vault layer only** - R tables only exist in the BV layer

**Key Features:**
- Enforces one source object per system mapping to a business object at any given time
- Logic exists to determine preference when data shows multiple source objects from same system
- Acts as both hub (defines business object existence) and historical mapping table

**Usage Patterns:**
- **Business object resolution:** [To be documented]
- **Source system lineage:** [To be documented]
- **Mapping conflict resolution:** [To be documented]

## E - Event Tables

**Purpose:** One row per event, tracking activities and actions related to business objects.

**Structure:**
- **event_id:** Optional identifier, not enforced as a true primary key.
- **event_time:** Timestamp when the event occurred (UTC)
- **Foreign Keys:** (BV layer onwards) Related business objects, alphabetical order
- **Attributes:** Alphabetical order
- **meta_audit:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Configurations:**

**Optional:**
- **_initial_date:** String date (e.g., "2020-01-01")
- **_delta_limit:** Positive integer
- **_rollback_days:** Positive integer (can be 0)

**Usage Patterns:**
- **Event analysis:** [To be documented]
- **Activity tracking:** [To be documented]
- **Behavioral aggregation:** [To be documented]

## AX - Aggregate Tables

**Purpose:** Counts and summarizes events within given periods. Usually aggregated from E tables and denormalized in the INT layer.

**Structure:**
- **Primary Key(s):** 1 or more fields. For relationships, primary object listed first
- **event_type:** Type of event being aggregated
- **period_begin:** Start of aggregation period (timestamp or date, UTC)
- **period_end:** End of aggregation period (timestamp or date, UTC)
- **Foreign Keys:** Related business objects, alphabetical order
- **Attributes:** Aggregated measures, alphabetical order
- **meta_audit:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Configurations:**

**Mandatory:**
- **unique_key:** Standard dbt format, array of string field names. Must include primary object IDs AND period_begin

**Optional:**
- **_initial_date:** String date (e.g., "2020-01-01")
- **_delta_limit:** Positive integer
- **_rollback_days:** Positive integer (DEFAULT 0, these tables always have some element of rollback)

**Temporal Variants:**
- **AX tables only:** No base A table exists - always has time period suffix (e.g., AD for daily, AW for weekly, AM for monthly)
- **Current period handling:** Includes most recent incomplete period - gets overwritten with each run until period is complete

**Usage Patterns:**
- **Time-series analysis:** [To be documented]
- **Trend tracking:** [To be documented]
- **Performance metrics:** [To be documented]

## SX - Periodic Snapshots

**Purpose:** Point-in-time snapshots for reporting purposes at regular intervals. Derivable from HX and H tables but optimized for reporting consumption.

**Structure:**
- **Primary Key(s):** 1 or more fields. For relationships, primary object listed first
- **valid_at:** Dates or timestamps separated by time period
- **Foreign Keys:** Related business objects, alphabetical order
- **Attributes:** Alphabetical order
- **meta_audit:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Configurations:**

**Mandatory:**
- **unique_key:** Standard dbt format, array of string field names. Must include primary object IDs AND period_begin

**Optional:**
- **_initial_date:** String date (e.g., "2020-01-01")
- **_delta_limit:** Positive integer, must be greater than or equal to the days in the period
- **_rollback_days:** Positive integer (DEFAULT 0, these tables always have some element of rollback)

**Temporal Variants:**
- **SX tables only:** No base S table exists - always has time period suffix (e.g., SD for daily, SW for weekly, SM for monthly)

**Key Features:**
- Reporting-optimized structure
- Derivable from H and HX tables
- Regular time intervals

**Usage Patterns:**
- **Point-in-time reporting:** [To be documented]
- **Dashboard optimization:** [To be documented]
- **Historical comparisons:** [To be documented]

## C - Current State Tables

**Purpose:** Single current state of objects or entities for reporting purposes. No historical tracking - just the most recent state.

**Structure:**
- **Primary Key(s):** 1 or more fields. For relationships, primary object listed first
- **updated_at:** Timestamp when this state was last updated (UTC)
- **Foreign Keys:** Related business objects, alphabetical order
- **Attributes:** Alphabetical order
- **meta_audit:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Configurations:**

**Mandatory:**
- **unique_key:** Standard dbt format, array of string field names. Must include primary object IDs AND period_begin

**Key Features:**
- Single row per object/entity
- No valid_to field - always current state
- Optimized for current state queries
- Common in MART layer for reporting

**Usage Patterns:**
- **Current state reporting:** [To be documented]
- **Dashboard current values:** [To be documented]
- **Operational reporting:** [To be documented]

## Time Variants

Time period suffixes modify base table types to create period-based structures:

- **D:** Daily (default if unspecified)
- **W:** Weekly
- **M:** Monthly
- **Q:** Quarterly
- **Y:** Yearly

**Usage Examples:**
- `customer_hd` - Daily historical snapshots of customers
- `login_aw` - Weekly login activity aggregates
- `account_sm` - Monthly account snapshots
- `customer_hc` - Current state of customers

**Key Behaviors:**
- Period tables always include the most recent data available, even if the current period is incomplete
- Incomplete periods are continuously updated until the period closes
- Historical periods remain immutable once closed