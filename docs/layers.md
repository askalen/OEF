# Data Warehouse Layers

Data processing layers from raw to analytics-ready. The OEF uses six schemas organized into three conceptual layers, each with a specific purpose in transforming source data into standardized business-ready analytics tables.

## Three-Layer Architecture Overview

**Source Layer (SRC):** Standardizes raw data into OEF structures  
**Vault Layer (VLTX + VLT):** Creates authoritative business object definitions  
**Warehouse Layer (WHX + WH):** Produces denormalized, metric-rich analytics tables

## SRC - Source Layer

**Purpose:** Standardizes raw source data into OEF table structures without applying business logic. Focuses on structural transformation, field organization, change detection, and splitting fast-changing objects into slow attributes and fast events.

**Key Transformations:**
- Converts data to standard OEF format (H or E table structures)
- Removes rows without attribute changes
- Splits fast-changing object tables into slow attribute H tables and fast event E tables
- Isolates primary keys and aligns on single time fields
- Organizes fields into standard order (PK, Time, FK, Attribute, Meta)
- Adds standardized meta fields
- Minimal business logic - only field renaming when absolutely necessary (reserved name conflicts)

### H Tables
**Purpose:** Track source object attribute changes in SCD Type 2 format, focusing only on actual changes  
**Configs:** See H - Historical Tables for standard configurations

### E Tables
**Purpose:** Capture source system events and fast-changing attributes that were split from object tables  
**Configs:** See E - Event Tables for standard configurations

## VLTX - Vault Transformation Layer

**Purpose:** Creates business object mappings and produces one representative record per business object per source system. Handles the transformation from source-oriented data to business-object-oriented data while maintaining source-level precision.

**Processing Order:** R tables are built first to establish source-to-business object mappings, then used by O tables for overrides, then H and E tables use both for business object alignment.

### R Tables
**Purpose:** Registry tables that map key source identifiers to business object identifiers.
**Layer-specific:** Only exist in VLTX layer - built first to establish mappings used by H and E tables.

### O Tables
**Purpose:** Override tables that provide manual configuration for special processing requirements.
**Layer-specific:** Add `meta_is_primary` field to specific source objects, which takes priority during VLTX record selection.

### H Tables
**Purpose:** Business object attributes per source system, with one representative record per business object.
**Layer-specific:** Uses registry mappings to transform source identifiers and applies override logic for record selection.

### E Tables
**Purpose:** Business events per source system.
**Layer-specific:** Normalized using business object identifiers from R tables.

## VLT - Vault Layer

**Purpose:** Creates the authoritative, consolidated business object definitions by aggregating across source systems. Combines data from multiple VLTX source tables using field-by-field business rules to produce the single source of truth for each business object.

**Key Characteristics:**
- Bounded complexity: Scales with number of sources (2-5), not number of records
- Field-by-field consolidation using business rules
- Preserves exact timestamps from source-level changes
- Clean separation between source deduplication and cross-source consolidation

### H Tables
**Purpose:** Consolidated business object attributes across all source systems.
**Layer-specific:** Uses COALESCE and business rules to select the best value for each field across multiple source systems.

### E Tables
**Purpose:** Consolidated business events across all source systems.

## WHX - Warehouse Transformation Layer

**Purpose:** Denormalizes business objects from the VLT layer to prepare for metric aggregation. Combines related business objects and events into wide tables optimized for analytical processing and aggregation in the WH layer.

### H Tables
**Purpose:** Denormalized business object attributes with related dimensional context.
**Layer-specific:** Prepares data for aggregation in the WH layer.

### E Tables
**Purpose:** Denormalized business events with full dimensional context.
**Layer-specific:** Optimized for aggregation and analysis in the WH layer.

## WH - Warehouse Layer

**Purpose:** Creates the final analytical tables with aggregated metrics and comprehensive dimensional information. Combines denormalized data from WHX with calculated measures to produce complete, analytics-ready tables.

### HX Tables
**Purpose:** Period-based dimensional data.
**Layer-specific:** Checks for changes less frequently than standard H tables (e.g., weekly checks instead of every change). Essential for tables that would change too frequently if tracked at every modification.

### AX Tables
**Purpose:** Aggregated metrics and counts organized by time periods.
**Layer-specific:** Blended with dimensional information from WHX layer.

### H Tables
**Purpose:** Denormalized business objects with embedded aggregate metrics.
**Layer-specific:** Final analytical tables with comprehensive metrics for analysis.

### E Tables
**Purpose:** Denormalized events with contextual metrics and dimensional data.
**Layer-specific:** Event data enriched with calculated measures and context.

## MART - Mart Layer

**Purpose:** Flexible, use-case-specific tables optimized for consumption by business teams and applications. Less structured than other layers to accommodate diverse reporting and analytical needs.

**Database Structure:** Separate database with use-case-based schemas (department, major reporting project, etc.)  
**Schema Naming:** Schemas serve as table prefixes (e.g., finance_user_hc.sql)  
**Table Ownership:** Owned and maintained by consuming teams rather than central data team

**Common Table Types:**
- **SX Tables:** Periodic snapshots for point-in-time reporting
- **HC Tables:** Current object state tables (single row per object, no valid_to field)
- **Custom Structures:** Flexible formats based on specific use case requirements

**Flexibility:**
- Less rigid field naming conventions
- JSON usage permitted where beneficial
- Structure optimized for consumption rather than processing efficiency
- Team-specific requirements take precedence over framework standards

## Supporting Schemas

### META
**Purpose:** Framework metadata tables for processing control, cursor tracking, and audit information.

### REF
**Purpose:** Stable reference tables like dates, regions, and other dimensional data that doesn't fit the business object model.

### EXTSRC
**Purpose:** External source data that is not part of the main ecosystem. Keeps separate data sources isolated while allowing downstream integration.

**Key Considerations:**
- May have different ingestion patterns or frequencies
- Less strict adherence to OEF standards initially
- Requires clear metadata to distinguish from core sources

### EXTWH
**Purpose:** External warehouse tables outside the core data warehouse ecosystem. Highly specialized datasets, data science models, or temporary tables for ad-hoc analysis.

**Key Considerations:**
- Often less governed, allowing for rapid experimentation
- Data lineage may be less formal
- Can be purged or rebuilt more frequently