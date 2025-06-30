# Layers

Data processing layers from raw to analytics-ready. Each layer has a specific purpose in transforming source data into standardized business-ready analytics tables.

## IN - Ingestion Layer

**Purpose:** Standardizes raw source data into OEF table structures without applying business logic. Focuses on structural transformation, field organization, change detection, and splitting fast-changing objects into slow attributes and fast events.

**Key Transformations:**
- Converts data to standard OEF format (H or E table structures)
- Removes rows without attribute changes
- Splits fast-changing object tables into slow attribute H tables and fast event E tables
- Isolates primary keys and aligns on single time fields
- Organizes fields into standard order (PK, Time, FK, Attribute, Meta)
- Adds standardized meta fields
- Minimal business logic - only field renaming when absolutely necessary (reserved name conflicts)

#### H Tables

**Purpose:** Track source object attribute changes in SCD Type 2 format, focusing only on actual changes
**Configs:** See [H - Historical Tables](table-types.md#h-historical-tables) for standard configurations  
**Template:** [Link to in_template_h.sql]

#### E Tables

**Purpose:** Capture source system events and fast-changing attributes that were split from object tables
**Configs:** See [E - Event Tables](table-types.md#e-event-tables) for standard configurations
**Template:** [Link to in_template_e.sql]

## DV - Data Vault

**Purpose:** Normalizes historical tables around source objects and relationships. Serves as an intermediate step before business object normalization, maintaining source system perspective while preparing for business vault transformation.

#### H Tables

**Purpose:** Source object and relationship normalization without business logic transformation
**Configs:** See [H - Historical Tables](table-types.md#h-historical-tables) for standard configurations
**Template:** [Link to dv_template_h.sql]

## BV - Business Vault

**Purpose:** Normalizes data around business objects and relationships. Creates authoritative mapping from source objects to business objects and maintains complete business object histories and events.

**Processing Order:** R tables are built first to establish source-to-business object mappings, then used to align source objects into business objects for H and E tables.

#### R Tables

**Purpose:** Registry tables that map source system objects to business objects over time and define business object existence
**Configs:** See [R - Registry Tables](table-types.md#r-registry-tables) for standard configurations
**Layer Restriction:** R tables only exist in the BV layer
**Template:** [Link to bv_template_r.sql]

#### H Tables

**Purpose:** Business object attribute changes over time, normalized using R table mappings
**Configs:** See [H - Historical Tables](table-types.md#h-historical-tables) for standard configurations
**Template:** [Link to bv_template_h.sql]

#### E Tables

**Purpose:** Business events normalized using business object identifiers from R tables
**Configs:** See [E - Event Tables](table-types.md#e-event-tables) for standard configurations
**Template:** [Link to bv_template_e.sql]

## FCT - Fact Layer

**Purpose:** Denormalizes business objects from the BV layer to prepare for aggregation. Combines related business objects and events into wide tables optimized for analytical processing and aggregation in the OUT layer.

#### H Tables

**Purpose:** Denormalized business object attributes with related dimensional context for aggregation preparation
**Configs:** See [H - Historical Tables](table-types.md#h-historical-tables) for standard configurations
**Template:** [Link to fct_template_h.sql]

#### E Tables

**Purpose:** Denormalized business events with full dimensional context for aggregation and analysis
**Configs:** See [E - Event Tables](table-types.md#e-event-tables) for standard configurations
**Template:** [Link to fct_template_e.sql]

## OUT - Output Layer

**Purpose:** Creates official aggregated metrics and period-based dimensional data. Combines aggregated measures with dimensional information from the FCT layer to produce comprehensive, authoritative analytical tables.

#### HX Tables

**Purpose:** Period-based dimensional data that checks for changes less frequently than standard H tables (e.g., weekly checks instead of every change). Essential for tables that would change too frequently if tracked at every modification.
**Configs:** See [H - Historical Tables](table-types.md#h-historical-tables) for standard configurations (time period variants)
**Template:** [Link to out_template_hx.sql]

#### AX Tables

**Purpose:** Official aggregated metrics and counts organized by time periods, blended with dimensional information
**Configs:** See [A - Aggregate Tables](table-types.md#a-aggregate-tables) for standard configurations
**Template:** [Link to out_template_ax.sql]

## MART - Mart Layer

**Purpose:** Flexible, use-case-specific tables optimized for consumption by business teams and applications. Less structured than other layers to accommodate diverse reporting and analytical needs.

**Database Structure:** Separate database with use-case-based schemas (department, major reporting project, etc.)
**Schema Naming:** Schemas serve as table prefixes (e.g., `finance_user_hc.sql`)
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