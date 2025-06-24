# Business Vault Implementation Guide

## Mapping Table Design

### Core Structure
The mapping table (Registry) contains:
- Business ID (generated unique key)
- Valid_from/Valid_to timestamps
- Foreign keys to each potential natural key
- Primary key indicator

### Historical Tracking
- New row added for each mapping change
- Valid_from/Valid_to enables point-in-time queries
- Historical mappings never modified, only new rows added
- Ensures downstream rebuilds see consistent mappings

### Business ID Generation
- New business ID created when a new primary identifier appears
- Subsequent natural keys update the mapping to connect to existing business ID
- Business IDs remain stable even when primary identifier changes

## Primacy Logic Implementation

### Purpose
Determines which source "wins" when multiple sources provide data for the same business object.

### Implementation Approach
1. Define primacy rules at field level or source level
2. Apply during Business Vault satellite construction
3. Can be static rules or time-based

### Example Patterns
```sql
-- Field-level primacy
CASE 
  WHEN source_a.revenue IS NOT NULL THEN source_a.revenue
  WHEN source_b.revenue IS NOT NULL THEN source_b.revenue
  ELSE source_c.revenue
END as revenue

-- Time-based source switching
CASE
  WHEN record_date < '2023-06-01' THEN source_a.revenue
  ELSE source_b.revenue
END as revenue
```

## Source Management

### Data From/To Configurations
- Tables can be configured with active date ranges
- Enables clean handoffs between sources
- Prevents overlap conflicts during transitions

### Configuration Table Structure
```
SOURCE_NAME | TABLE_NAME | DATA_FROM | DATA_TO
source_a    | customer   | 2020-01-01| 2023-05-31
source_b    | customer   | 2023-06-01| NULL
```

## Satellite Construction Process

### Business Satellites from Data Satellites
1. Start with mapping table for time period
2. Left join relevant data satellites using natural keys
3. Apply primacy logic for field selection
4. Apply source from/to filtering
5. Result is clean business-level history

### Key Considerations
- Log which source provided each field for audit trail
- Alert on significant disagreements between sources
- Consider storing source metadata in satellite

## Chain Relationship Handling

### When Needed
For relationships that require routing through multiple objects to establish business connection.

### Implementation
- Define chain logic in transformation layer
- Document each chain as a business rule
- Consider metadata table for chain definitions

### Example
```sql
-- Deduce company parent through Salesforce accounts
WITH account_hierarchy AS (
  SELECT 
    company.entity_id,
    sf_account.parent_account_id
  FROM vlt_entity_company_hr company
  JOIN salesforce_account sf_account 
    ON company.sf_account_id = sf_account.account_id
)
-- Continue chain to find ultimate parent
```

## Late-Arriving Data Handling

### Prevention Through Rules
- No mapping = no processing rule prevents issues
- Natural keys must link to business keys before processing
- Eliminates need for provisional IDs or later merges

### If Mappings Change
- Primacy logic switches which source provides values
- Business object IDs remain stable
- Only field values change, not object existence

## Performance Considerations

### Mapping Table Access
- Hit during every Data Vault → Business Vault transformation
- Consider partitioning by valid_to date
- Index on natural key columns
- Once in Business Vault, mapping table not needed for queries

### Registry as Views
- Decision made to keep registries as tables, not views
- Provides clean anchor point for relationships
- Better performance than deriving from mapping table
- Maintains clearer separation of concerns