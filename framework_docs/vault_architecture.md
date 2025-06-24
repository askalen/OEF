# Business Vault Architecture Guide

## Overview

This guide describes a two-layer vault architecture designed to handle complex business key mapping scenarios while maintaining clean historical tracking. The approach addresses several edge cases that traditional Data Vault struggles with, particularly around Same-As-Links (SAL) and business key evolution.

## Core Architecture

### Two-Layer Design

1. **Data Vault Layer** (Natural Key Layer)
   - Standard Data Vault normalized around natural keys from source systems
   - Uses SCD Type 2 tables from the SRC layer as input
   - Maintains all natural relationships exactly as they exist in source systems

2. **Business Vault Layer**
   - Normalized around business keys and business concepts
   - Fed from the Data Vault layer through a mapping table
   - Contains only "real" business objects with confirmed mappings

### Registry Tables (Replacing Traditional Hubs)

Instead of traditional hub tables, this architecture uses Registry tables that serve as:
- The authoritative source of business entity existence
- The mapping between natural keys and business keys
- Historical tracking of all key relationships

Registry tables include:
- Business ID (Primary Key)
- Valid_from/Valid_to (for historical ranges)
- Foreign keys to each natural key

### Key Design Principles

1. **Single Primary Identifier Rule**
   - At any given time, one natural key must be chosen as the 'primary' identifier for each business object
   - This can change over time, but only one exists at any moment
   - Primary identifier determines when new business IDs are generated

2. **No Mapping, No Processing Rule**
   - Sources without natural key mappings to business keys are not processed into the Business Vault
   - Ensures every object in the Business Vault is a "real" business object
   - Prevents provisional IDs that might need merging later

3. **One Source Per Business Object Rule**
   - Multiple source natural keys can connect to one business object
   - Only one natural key per source can be active at a time
   - Enforced through primacy logic

## Handling Edge Cases

### Multiple Natural Keys to Single Business Concept
- Mapping table maintains all natural key relationships
- Primacy logic determines which source "wins" for field values
- No SAL complexity - business objects remain clean

### Multiple Sources for Same Business Concept
- Data satellites joined through mapping table
- Field-level primacy logic in satellite building
- Source handoffs handled through 'data_from/to' configurations

### Changing Primary Business Keys
- Only requires updating the mapping logic
- Historical data remains intact
- No cascade of broken ETL or emergency fixes

### Chain Relationships
- Handled in satellite building logic when necessary
- Example: Deducing company-parent relationships through Salesforce accounts
- Kept as business rules, not structural complexity

## Benefits

1. **Stability**: Primary key changes become configuration updates, not crises
2. **Clean Business Layer**: No natural key pollution in business queries
3. **Full History**: Complete reproducibility with time-based mappings
4. **No Late-Arriving Issues**: Mapping requirement prevents duplicate business objects