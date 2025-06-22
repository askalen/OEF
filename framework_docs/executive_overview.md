# Modern Data Engineering System: Executive Overview

## The Challenge

Organizations struggle to effectively transform their raw data into actionable business intelligence. Current approaches often result in fragmented data systems, inconsistent business logic, and high maintenance overhead. This creates delays in data delivery and reduces trust in reporting accuracy.

## Starting Point: Your Data Foundation

The system begins with your existing data landscape: raw data in any format that can be parsed into a columnar structure. The primary focus is on historical state data - information that tracks how business objects change over time. This includes:

* Core business data like customer information, product details, and organizational structures  
* Historical state changes and relationships between business entities  
* Event and log data that both leverage and enhance the historical state tracking

While the system handles various data types, it is optimized for slowly changing dimensions - data that updates periodically rather than continuously. This focus enables powerful historical analysis and state tracking.

## End State: Analytics-Ready Architecture

The system transforms your data into two key databases:

**Processing Database** - Builder/engineer access only:
* Contains all transformation and preparation work
* Multiple layers from raw source to analytics-ready objects
* Protects complex intermediate steps from end users
* One authoritative source for each business object and relationship

**Reporting Database** - Analyst and business user access:
* Contains only data mart schemas organized by purpose
* Schema-level permissions for governance
* Tailored tables for specific reporting needs
* Optimized for dashboard and tool performance

## Our Solution

We've developed a comprehensive data engineering system that transforms raw data into analytics-ready information through a state-focused, business-oriented approach. Built on enterprise-grade technology (Snowflake, dbt Core, and Apache Airflow), the system creates a clear path from source data to business intelligence. However, the methodology represents a design pattern that can be applied across various technology stacks, similar to how Kimball or other methodologies can be implemented on different platforms.

## System Architecture

### Core Principles

The system is designed around state-centric analytics, focusing on how business objects evolve through states over time rather than just discrete events. This enables flexible, accurate historical analysis of business objects while preparing them for any custom metric aggregation. The architecture isolates volatile components (like categorization logic) to minimize reprocessing and uses consistent structural patterns with clear naming conventions.

### Processing Database Architecture

The Processing Database transforms data through seven distinct layers:

1. **Raw Layer (RAW)**: Raw data from data lake
   - Original source data without modification
   - All formats and structures preserved
   - Foundation for all downstream processing

2. **Source Layer (SRC)**: Cleaned and structured versions of raw tables
   - No business logic applied
   - Standardizes table structure with only meaningful fields
   - Maintains alignment with source systems

3. **Vault Intermediate Layer (VIN)**: Handles complex transformations *(optional)*
   - Only created when needed for complex source transformations
   - Handles field mapping, source handoffs, and structural changes
   - Maintains DRY principles by centralizing transformation logic
   - Advanced option: Full Data Vault normalization for maximum future-proofing

4. **Vault Layer (VLT)**: Business Vault implementation
   - Standard Business Vault with Hub and Satellite tables
   - Normalizes around business objects, relationships, and events
   - First layer where D (Dimension) tables appear
   - Creates reliable foundation for downstream processing

5. **Analytics Intermediate Layer (AIN)**: Parallel processing layer
   - **Function 1**: Event aggregation by time periods and primary keys
   - **Function 2**: Denormalization of object/relationship tables
   - Introduction of HX (time-granular historical) tables
   - Prepares data for final analytical consumption

6. **Analytics Layer (ANA)**: "Golden tables" serving as sources of truth
   - Contains object/relationship tables with related properties
   - Contains object/relationship aggregate tables
   - Contains event tables structured like traditional fact tables
   - Only measures and dimensions outside this layer should be custom-purpose ones in data marts

7. **Mart Layer (MRT)**: Moved to Reporting Database
   - Purpose-built data marts for consumption
   - Schema-level organization by business function

### Reporting Database Architecture

The Reporting Database contains data marts organized into schemas:

* **Common Schema**: Joined tables for maximum convenience
* **Metrics Schema**: Official company metrics (metric store)
* **Departmental Schemas**: Team-specific customized tables
* **Reporting Schemas**: Tables optimized for specific reports and tools

## Table Types & Time Handling

The system uses consistent structural patterns indicated by table suffixes:

