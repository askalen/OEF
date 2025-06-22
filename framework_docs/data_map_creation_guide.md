# Creating Your Data Map

## Overview
The data map documents all possible tables in your data warehouse, from source through analytics and mart layers. Rather than capturing complex relationships in diagrams, we use a structured spreadsheet format that makes it easy to track both table definitions and data lineage.

## Structure
Create a spreadsheet with separate tabs for each layer (src, vin, vlt, ain, ana, mart). Each tab contains these columns:

name: Table name including appropriate suffix (_h, _e, _d, etc.)
schema: Layer schema (src, vin, vlt, etc.)
pks: Business object primary key fields
references: Upstream tables this table pulls from
status: Development status (not started, in design, in development, testing, complete)
description: Brief explanation of table purpose

## Key Concepts

### Object Hierarchy
When two objects are connected, their relative positions in the hierarchy are determined by:
- Which object's properties should flow to the other
- How metrics will need to aggregate
- Many-to-one relationships (the 'one' side is higher)

This hierarchy determines:
- Direction of denormalization (properties flow downward in ANA layer)
- Direction of aggregation (metrics flow upward in data marts)
- Position of relationship tables (always below the objects they connect)

### Primary Objects and Subtypes
- Primary objects represent core business concepts
- Subtypes are permanent classifications of primary objects
- Primary objects have a single dimension table that defines identity for all subtypes
- Each primary object and subtype gets its own historical table for properties
- Relationship tables reference primary objects, not subtypes

### Table Types
- _H tables track object state changes and properties
- _E tables track events and activities related to objects
- _D tables define object identity (vault layer)
- _HX tables contain time-based state snapshots (X represents configurable granularity)
- _AX tables contain time-based event aggregations
- _I tables contain instance-based lifecycle metrics
- _C tables provide current state snapshots
- _R tables contain reference data
- _A tables use EAV structure for flexible attributes
- _PX tables provide point-in-time snapshots at regular intervals

## Layer Documentation

### Source Layer
Document every source table's representation. Source tables typically map to one or two tables:
- _H for state changes and properties
- _E for events and activities

```
name: src_account_h
schema: src
pks: id
references: raw.sfdc_account
description: Organization account state changes from Salesforce

name: src_contact_h
schema: src
pks: id
references: raw.sfdc_contact
description: Individual contact state changes from Salesforce

name: src_login_e
schema: src
pks: id, event_id
references: raw.application_logs
description: User login events from application logs
```

### Vault Intermediate Layer
Document intermediate tables that handle source system transitions, combinations, or complex transformations. VIN tables are named after the VLT table they feed and only exist when needed.

```
name: vin_user_h
schema: vin
pks: user_id
references: src.contact_h, src.employee_h
description: Combined user data from contact and employee sources before vault

name: vin_account_h
schema: vin
pks: account_id
references: src.sfdc_account_h, src.legacy_customer_h
description: Account data handling system transition from legacy to Salesforce
```

### Vault Layer
Document vault tables that establish core identities for business objects and track their properties. Develop these alongside any needed VIN tables.

#### Dimension Tables (Identity)
```
name: vlt_user_d
schema: vlt
pks: user_id
references: vin.user_h
description: Core identity table for all users

name: vlt_account_d
schema: vlt
pks: account_id
references: vin.account_h
description: Core identity table for accounts
```

#### Historical Tables (Properties)
```
name: vlt_user_h
schema: vlt
pks: user_id
references: vlt.user_d, vin.user_h
description: User properties and state changes over time

name: vlt_account_h
schema: vlt
pks: account_id
references: vlt.account_d, vin.account_h
description: Account properties and state changes over time

name: vlt_user_account_h
schema: vlt
pks: user_id, account_id
references: vlt.user_d, vlt.account_d, src.user_account_mapping
description: User-account relationship tracking over time
```

#### Event Tables
```
name: vlt_login_e
schema: vlt
pks: user_id, event_id
references: vlt.user_d, src.login_e
description: User login events with vault keys
```

### Analytics Intermediate Layer
Document intermediate analytics tables that perform parallel processing - event aggregation and object denormalization. Develop these alongside the target ANA tables.

#### Event Aggregations
```
name: ain_user_login_ad
schema: ain
pks: user_id, date
references: vlt.login_e
description: Daily user login activity aggregations

name: ain_account_activity_ad
schema: ain
pks: account_id, date
references: vlt.user_account_activity_e
description: Daily account activity aggregations
```

