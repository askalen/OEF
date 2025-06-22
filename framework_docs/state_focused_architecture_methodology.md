# State-Focused Data Architecture Methodology

## Overview

This methodology is designed for modern software companies that need to track object state progressions over time rather than just discrete events. It leverages cheap storage and powerful compute capabilities of modern data warehouses (particularly Snowflake) to enable flexible, accurate historical analysis of business objects.

## Core Principles

- **State-centric analytics**: Focus on how business objects evolve through states over time
- **Historical aggregation-ready dimensions**: Objects prepared for any custom metric aggregation
- **Modular rebuild efficiency**: Isolate volatile components (like categorization logic) to minimize reprocessing
- **Consistent structural patterns**: Standardized table types with clear naming conventions

## Architecture Layers

### Database Separation

**Processing Database** - Builder/engineer access only
- Contains all transformation and preparation work
- Protects complex intermediate steps from end users

**Reporting Database** - Analyst and business user access  
- Contains only mart schemas organized by purpose
- Schema-level permissions for governance

### Layer Structure

**RAW** - Raw data from datalake

**SRC** - Cleaned and structured versions of raw tables
- No business logic applied
- Standardizes table structure and includes only meaningful fields

**VIN** - Vault Intermediate *(optional)*
- Only created when needed for complex source transformations
- Handles field mapping, source handoffs, and structural changes
- Maintains DRY principles by centralizing transformation logic
- Advanced option: Full data vault normalization for maximum future-proofing

**VLT** - Business Vault
- Standard Business Vault implementation
- Normalizes around business objects, relationships, and events
- First layer where D (Dimension) tables appear

**AIN** - Analytics Intermediate  
- Parallel processing layer with two functions:
  1. Event aggregation by time periods and primary keys
  2. Denormalization of object/relationship tables
- Introduction of HX (time-granular historical) tables

**ANA** - Analytics Layer
- "Golden tables" serving as sources of truth for all business objects and actions
- Contains object/relationship tables with related properties
- Contains object/relationship aggregate tables  
- Contains event tables structured like Kimball fact tables
- Only measures and dimensions outside this layer should be custom-purpose ones in marts

**MRT** - Mart Layer (Reporting Database)
- **Common Schema**: Joined tables for maximum convenience
- **Metrics Schema**: Official company metrics (metric store)
- **Departmental Schemas**: Team-specific customized tables
- **Reporting Schemas**: Tables optimized for specific reports and tools

## Table Structural Types

Every table has a type indicated by its suffix, providing consistent behavior and enabling automated processing:

**H** - Historical table, SCD Type 2
- Tracks every change to object attributes over time

**HX** - Time-granular Historical table (X = H/D/W/M/Q/Y)
- SCD Type 2 with rougher granularity using point-in-time slices
- Example: HD only adds rows for day-to-day changes
- Used for frequently-changing aggregate dimensions

**E** - Event table
- One row per event
- May have business keys but no primary keys

**EX** - Aggregate Event table  
- Counts and summarizes events within given periods
- Has primary key(s) based on aggregation method

**D** - Dimension table
- Defines business objects or relationships (hub/link tables)
- Contains immutable properties
- Insert-only tables
- First appears in VLT layer

**R** - Reference table
- Static data like dates, countries, enumeration mappings
- Present from early layers

**A** - Attribute table
- EAV (Entity-Attribute-Value) structure
- Primarily used in metric stores

**PX** - Point-in-time table (X = H/D/W/M/Q/Y)
- Date/time period as primary key
- New row every time period regardless of changes
- Less storage efficient than HX but required for certain reporting patterns
- Reporting layer only

**C** - Current table
- Most recent record only with updated_last field
- Derivable from historical tables
- May be necessary for specific reporting requirements
- Reporting layer only

## Table Type Progression by Layer

- **RAW/SRC/VIN**: E, H, R (raw source structures)
- **VLT**: E, H, R, D (business objects identified)
- **AIN**: E, H, R, D, HX (time-granular aggregations)
- **ANA**: All types except PX, C (full analytical capability)
- **MRT**: All types (including PX, C for reporting-specific needs)

## Key Benefits

- **Rebuild efficiency**: Change categorization logic without recalculating expensive event aggregations
- **Historical accuracy**: Complete audit trail of all object state changes
- **Analytical flexibility**: Objects prepared for any metric aggregation pattern
- **Operational clarity**: Consistent naming and structure patterns across all tables
- **Governance simplicity**: Clear database and schema separation for access control