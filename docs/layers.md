# Data Warehouse Layers

Data processing layers from raw to analytics-ready. The OEF uses six schemas organized into three conceptual layers, each with a specific purpose in transforming source data into standardized business-ready analytics tables.

## Layer Overview

The Object Evolution Framework transforms data lake data through four distinct transformation layers, like preparing a meal from shopping to serving:

<table>
<tr>
<td width="40%">
<img src="images/grocery.png" alt="Data Lake" width="100%">
</td>
<td width="60%">
<h3><a href="#data-lake">Data Lake</a></h3>
<strong>Source Systems & Raw Data</strong><br>
<em>"Shopping for ingredients"</em><br><br>
Raw data from various source systems stored in their original formats. Like ingredients scattered across different aisles in a grocery store - everything you need is available, but it requires selection and organization.
</td>
</tr>

<tr>
<td>
<img src="images/pantry.png" alt="Source Layer" width="100%">
</td>
<td>
<h3><a href="#src---source-layer">Source Layer</a></h3>
<strong>Structural Standardization</strong><br>
<em>"Organizing ingredients at home"</em><br><br>
Standardizes raw data into consistent OEF table structures without applying business logic. Like bringing groceries home and organizing them properly in your pantry and fridge - everything has its place and is ready for use.
</td>
</tr>

<tr>
<td>
<img src="images/counter.png" alt="Vault Layer" width="100%">
</td>
<td>
<h3><a href="#vlt---vault-layer">Vault Layer</a></h3>
<strong>Business Object Alignment</strong><br>
<em>"Measuring & prepping for recipe"</em><br><br>
Aligns source data around business objects and relationships. Like mise en place - every ingredient is measured, prepped, and organized; all laid out and ready to be combined as needed.
</td>
</tr>

<tr>
<td>
<img src="images/cake.png" alt="Warehouse Layer" width="100%">
</td>
<td>
<h3><a href="#wh---warehouse-layer">Warehouse Layer</a></h3>
<strong>Denormalization & Aggregation</strong><br>
<em>"Combining & cooking"</em><br><br>
Combines prepared data into metric-rich, denormalized tables optimized for analytics. Like the actual cooking process - ingredients are transformed and combined following your recipe to create the finished product.
</td>
</tr>

<tr>
<td>
<img src="images/slice.png" alt="Mart Layer" width="100%">
</td>
<td>
<h3><a href="#mart---mart-layer">Mart Layer</a></h3>
<strong>Use-Case Specific Tables</strong><br>
<em>"Serving individual portions"</em><br><br>
Flexible tables optimized for specific business teams and applications. Like cutting and plating the finished cake - the same core product served in different ways for different consumers and occasions.
</td>
</tr>
</table>

---

## Data Lake

Raw data storage from various source systems. The OEF framework assumes you have accessible data in columnar format - we focus on transformation, not initial data loading.

**Purpose:** Store all available source data in original formats for processing by the Source layer.

**Characteristics:**
- Data remains in original structure and format
- No transformations or business logic applied
- Serves as the foundation for all downstream processing
- Accessible via standard data lake technologies

---

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
**Purpose:** Registry tables that map key source identifiers to business object identifiers. Built first in VLTX to establish business object mappings, then used by both VLTX H/E tables and as the foundation for VLT consolidation.
**Layer-specific:** Only exist in VLTX layer but are used by VLT as the "starting table" for cross-source joins.

### O Tables
**Purpose:** Override tables that provide manual configuration for special processing requirements.
**Layer-specific:** Add `meta_is_primary` field to specific source objects, which takes priority during VLTX record selection.

### H Tables
**Purpose:** Business object attributes per source system, with one representative record per business object from that source.
**Layer-specific:** Uses registry mappings to transform source identifiers and applies override logic for record selection. Creates source-level business object alignment that VLT can then consolidate.

### E Tables
**Purpose:** Business events per source system.
**Layer-specific:** Normalized using business object identifiers from R tables.

## VLT - Vault Layer

**Purpose:** Creates the authoritative, consolidated business object definitions by aggregating across source systems. Uses VLTX registry tables as the foundation and left joins each source's VLTX tables to combine data using field-by-field business rules.

**Key Characteristics:**
- Bounded complexity: Scales with number of sources (2-5), not number of records
- Field-by-field consolidation using business rules
- Preserves exact timestamps from source-level changes
- Clean separation between source deduplication and cross-source consolidation

### H Tables
**Purpose:** Consolidated business object attributes across all source systems.
**Layer-specific:** Starts with VLTX registry tables and left joins each source's VLTX H table, using COALESCE and business rules to select the best value for each field across sources.

### E Tables
**Purpose:** Consolidated business events across all source systems.

## WHX - Warehouse Transformation Layer

**Purpose:** Denormalizes business objects from the VLT layer to prepare for metric aggregation. Brings dimensional attributes "down" from higher-level objects so they can be aggregated "up" in the WH layer. For example, brings Account attributes down to the User level so users can be aggregated up to Plan level with "users in owned accounts" metrics.

### H Tables
**Purpose:** Denormalized business object attributes with dimensional context from related objects.
**Layer-specific:** Brings attributes "down" from higher objects (e.g., Account attributes onto User records) to enable aggregation "up" to higher levels with rich dimensional context.

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