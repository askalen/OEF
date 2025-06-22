# Business Object Implementation Guide

## Implementation Process

### Step 1: Source Key Analysis
Begin by documenting all key fields in your source tables. For each table, identify primary keys, foreign keys, and any reference code fields used for joining (like currency or country codes). Note the data type of each field, whether it's system-generated or has business meaning, and what it references in the case of foreign keys. Pay special attention to cases where the same concept appears in different tables under different names.

Example Source Key Documentation:
```
Table: SALESFORCE.CONTACT
- Primary Key: ID (system-generated)
- Foreign Keys:
  - ACCOUNT_ID (references ACCOUNT.ID)
  - OWNER_ID (references USER.ID)
- Reference Codes:
  - COUNTRY_CODE
  - CURRENCY_CODE
```

### Step 2: Business Object Definition

Core Goal: Create a stable set of business objects that accurately represent how your company uses data, independent of how that data is currently stored.

Process:
First, create a comprehensive list of source objects and document their business purpose. Understanding what each object represents in the business, how it's used in reporting and operations, and how it relates to other objects is crucial for the next steps.

Next, analyze where different source objects might represent the same business concept. Look for cases where objects could be meaningfully combined in reports, share key identifying information, or serve similar business purposes.

With this understanding, begin defining your business objects. Start with the most fundamental objects, which are usually real-world entities. For each object, determine whether variations should be handled as subtypes (permanent classifications) or states (temporary conditions). Identify which aspects should be treated as elements of other objects rather than objects themselves.

Finally, review and revise your definitions until they're stable. Test them against edge cases, verify that all source objects have appropriate mappings, and ensure the model will support both current and planned reporting needs.

Common Patterns:

Real-world Entities represent things that exist independently outside your systems. These often need to be combined from multiple sources and usually have natural keys like email or tax ID. Customers appearing in both CRM and support systems are a typical example.

Internal Structure represents your company's organization. These usually have a single authoritative source and often show hierarchical relationships. Departments, positions, and cost centers fall into this pattern.

Commercial Activities represent business transactions or agreements. These typically generate financial records and usually have line items as elements. Orders, invoices, and contracts are common examples.

Work Management represents actions or tasks that need to be tracked. These have assignees and status workflows, and often link multiple other objects together. Support tickets, projects, and opportunities demonstrate this pattern.

Assets and Resources represent things that can be owned or used, whether physical or digital. These often need assignment or allocation tracking. Inventory items, digital content, and licenses fit this pattern.

### Step 3: Key Mapping Implementation
Once your business objects are stable, create mapping entries for every key field in your source systems.

For ID Fields:
```
Technical PK: [Source system unique identifier]
Filter: [Optional WHERE clause to segment records]
Natural Key: [Source expression] -> [Vault field]
Business Object: [Target business object/subtype]
```

Example:
```
Technical PK: ID
Filter: type = 'person'
Natural Key: LOWER(email) -> email
Business Object: entity-individual
```

For Code Fields:
```
Transform: [Standardization expression]
Target Field: [Standard reference field]
```

Example:
```
Transform: UPPER(TRIM(currency_id))
Target Field: CURRENCY_CODE
```

## Implementation Guidelines

Key Rules:
1. Every business object should have independent meaning and lifecycle
2. Subtypes are permanent classifications, states are temporary
3. Elements (like line items) belong to parent objects
4. Every ID field needs a mapping entry
5. Reference codes only need standardization rules
6. Take time to get definitions right - this affects everything downstream

This process typically takes 2-4 weeks. Remember that business object definitions are subjective and company-specific - the same concept might be a subtype in one company and a state in another. Focus on how your company uses data rather than how source systems are structured. Document your decisions and rationale, as you'll need to reference them throughout the implementation.

## Mapping Business Objects to Analytics Tables

Once your business objects are defined and key mappings are established, you'll need to plan how these objects will be transformed into analytics tables in the ANA layer. This creates the foundation for analysis and aggregation.

### Architecture Progression

Your business objects flow through the system in a structured progression:

**Vault Layer (VLT)**: Normalized business object storage
- `vlt_entity_d`: Core identity for entity objects
- `vlt_entity_individual_h`: Properties specific to individual entities
- `vlt_entity_organization_h`: Properties specific to organization entities

**Analytics Intermediate Layer (AIN)**: Parallel processing preparation
- **Denormalization Stream**: Combines related object properties
- **Event Aggregation Stream**: Summarizes behavioral data by time periods
- Creates foundation for complete analytical objects

**Analytics Layer (ANA)**: Complete business objects ready for analysis
- `ana_entity_individual_h`: Complete individual entity with properties and derived states
- `ana_entity_organization_h`: Complete organization entity with metrics and relationships
- `ana_entity_individual_hd`: Daily snapshots with activity aggregations

### Key Considerations

1. **Denormalization Strategy**: Determine which related attributes should be denormalized into each analytics table. Consider query patterns, performance needs, and logical groupings.

2. **Measure Identification**: Identify measurable attributes (quantities, amounts, counts) and behavioral states that will be derived from event aggregations.

3. **Relationship Handling**: Decide how relationships between objects will be represented in the analytics layer - whether as separate relationship analytics tables or as denormalized attributes.

4. **History Tracking**: Establish how historical changes will be preserved in the analytics tables, using SCD Type 2 patterns for state tracking.

5. **Aggregate Integration**: Plan how event aggregations from the AIN layer will enrich business objects with derived behavioral states like activity levels, engagement tiers, and risk scores.

### Implementation Patterns

For each primary business object and subtype, create a corresponding analytics table implementation plan:

```
Business Object: [Name]
Primary Analytics Table: ANA_[NAME]_H
Key Structure: [Primary key fields]
Inherited Dimensions: [Properties from related objects to include]
Derived States: [Behavioral states calculated from activity patterns]
Time Aggregations: [Daily/weekly/monthly snapshot tables needed]
```

Example:
```
Business Object: entity-individual
Primary Analytics Table: ANA_ENTITY_INDIVIDUAL_H
Key Structure: ENTITY_ID
Inherited Dimensions: Organization properties, manager details, account context
Derived States: is_active, engagement_tier, risk_score
Time Aggregations: ANA_ENTITY_INDIVIDUAL_HD (daily activity snapshots)
```

### Aggregation Strategy

The system handles aggregation through the AIN layer's parallel processing:

**Event Aggregation Stream** creates time-based summaries:
- `ain_user_login_ad`: Daily login activity by user
- `ain_account_transaction_ad`: Daily transaction volumes by account

**Denormalization Stream** enriches objects with related properties:
- `ain_user_h`: User properties with manager, department, and account details
- `ain_account_h`: Account properties with user relationships and organizational context

**Analytics Layer Combination** merges both streams:
- `ana_user_h`: Complete user object with both inherited properties and derived behavioral states
- `ana_user_hd`: Daily user snapshots combining state properties with activity metrics

This approach ensures your business objects transition smoothly from normalized vault storage to complete analytical objects that support both detailed analysis and flexible aggregation patterns.

The key innovation is treating these analytics tables as aggregatable business dimensions rather than traditional fact tables, allowing direct aggregation of entity properties while maintaining full historical context and behavioral insights.