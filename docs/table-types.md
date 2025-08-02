# Table Types

Standard table structures and when to use each type in the Object Evolution Framework.

## Overview

The OEF uses a suffix-based naming convention to indicate table structure and behavior. Each table name ends with a suffix that defines its type and temporal characteristics:

- **Base Type:** Single letter indicating the fundamental table structure (H, R, O, E, AX, SX, C)
- **Time Period:** Optional second letter for temporal variants (D, W, M, Q, Y)

Examples:
- `entity_organization_h` - Historical table tracking organization changes
- `user_r` - Registry table mapping source IDs to business object IDs
- `salesforce_contact_o` - Override table for Salesforce contact data
- `user_login_e` - Event table for user login events  
- `user_ad` - Daily aggregate table for user activity
- `account_sm` - Monthly snapshot table for accounts
- `entity_organization_c` - Current state of organizations

All tables include standardized meta fields for auditing and change tracking. Field ordering follows consistent patterns: primary keys first, time fields, foreign keys (alphabetical), attributes (alphabetical), then meta fields.

## H - Historical Tables

**Purpose:** SCD Type 2 tracking of every change to object attributes over time

**Structure:**
- **Primary Key(s):** 1 or more fields. For relationships, primary object listed first
- **valid_from:** Timestamp when this version became effective (UTC)
- **valid_to:** Timestamp when this version ended (9999-12-31 for current record, UTC)
- **Foreign Keys:** (VLTX layer onwards only) Alphabetical order
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

**Purpose:** Map key source identifiers to business object identifiers. Each business object type has exactly one "key source" that maintains 1:1 cardinality with business objects and drives business object creation.

**Structure:**
- **key_source_id:** The authoritative identifier from the key source (e.g., email address, DUNS number)
- **business_object_id:** Generated business object identifier (e.g., entity-person.com-us.35F261H)
- **assignment_rank:** Sequential tracking for ID generation process
- **Meta fields:** Standard audit fields

**Business Object ID Generation:**
- **Character set:** 0-9 plus uppercase consonants (30-31 characters total)
- **Structure:** `{object-type}.{qualifier}.{generated-key}`
- **Process:** Pre-generated randomized pool with sequential assignment
- **Length:** 7 characters provides ~17 billion unique combinations

**Key Source Rules:**
- **One key source per business object type:** Exactly one source maintains 1:1 cardinality
- **Key source drives creation:** New key source ID = new business object ID  
- **Non-key sources resolve:** Many-to-one mapping to existing business objects through mapping logic

**Processing:**
1. Scan incoming source data for distinct key source values
2. Anti-join against existing registry to find new values needing assignment
3. Query current registry for maximum assigned position
4. Assign incremental positions to new values (max + 1, max + 2, etc.)
5. Join incremental assignments to pre-generated pool by assignment order
6. Update registry with new mappings

**Configurations:**

**Optional:**
- **_initial_date:** String date (e.g., "2020-01-01")
- **_delta_limit:** Positive integer
- **_rollback_days:** Positive integer (can be 0)

**Layer Restrictions:**
- **VLTX layer only** - R tables only exist in the VLTX layer

**Key Features:**
- Immutable mappings: Once a key source ID is mapped to a business object ID, that relationship never changes
- Current mappings only: No temporal fields - registry contains only active mappings
- Migration capable: Key source changes replace entire registry structure with coordinated rebuild

**Usage Patterns:**
- **Business object resolution:** [To be documented]
- **Source system lineage:** [To be documented]
- **Cross-source consolidation:** [To be documented]

## O - Override Tables

**Purpose:** Manual configuration via CSV seeds to override or add fields to any table at any processing layer. Provides escape hatch for edge cases and special processing requirements.

**Structure:**
- **Primary Keys:** Same PKs as target table, but no time fields (e.g., for H table, includes object IDs but not valid_from)
- **Override Fields:** Any attribute fields that should override or add to the target table
- **Meta Fields:** Framework control fields (e.g., meta_is_primary)

**Processing:**
- Override table joined to target table on PK fields
- Override fields take precedence over source fields
- New fields get added to the result
- Meta fields influence framework processing logic

**Common Use Cases:**
- **Primary designation:** Add `meta_is_primary` flag to specific source objects to override "most recent" selection logic
- **Data correction:** Override incorrect values from source systems
- **Synthetic entities:** Add entities required for referential integrity
- **Special handling:** Flag records for custom processing logic

**Layer Placement:**
- Can exist at any layer where overrides are needed
- Named to match target table with O suffix (e.g., `salesforce_contact_o`)
- Acts as input TO the layer's processing, not output FROM it

**Configuration:**
- Sourced from CSV files in seeds/ directory
- No temporal configurations needed (inherits from target table)
- No unique_key required (uses target table's PK structure)

**Examples:**
```csv
# salesforce_contact_o.csv
contact_id,meta_is_primary
12345,true
67890,false
```

**Usage Patterns:**
- **VLTX processing:** Most common use case - flag primary sources for record selection
- **Data quality:** Override problematic source values
- **Business rules:** Add custom flags for special processing
- **Missing data:** Provide values not available in source systems

## E - Event Tables

**Purpose:** One row per event, tracking activities and actions related to business objects.

**Structure:**
- **event_id:** Optional identifier, not enforced as a true primary key.
- **event_time:** Timestamp when the event occurred (UTC)
- **Foreign Keys:** (VLTX layer onwards) Related business objects, alphabetical order
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

**Purpose:** Counts and summarizes events within given periods. Usually aggregated from E tables and denormalized in the WHX layer.

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
- `entity_organization_hd` - Daily historical snapshots of organizations
- `user_login_aw` - Weekly user login activity aggregates
- `account_sm` - Monthly account snapshots
- `entity_organization_c` - Current state of organizations

**Key Behaviors:**
- Period tables always include the most recent data available, even if the current period is incomplete
- Incomplete periods are continuously updated until the period closes
- Historical periods remain immutable once closed