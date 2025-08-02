# Data Inventory Instructions for SMEs

## Overview

As a subject matter expert (SME), your role is to document the source systems that contain business data needed for the data warehouse. You'll work in two phases:

1. **Planning Phase:** Help create a planning spreadsheet that inventories all available source tables and assigns ownership
2. **Documentation Phase:** Create detailed YML files for assigned tables that serve as both planning documentation and technical specifications for engineers

These YML files become the source definitions that dbt uses during the build phase, so accuracy and completeness are critical.

## Phase 1: Planning Spreadsheet

Work with your team to create a planning document (Google Sheets, Excel, etc.) with the following structure:

### Parent Rows: Source Paths
Each parent row represents a database/schema combination with an assigned name:

| Source Path | Source Name | Assigned SME | Assigned Engineer |
|-------------|-------------|--------------|-------------------|
| salesforce_db.production | salesforce_prod | Jane Smith | John Doe |
| erp_system.main | erp_main | Bob Wilson | Jane Doe |
| data_warehouse.raw | warehouse | Alice Brown | John Doe |

**Source Path:** The actual database.schema path in your system  
**Source Name:** Clean, short name for use in file naming (use database_schema format or custom words)

### Child Rows: Individual Tables
Under each source path, list all business-relevant tables:

| Table Name | Business Purpose | Split Decision | Status |
|------------|------------------|----------------|---------|
| account | Customer and prospect data | H+E split | Assigned |
| opportunity | Sales pipeline data | H only | In Progress |
| contact | Individual contact records | H only | Complete |

**Split Decision Options:**
- **H only:** Slow-changing object attributes
- **E only:** Pure activity/event data  
- **H+E split:** Table contains both object attributes AND activity events

## Phase 2: YML File Creation

Create one YML file per table per processing type, using this naming pattern:
`{source_name}_{table_name}_{h|e}.yml`

**Examples:**
- `salesforce_prod_account_h.yml` (account attributes)
- `salesforce_prod_account_e.yml` (account activity events)
- `erp_main_order_h.yml` (order data)

### Deciding on H vs E Split

**H Tables (Historical Attributes):**
Focus on meaningful attributes OF the business object:
- Object identifiers and classifications
- Status, tier, category, type fields
- Names, descriptions, settings
- Business relationships and hierarchies

**E Tables (Events):**
Focus on things that HAPPENED TO the object:
- Activity timestamps (last_login, last_accessed)
- User interactions (created_by, modified_by, accessed_by)
- State change events
- Activity metrics and counters

**Examples:**
- `customer_name` → H table (attribute of customer)
- `customer_tier` → H table (attribute of customer)
- `last_login_date` → E table (activity event)
- `last_modified_by` → E table (activity event)
- `view_count` → E table (activity metric)

## YML File Structure

### Source Level Information

```yml
version: 2
sources:
  - name: {source_name}              # From planning doc: salesforce_prod, erp_main, etc.
    database: {actual_database_name}  # Real database name in your platform
    schema: {actual_schema_name}      # Real schema name (if applicable)
    
    tables:
    - name: {actual_table_name}       # Exact table name in source system
```

### Table Level Information

```yml
- name: {table_name}
  description: "{Business purpose of this table}"  # Optional but recommended
  meta:
    _filter: {SQL_where_condition}   # Optional: exclude invalid/test data
    _type: {journal|snapshot}        # journal = changes over time, snapshot = point-in-time
    _valid_from: '{YYYY-MM-DD}'      # Optional: earliest date to process data
    _valid_to: '{YYYY-MM-DD}'        # Optional: latest date to process data
```

**_filter examples:** `is_deleted = FALSE`, `status != 'TEST'`, `validity = 'VALID'`  
**_type:** Most transactional systems are `journal`, data warehouse extracts are usually `snapshot`
**_valid_from/_valid_to:** Date range for data processing - use when switching sources or don't need full history

### Column Level Information

**Required Fields:**

1. **Primary Key(s) - H tables only, E tables optional**
   ```yml
   - name: {pk_field}
     description: "{Business meaning}"  # Only if additional context needed
     _purpose: pk
   ```
   - H tables: Must have at least one PK field
   - E tables: PK is optional but allowed
   - Combined PK + data_time should be unique at source table grain

2. **Data Time Field - Required for all tables**
   ```yml
   - name: {data_time_field}
     _purpose: data_time
     _transformation: {field_name}::TIMESTAMP  # If conversion needed
   ```
   - Examples: `created_date`, `transaction_time`, `last_modified_date`
   - Exactly one per table

