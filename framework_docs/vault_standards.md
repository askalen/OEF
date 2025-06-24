# Business Vault Standards & Conventions Guide

## Table Naming Convention

### Base Pattern
```
LAYER_OBJECT_(SUBTYPE)_(RELATIONSHIP)_SUFFIX
```

### Layer Prefixes
- `SRC` - Source layer
- `VLT` - Vault layer
- `ANA` - Analytics layer
- `MRT` - Mart layer

### Suffix Types
- `HR` - Historical Registry (registry tables with mappings/validity)
- `H` - History (SCD Type 2 historical satellites)
- `E` - Event
- `A` - Aggregate Event

## Object Naming

### Primary Objects and Subtypes
- Primary objects represent major business concepts
- Subtypes are variations that share behavior with the primary object
- If two objects are ever handled the same way, they should be subtypes of a primary object

### Examples
- Primary object: `ENTITY`
  - Subtypes: `ENTITY_COMPANY`, `ENTITY_PERSON`
- Primary object: `USER`
  - Subtypes: `USER_PRODUCT`, `USER_API`

### Object Table Naming
```
VLT_PRIMARYOBJECT_SUBTYPE_SUFFIX
```
Examples:
- `VLT_ENTITY_COMPANY_HR` - Company entity registry
- `VLT_ENTITY_PERSON_HR` - Person entity registry
- `VLT_ENTITY_COMPANY_H` - Company attributes history

## Relationship Naming

### Pattern
```
VLT_PRIMARYOBJECT_RELATIONSHIP_SUFFIX
```

### Key Rules
1. Only include the primary object in the table name
2. Relationship keyword implies the related object type
3. Avoids unnecessarily long names and duplicates

### Examples
- `VLT_ACCOUNT_PARENT_H` - Account hierarchy (ACCOUNT_ID, PARENT_ACCOUNT_ID)
- `VLT_CONTRACT_OWNERSHIP_H` - Contract to entity ownership
- `VLT_USER_MANAGER_H` - User to manager relationship

## Reserved Relationship Keywords

Keywords that imply specific object types:

- **MANAGER** - Always relates to Employee objects
- **OWNER** - Always relates to User objects
- **REPRESENTATION** - Always relates to Employee objects
- **PARENT/CHILD** - Always same-type hierarchical relationships
- **MEMBERSHIP** - Typically relates to User objects
- **OWNERSHIP** - Context-dependent (User or Entity)

## ID Structure

### Format
```
objecttype-subtype.system.identifier
```

### Examples
- `entity-company.us.355254` - Company in US system
- `entity-person.eu.882` - Person in EU system
- `user-api.gov.12345` - API user in government system

### System Identifiers
- Regional deployments: `us`, `eu`, `asia`
- Environment types: `gov`, `dev`, `test`
- Prevents ID collisions across systems
- Not for business geography (that's an attribute)

## Composite Keys for Polymorphic Relationships

When relating to primary objects with subtypes:
```
PRIMARY_ID, OBJECT_TYPE, OBJECT_ID
```

Example for `VLT_CONTRACT_ENTITY_OWNERSHIP_H`:
- CONTRACT_ID
- ENTITY_TYPE ('entity-company' or 'entity-person')
- ENTITY_ID

This provides:
- Type safety at database level
- Efficient clustering/partitioning
- Self-documenting relationships