### Base Types
* **H** (Historical): SCD Type 2 tracking of every change to object attributes
* **HX** (Time-granular Historical): SCD Type 2 with rougher granularity using point-in-time slices
* **E** (Event): One row per event, may have business keys but no primary keys
* **EX** (Aggregate Event): Counts and summarizes events within given periods
* **D** (Dimension): Defines business objects or relationships (hub/link tables)
* **R** (Reference): Static data like dates, countries, enumeration mappings
* **A** (Attribute): EAV (Entity-Attribute-Value) structure for metric stores
* **PX** (Point-in-time): Date/time period as primary key, new row every period
* **C** (Current): Most recent record only with updated_last field

### Time Periods (X)
* **H/D**: Daily (default if unspecified)
* **W**: Weekly
* **M**: Monthly
* **Q**: Quarterly
* **Y**: Yearly

### Table Type Progression by Layer
* **RAW/SRC/VIN**: E, H, R (raw source structures)
* **VLT**: E, H, R, D (business objects identified)
* **AIN**: E, H, R, D, HX (time-granular aggregations)
* **ANA**: All types except PX, C (full analytical capability)
* **MRT**: All types (including PX, C for reporting-specific needs)

## Data Flow and Processing

Data flows systematically through each layer, with tables built by joining together tables in the same layer or those one layer upstream. The AIN layer performs parallel processing: one stream aggregates events by time periods and primary keys, while another stream denormalizes object and relationship tables. These streams converge in the ANA layer to create complete analytical objects.

## Implementation Strategy

### Foundation Phase

This critical first phase establishes the framework for all future development through three parallel workstreams:

**Discovery Phase** - Understanding the complete data landscape:
* Documentation of all data sources and their characteristics
* Identification of subject matter experts and key teams
* Development of organizational role hierarchies
* Creation of prioritization frameworks and timelines

**Planning Phase** - Creating the architectural blueprint:
* Definition and documentation of business objects
* Mapping of all possible relationships
* Creation of the complete design space
* Establishment of development priorities

**Initial Setup Phase** - Preparing the technical environment:
* Deployment of core tools (Snowflake, dbt, Airflow)
* Creation of security roles and access controls
* Configuration of databases and schemas

### Continuous Development Phase

Development proceeds incrementally through the layer structure:

**Processing Database Development**:
* Building tables according to established priorities
* Integration of new data sources
* Expanding coverage of the design space based on business needs

**Data Mart Development**:
* Creation of purpose-built tables for specific business needs
* Optimization for reporting and dashboard performance

**Testing and Migration**:
* Continuous validation of new tables and relationships
* Gradual transition of existing processes to the new system
* Systematic deprecation of legacy systems

## Deployment Strategy

The system deploys as a standalone solution, running parallel to existing processes. This approach allows for methodical validation and risk-free migration. Reports and tools can transition to the new system as their underlying data becomes available, ensuring business continuity.

## Technology Foundation

Built on proven enterprise tools:

* **Snowflake**: Provides cloud data warehouse infrastructure for both Processing and Reporting databases
* **dbt Core**: Manages data transformations between layers, ensuring consistent application of business logic and data quality checks
* **Apache Airflow**: Orchestrates the overall pipeline, managing scheduling and dependencies between transformation steps

The methodology serves as a design pattern that can be adapted to other technology stacks while maintaining the core principles of state-focused analytical architecture.

## Business Impact

### Rebuild Efficiency
Change categorization logic without recalculating expensive event aggregations. The modular design isolates volatile components to minimize reprocessing requirements.

### Historical Accuracy
Complete audit trail of all object state changes with accurate point-in-time analysis capabilities for any business question.

### Analytical Flexibility
Objects prepared for any metric aggregation pattern, supporting both planned and ad-hoc analytical requirements.

### Operational Clarity
Consistent naming and structure patterns across all tables, making the system intuitive for both technical and business users.

### Governance Simplicity
Clear database and schema separation for access control, with Processing Database protecting complex logic from end users while Reporting Database provides governed access.

## Risk Mitigation

The parallel deployment strategy eliminates disruption risk to existing processes. The use of industry-standard tools ensures long-term viability and access to skilled resources. Comprehensive documentation and standardized patterns reduce key person dependencies.

---

# Data Structure Examples: User Object Through the System

## Processing Database Flow