**Optional Fields:**

3. **Process Time Field**
   ```yml
   - name: {process_time_field}
     _purpose: process_time
     _transformation: {field_name}::TIMESTAMP  # If conversion needed
   ```
   - Examples: `inserted_at`, `_loaded_at`, `etl_timestamp`
   - If not specified, defaults to match data_time
   - At most one per table

4. **Attribute Fields - Business data**
   ```yml
   - name: {business_field}
     description: "{Business meaning}"  # Only if context needed
     _purpose: attribute
     _transformation: UPPER({field_name})  # If standardization needed
   ```

5. **Meta Fields - Process/audit data**
   ```yml
   - name: {audit_field}
     description: "{Process tracking purpose}"  # Only if context needed
     _purpose: meta
   ```
   - Examples: `process_id`, `batch_id`, `etl_run_id`
   - Important for auditing but don't justify new rows

6. **Excluded Fields**
   ```yml
   - name: {field_to_exclude}
     description: "{Why excluded}"
     _exclude: true
   ```

## Field Purpose Summary

| Purpose | Required | Description | Examples |
|---------|----------|-------------|----------|
| `pk` | H tables: Yes (≥1)<br>E tables: Optional | Primary key fields | `customer_id`, `transaction_id` |
| `data_time` | All tables: Yes (=1) | When business event occurred | `created_date`, `last_modified` |
| `process_time` | Optional (≤1) | When data was processed | `inserted_at`, `_loaded_at` |
| `attribute` | Optional | Business object attributes | `name`, `status`, `amount` |
| `meta` | Optional | Process/audit tracking | `batch_id`, `process_id` |

## Quality Checklist

Before finalizing each YML file:

- [ ] File named correctly: `{source_name}_{table_name}_{h|e}.yml`
- [ ] H tables have at least one PK field, E tables may have zero or more
- [ ] Exactly one data_time field specified
- [ ] At most one process_time field (or none, defaults to data_time)
- [ ] PK + data_time combination matches source table grain
- [ ] H/E split decision follows attribute vs. activity logic
- [ ] Important business fields documented with `_purpose: attribute`
- [ ] Process fields documented with `_purpose: meta` if kept
- [ ] Any necessary data quality filters included
- [ ] Descriptions only added where additional context is needed

## Common Patterns

### Customer/Account Tables
- **H table:** `customer_id` (pk), `name`, `tier`, `status`, `created_date` (data_time)
- **E table:** `customer_id`, `last_login` (data_time), `login_count`, `accessed_by`

### Transaction Tables  
- **H table:** `transaction_id` (pk), `amount`, `status`, `created_date` (data_time)
- **E table:** `transaction_id`, `status_change_date` (data_time), `old_status`, `new_status`, `changed_by`

### Product Tables
- **H table:** `product_id` (pk), `name`, `category`, `price`, `last_updated` (data_time)
- **E table:** `product_id`, `view_date` (data_time), `viewed_by`, `source_page`

## Implementation Flow

These YML files become the foundation for the entire data warehouse build process:

### Source Layer (SRC)
YML files drive the creation of standardized source tables:
- `salesforce_account_h` - Historical account attributes from Salesforce
- `salesforce_account_e` - Account activity events from Salesforce
- `hubspot_contact_h` - Historical contact attributes from HubSpot

### Vault Transformation (VLTX)
Source tables feed into business object mapping:
- Registry tables (`entity_r`, `user_r`) map source IDs to business object IDs
- Override tables (`salesforce_account_o`) provide manual configuration
- Transformed tables (`entity_organization_salesforce_h`) align to business objects

### Vault Layer (VLT)
Multiple sources consolidate into authoritative business objects:
- `entity_organization_h` - Consolidated organization data across all sources
- `user_h` - Consolidated user data with best-value selection logic

### Warehouse Layers (WHX, WH)
Business objects become analytics-ready tables:
- Denormalized structures with related dimensional context
- Embedded metrics and aggregations for analysis
- Optimized for consumption by business teams

## Getting Help

**If you're unsure about:**
- **H vs E split:** Ask "Is this an attribute OF the object, or something that HAPPENED TO it?"
- **Field purposes:** Focus on business meaning - what makes this field important?
- **Data quality:** Better to include questionable data with filters than exclude potentially useful information
- **YML syntax:** Use the template; format is forgiving for minor errors

**Remember:** These files become the foundation for all downstream processing. Accuracy in field classification and business context is more important than perfect technical syntax.