#### Object Denormalization
```
name: ain_user_h
schema: ain
pks: user_id
references: vlt.user_h, vlt.user_account_h
description: Denormalized user data with account relationships

name: ain_account_h
schema: ain
pks: account_id
references: vlt.account_h, vlt.user_account_h
description: Denormalized account data with user relationships
```

### Analytics Layer
Document analytics tables that combine denormalized objects with aggregated metrics to create complete business objects ready for analysis.

#### Business Objects
```
name: ana_user_h
schema: ana
pks: user_id
references: ain.user_h, ain.user_login_ad
description: Complete user object with properties and derived behavioral states

name: ana_account_h
schema: ana
pks: account_id
references: ain.account_h, ain.account_activity_ad
description: Complete account object with properties and activity metrics

name: ana_user_account_h
schema: ana
pks: user_id, account_id
references: ain.user_h, ain.account_h, vlt.user_account_h
description: User-account relationships with enriched context
```

#### Events
```
name: ana_login_e
schema: ana
pks: user_id, event_id
references: vlt.login_e, ana.user_h
description: Login events with enriched user context
```

#### Time-based Aggregations
```
name: ana_user_hd
schema: ana
pks: user_id, date
references: ana.user_h, ain.user_login_ad
description: Daily user state snapshots with activity metrics

name: ana_account_hd
schema: ana
pks: account_id, date
references: ana.account_h, ain.account_activity_ad
description: Daily account state snapshots with activity metrics
```

### Mart Layer
Document data mart tables organized by schema for specific consumption needs.

#### Common Data Marts
```
name: common_user_hd
schema: mart_common
pks: user_id, date
references: ana.user_hd
description: Daily user metrics for company-wide reporting

name: common_account_hd
schema: mart_common
pks: account_id, date
references: ana.account_hd
description: Daily account metrics for company-wide reporting

name: common_user_c
schema: mart_common
pks: user_id
references: ana.user_h
description: Current user state for company-wide analysis
```

#### Departmental Data Marts
```
name: sales_account_overview_c
schema: mart_sales
pks: account_id
references: common.account_hd
description: Current account overview optimized for sales dashboards

name: marketing_user_engagement_d
schema: mart_marketing
pks: user_id, date
references: common.user_hd
description: Daily user engagement metrics for marketing campaigns

name: support_user_activity_w
schema: mart_support
pks: user_id, week
references: common.user_hd
description: Weekly user activity summary for support team reporting
```

## Development Strategy

1. Complete one layer at a time, moving from source through analytics to mart layers

2. Within each layer, develop tables in order:
   - Core business objects and their identities
   - Properties and relationships 
   - Events and activities
   - Time-based aggregations

3. Develop intermediate layers (VIN, AIN) alongside their target layers table by table

4. Review references to ensure:
   - All upstream dependencies are documented
   - No circular dependencies exist
   - References only point to current or upstream layers

5. Update status as development progresses:
   - not started: Initial state
   - in design: Requirements being gathered
   - in development: Active development
   - testing: Under validation
   - complete: Production ready

## Using the Data Map

The completed data map serves multiple purposes:

1. **Development Planning**
   - Creates clear sequence of table development
   - Shows dependencies between tables
   - Helps allocate development resources

2. **Progress Tracking**
   - Provides overview of project status
   - Identifies bottlenecks in development
   - Shows impact of delays on dependent tables

3. **Documentation**
   - Shows complete data warehouse structure
   - Explains table relationships and lineage
   - Helps onboard new team members

4. **Impact Analysis**
   - Trace data flows through layers
   - Understand downstream effects of changes
   - Identify affected tables for testing

Keep the data map updated as development progresses and new requirements emerge. Regular reviews ensure it remains an accurate representation of your data warehouse structure.

## Common Patterns

1. **Primary Object Structure**:
   - Single dimension table defines identity (_D suffix)
   - Properties tracked in historical table (_H suffix)
   - Relationships tracked separately with both object keys
   - Events linked to primary objects, not subtypes

2. **Intermediate Layer Usage**:
   - VIN layer: Only when source combination or complex transformation needed
   - AIN layer: Parallel processing for event aggregation and denormalization
   - Named after target layer tables they feed

3. **Property Flow**:
   - Properties flow from VLT to ANA layer through denormalization
   - Metrics aggregate from events into time-based tables
   - Complete objects combine properties and derived metrics in ANA layer

4. **Time and Aggregation Patterns**:
   - _HX for time-based state tracking (configurable granularity)
   - _AX for time-based event aggregations
   - _I for instance-based lifecycle metrics
   - _C for current state snapshots
   - _E for event tracking
   - _H for state changes and properties