### VLT_USER_D (Vault User Dimension)
```
VLT_USER_D
- USER_ID (hub key)
- NATURAL_KEY (email)
- LOAD_DATE
- SOURCE_SYSTEM
```

### VLT_USER_H (Vault User Satellite)
```
VLT_USER_H
- USER_ID
- EFFECTIVE_FROM
- EFFECTIVE_TO
- NAME_FIRST
- NAME_LAST
- EMAIL
- DEPARTMENT
- TITLE
```

### ANA_USER_H (Analytics User Object)
```
ANA_USER_H
- USER_ID
- EFFECTIVE_FROM
- EFFECTIVE_TO
- -- Denormalized properties
- NAME_FIRST, NAME_LAST, EMAIL
- DEPARTMENT, TITLE
- MANAGER_NAME, MANAGER_EMAIL
- ACCOUNT_NAME, ACCOUNT_REGION
- -- Derived states
- IS_ACTIVE (from behavioral analysis)
- ENGAGEMENT_TIER (from activity patterns)
- RISK_SCORE (from trend analysis)
```

## Reporting Database Data Marts

### COMMON_USER_HD (Common Daily Metrics)
```
COMMON_USER_HD
- USER_ID
- DATE
- EFFECTIVE_FROM, EFFECTIVE_TO
- -- User properties
- NAME_FIRST, NAME_LAST, EMAIL
- IS_ACTIVE, ENGAGEMENT_TIER
- -- Daily aggregated metrics
- LOGIN_COUNT
- EMAIL_SENT_COUNT
- ASSETS_OWNED_COUNT
- ACTIVE_PROJECTS_COUNT
```

### MARKETING_USER_C (Marketing Current View)
```
MARKETING_USER_C
- USER_ID
- -- Marketing-relevant fields only
- EMAIL, NAME_FIRST, NAME_LAST
- DEPARTMENT, REGION
- IS_ACTIVE
- -- Simplified derived metrics
- ENGAGEMENT_TIER
- TENURE_MONTHS
- LAST_LOGIN_DATE
```

## Key Architectural Benefits Demonstrated

1. **State-centric approach**: User objects maintain complete state over time
2. **Modular rebuild**: Marketing logic changes don't affect core user analytics
3. **Historical aggregation-ready**: Any time period analysis possible from base objects
4. **Consistent patterns**: Same structure across all business objects
5. **Access governance**: Technical complexity hidden in Processing Database

---

# Modern Data Engineering System: Frequently Asked Questions

### Why does the system use JSON for complex attributes?

While JSON queries can be slower in traditional databases, Snowflake's architecture optimizes JSON storage by treating JSON keys as native columns behind the scenes. This provides the flexibility of JSON while maintaining query performance. Additionally, the data marts flatten JSON structures into columns when needed for specific business uses.

### Why focus only on analytics rather than including real-time processing?

The system is specifically designed for analytical workloads with update frequencies of an hour or longer. This focus allows for optimizations specific to analytics use cases and avoids the complexity of trying to serve both analytical and operational needs in a single system. Organizations requiring real-time processing should maintain separate systems optimized for that purpose.

### Why run the new system in parallel with existing processes?

Parallel operation allows for thorough validation of the new system without business disruption. Each data mart and report can be migrated individually once its data quality and performance have been verified. This approach reduces risk and allows for controlled, incremental migration.

### What makes this different from traditional dimensional modeling?

Traditional dimensional modeling separates facts (events) from dimensions (attributes). This system treats business object states as aggregatable dimensions, allowing direct aggregation of entity properties while maintaining full historical context. This enables analysis patterns like "count of active users by region" without requiring separate fact tables.

### How does the parallel processing in AIN work?

The Analytics Intermediate layer runs two simultaneous processes: one stream aggregates events by time periods (creating daily login counts, transaction volumes, etc.), while another stream denormalizes object tables (adding manager properties, account details, etc.). These streams feed into the Analytics layer to create complete business objects with both inherited properties and derived metrics.

### What are the prerequisites for implementing this system?

* Snowflake environment with appropriate sizing for your data volume
* Development environment for dbt Core
* Apache Airflow installation or compatible orchestration tool
* Source system access and permissions
* Business subject matter experts for data validation

[Note: Additional questions will be added based on implementation experience and user feedback.]