# Introduction

The Object Evolution Framework (OEF) is a comprehensive data warehouse methodology that treats business object evolution as a first-class analytical concern. Instead of enriching events, OEF tracks how your business entities change over time with complete historical accuracy and unprecedented efficiency.

## The Cost of Object-Blind Warehouses

Most data warehouse frameworks center around event processing. You load transaction logs, enrich them with dimensional context, and aggregate them into metrics. This works for operational dashboards, but creates expensive headaches when you need to understand how your business objects actually evolve.

**Real scenarios that break traditional warehouses:**

**"What was our customer risk profile when we made that pricing decision?"** Your executive team needs to understand historical context for a major business decision. You spend 3 weeks building a one-off analysis because your warehouse can't answer point-in-time questions about how customers looked 6 months ago.

**"We found a bug in our segmentation logic."** Marketing discovers an error in how customer segments were calculated. The "simple" fix requires rebuilding 18 months of expensive aggregations because every downstream table depends on that flawed segmentation.

**"How has churn risk changed since our product launch?"** Product wants to understand if the new features are reducing churn risk over time. Your current approach can show you churn events, but can't track how individual customer risk profiles evolved before those events happened.

**"We need to rebuild our warehouse with better business logic."** Your team has learned better ways to structure the data, but implementing changes means months of recalculating expensive historical aggregations and hoping nothing breaks downstream.

These problems exist because traditional frameworks treat business objects as static dimensions rather than evolving entities. You need every change to every business object tracked over time, with the ability to snapshot any object at any historical moment.

## The Solution

OEF provides a complete methodology for building object-centric data warehouses that are:

**Historically Complete:** Every change to every business object is tracked in SCD Type 2 format with full audit trails and change detection.

**Analytically Optimized:** Purpose-built table structures and processing patterns designed specifically for object evolution analysis.

**Rebuild Efficient:** Change business logic without recalculating expensive aggregations. The framework tracks what needs to be reprocessed and what can be preserved.

**Foolproof:** Prescriptive patterns eliminate subjective design decisions. Any two engineers working on the same data will build identical tables.

**Low-Code:** Comprehensive macro system automates everything possible. Engineers fill in templates rather than writing complex transformation logic.

## What You Get

### Starting Point
Raw data in any columnar format with business object attributes and timestamps. You'll need an accessible data lake - we handle transformation, not initial data loading.

### End Result
Two clean, purpose-built databases:

**Processing Database:** Standardized transformation layers organized into three conceptual layers (Source, Vault, Warehouse) with automated processing, cursor tracking, and rollback capabilities.

**Reporting Database:** Flexible data marts organized by business function, optimized for consumption rather than processing efficiency.

### Development Experience
Templates and macros handle the heavy lifting. Engineers focus on business logic rather than infrastructure code:

```sql
-- Source layer - this (plus a documented data source) is literally all you write:
{{ config(
  _initial_date = '2020-01-01',
  _delta_limit = 20
) }}
{{ generate_src_table(source('crm', 'customers')) }}
```

```sql
-- Vault layer - simple business logic:
{{ config(unique_key = ['user_id', 'valid_from']) }}

SELECT
  oef_id_user('user', customer_id) as user_id,
  valid_from,
  name_first,
  name_last,
  is_active
FROM {{ ref('salesforce_customer_h') }}
```

The framework generates all SCD Type 2 logic, change detection, clustering, incremental processing, metadata tracking, and rollback capabilities automatically.

## When To Choose OEF

**Perfect fit when you need to:**
- Analyze how business objects change over time
- Perform point-in-time analysis with historical accuracy
- Rebuild warehouse logic without expensive recalculation
- Standardize data warehouse development across teams
- Deploy commercial-scale warehouses with intermediate SQL skills

**Not a fit when:**
- You have no need for historical object tracking or point-in-time analysis
- You need real-time operational systems (we're analytical-focused)
- Your organization prefers flexible, non-prescriptive approaches
- You're building simple reporting dashboards rather than analytical systems

## Technology Requirements

**Platform:** Snowflake + dbt Core + orchestration scheduler (Airflow, Prefect, etc.)

**Skills:** Intermediate SQL and basic dbt knowledge. No advanced data engineering experience required.

**Data:** Accessible data lake with business object data in columnar format.

## Implementation Overview

### Phase 1: Planning (4-8 weeks)
Use our design methodology to map out every business object, relationship, and table in your future warehouse. This planning phase is critical - it eliminates subjective decisions and creates a clear roadmap.

### Phase 2: Environment Setup (2 weeks)
Install the OEF dbt package, run our scaffold script to set up your repository structure, and configure your environments.

### Phase 3: Layer-by-Layer Development (16-40 weeks)
Build your warehouse systematically using our templates:
1. **Source Layer (SRC):** Standardize raw data into OEF structures
2. **Vault Transformation (VLTX):** Create business object mappings and source-specific representations
3. **Vault Layer (VLT):** Consolidate across sources into authoritative business objects
4. **Warehouse Transformation (WHX):** Denormalize for analytical processing
5. **Warehouse Layer (WH):** Add aggregated metrics to create final analytical tables
6. **Mart Layer (MART):** Build consumption-optimized tables

### Phase 4: Data Marts (Ongoing)
Deploy flexible, use-case-specific tables optimized for your business teams and applications.

## What Success Looks Like

**For Engineers:**
- Consistent table structures and naming across all projects
- Automated handling of complex scenarios (late data, rollbacks, incremental processing)
- Templates that eliminate repetitive coding
- Built-in monitoring and health checking

**For Analysts:**
- Rich historical context for every business object
- Point-in-time snapshots for accurate historical analysis
- Consistent data marts with predictable structures
- Self-documenting field naming and relationships

**For Organizations:**
- Warehouse development that scales with team growth
- Rebuild capabilities that preserve expensive calculations
- Audit trails and change tracking for compliance
- Methodology that works consistently across different business domains

## Getting Started

1. **Evaluate Fit:** Review our [design principles](principles.md) and [table types](table-types.md) to confirm alignment with your needs
2. **Plan Your Objects:** Use our [design methodology](plan_business_objects.md) to map out your business objects and relationships
3. **Install the Package:** Follow our setup guide to deploy the framework in your environment
4. **Build Your First Table:** Start with a simple historical table using our templates

The framework includes comprehensive documentation, templates for every layer, and step-by-step guides to take you from planning to production.

Ready to build a data warehouse that actually understands how your business evolves over time?