# **Data Warehouse Layers**

Data processing layers from raw to analytics-ready. Each layer has a specific purpose in transforming source data into standardized business-ready analytics tables.

## **SRC \- Source Layer (formerly IN \- Ingestion Layer)**

**Purpose:** Standardizes raw source data into OEF table structures without applying business logic. Focuses on structural transformation, field organization, change detection, and splitting fast-changing objects into slow attributes and fast events.

**Key Transformations:**

* Converts data to standard OEF format (H or E table structures)  
* Removes rows without attribute changes  
* Splits fast-changing object tables into slow attribute H tables and fast event E tables  
* Isolates primary keys and aligns on single time fields  
* Organizes fields into standard order (PK, Time, FK, Attribute, Meta)  
* Adds standardized meta fields  
* Minimal business logic \- only field renaming when absolutely necessary (reserved name conflicts)

#### **H Tables**

Purpose: Track source object attribute changes in SCD Type 2 format, focusing only on actual changes  
Configs: See H \- Historical Tables for standard configurations  
Template: \[Link to src\_template\_h.sql\]

#### **E Tables**

Purpose: Capture source system events and fast-changing attributes that were split from object tables  
Configs: See E \- Event Tables for standard configurations  
Template: \[Link to src\_template\_e.sql\]

## **EXTSRC \- External Source Layer**

**Purpose:** This layer houses ingested data sources that are *not* part of the main ecosystem. This keeps them separate from the primary data ingestion pipeline while still allowing them to be integrated downstream if needed. Data here might be less structured initially and require more specific transformations before joining the main data flow.

**Key Considerations:**

* May have different ingestion patterns or frequencies.  
* Less strict adherence to OEF standards initially.  
* Requires clear metadata to distinguish from core sources.

## **DV \- Data Vault**

**Purpose:** Normalizes historical tables around source objects and relationships. Serves as an intermediate step before business object normalization, maintaining source system perspective while preparing for business vault transformation.

#### **H Tables**

Purpose: Source object and relationship normalization without business logic transformation  
Configs: See H \- Historical Tables for standard configurations  
Template: \[Link to dv\_template\_h.sql\]

## **BV \- Business Vault**

**Purpose:** Normalizes data around business objects and relationships. Creates authoritative mapping from source objects to business objects and maintains complete business object histories and events.

**Processing Order:** R tables are built first to establish source-to-business object mappings, then used to align source objects into business objects for H and E tables.

#### **R Tables**

Purpose: Registry tables that map source system objects to business objects over time and define business object existence  
Configs: See R \- Registry Tables for standard configurations  
Layer Restriction: R tables only exist in the BV layer  
Template: \[Link to bv\_template\_r.sql\]

#### **H Tables**

Purpose: Business object attribute changes over time, normalized using R table mappings  
Configs: See H \- Historical Tables for standard configurations  
Template: \[Link to bv\_template\_h.sql\]

#### **E Tables**

Purpose: Business events normalized using business object identifiers from R tables  
Configs: See E \- Event Tables for standard configurations  
Template: \[Link to bv\_template\_e.sql\]

## **FCT \- Fact Layer**

**Purpose:** Denormalizes business objects from the BV layer to prepare for aggregation. Combines related business objects and events into wide tables optimized for analytical processing and aggregation in the ANL layer.

#### **H Tables**

Purpose: Denormalized business object attributes with related dimensional context for aggregation preparation  
Configs: See H \- Historical Tables for standard configurations  
Template: \[Link to fct\_template\_h.sql\]

#### **E Tables**

Purpose: Denormalized business events with full dimensional context for aggregation and analysis  
Configs: See E \- Event Tables for standard configurations  
Template: \[Link to fct\_template\_e.sql\]

## **ANL \- Analytics Layer (formerly OUT \- Output Layer)**

**Purpose:** Creates official aggregated metrics and period-based dimensional data. Combines aggregated measures with dimensional information from the FCT layer to produce comprehensive, authoritative analytical tables.

#### **HX Tables**

Purpose: Period-based dimensional data that checks for changes less frequently than standard H tables (e.g., weekly checks instead of every change). Essential for tables that would change too frequently if tracked at every modification.  
Configs: See H \- Historical Tables for standard configurations (time period variants)  
Template: \[Link to anl\_template\_hx.sql\]

#### **AX Tables**

Purpose: Official aggregated metrics and counts organized by time periods, blended with dimensional information  
Configs: See A \- Aggregate Tables for standard configurations  
Template: \[Link to anl\_template\_ax.sql\]

## **MART \- Mart Layer**

**Purpose:** Flexible, use-case-specific tables optimized for consumption by business teams and applications. Less structured than other layers to accommodate diverse reporting and analytical needs.

Database Structure: Separate database with use-case-based schemas (department, major reporting project, etc.)  
Schema Naming: Schemas serve as table prefixes (e.g., finance\_user\_hc.sql)  
Table Ownership: Owned and maintained by consuming teams rather than central data team  
**Common Table Types:**

* **SX Tables:** Periodic snapshots for point-in-time reporting  
* **HC Tables:** Current object state tables (single row per object, no valid\_to field)  
* **Custom Structures:** Flexible formats based on specific use case requirements

**Flexibility:**

* Less rigid field naming conventions  
* JSON usage permitted where beneficial  
* Structure optimized for consumption rather than processing efficiency  
* Team-specific requirements take precedence over framework standards

## **EXTANL \- External Analytics Layer**

**Purpose:** This layer is for analytics tables that are *outside* of your core data warehouse ecosystem. These might be highly specialized datasets, data science models, or temporary tables for ad-hoc analysis that don't need to conform to the strict structure of the ANL or MART layers.

**Key Considerations:**

* Often less governed, allowing for rapid experimentation.  
* Data lineage may be less formal.  
* Can be purged or rebuilt more frequently.