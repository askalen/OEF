# Table Types

Standard table structures and when to use each type in the Object Evolution Framework.

## Overview

The OEF uses a suffix-based naming convention to indicate table structure and behavior. Each table name ends with a suffix that defines its type and temporal characteristics:

- **Base Type:** Single letter indicating the fundamental table structure (H, R, M, E, A, S)
- **Time Period:** Optional second letter for temporal variants (D, W, M, Q, Y)

Examples:
- `customer_h` - Historical table tracking customer changes
- `login_e` - Event table for login events  
- `user_activity_ad` - Daily aggregate table for user activity
- `account_snapshot_sm` - Monthly snapshot table for accounts

All tables include standardized meta fields for auditing and change tracking. Field ordering follows consistent patterns: primary keys first, time fields, foreign keys (alphabetical), attributes (alphabetical), then meta fields.

## H - Historical Tables

**Purpose:** SCD Type 2 tracking of every change to object attributes over time

**Structure:**
- **Primary Key(s):** 1 or more fields. For relationships, primary object listed first
- **valid_from:** Timestamp when this version became effective (UTC)
- **valid_to:** Timestamp when this version ended (9999-12-31 for current record, UTC)
- **Foreign Keys:** (INT layer onwards only) Alphabetical order
- **Attributes:** Alphabetical order  
- **meta_audit:** [Link to meta fields section]
- **meta_changes:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

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

## M - Mapping Tables

[To be documented]

## E - Event Tables

**Purpose:** One row per event, tracking activities and actions related to business objects.

**Structure:**
- **event_id:** Optional identifier, not enforced as a true primary key.
- **event_time:** Timestamp when the event occurred (UTC)
- **Foreign Keys:** (BV layer onwards) Related business objects, alphabetical order
- **Attributes:** Alphabetical order
- **meta_audit:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Usage Patterns:**
- **Event analysis:** [To be documented]
- **Activity tracking:** [To be documented]
- **Behavioral aggregation:** [To be documented]

## A - Aggregate Tables

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

**Temporal Variants:**
- **AX tables:** Period-based aggregations (e.g., AD for daily, AW for weekly, AM for monthly)
- **Current period handling:** Includes most recent incomplete period - gets overwritten with each run until period is complete

**Usage Patterns:**
- **Time-series analysis:** [To be documented]
- **Trend tracking:** [To be documented]
- **Performance metrics:** [To be documented]

## S - Snapshot Tables

**Purpose:** Point-in-time snapshots for reporting purposes. Derivable from HX and H tables but optimized for reporting consumption.

**Structure:**
- **Primary Key(s):** 1 or more fields. For relationships, primary object listed first
- **valid_at:** Dates or timestamps separated by time period, plus a 'current' option
- **Foreign Keys:** Related business objects, alphabetical order
- **Attributes:** Alphabetical order
- **meta_audit:** [Link to meta fields section]
- **meta_datahash:** [Link to meta fields section]

**Temporal Variants:**
- **SX tables only:** No base S table exists - always has time period suffix (e.g., SD for daily, SW for weekly, SM for monthly)

**Key Features:**
- Reporting-optimized structure
- Derivable from H and HX tables
- Regular time intervals plus current state

**Usage Patterns:**
- **Point-in-time reporting:** [To be documented]
- **Dashboard optimization:** [To be documented]
- **Historical comparisons:** [To be documented]

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

**Key Behaviors:**
- Period tables always include the most recent data available, even if the current period is incomplete
- Incomplete periods are continuously updated until the period closes
- Historical periods remain immutable once closed