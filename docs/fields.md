# Fields

Standard field types, naming conventions, and principles for deterministic field naming in the Object Evolution Framework.

## Core Principles

### Maximum Clarity with Minimum Characters

Field names should convey complete meaning in the shortest possible way while maintaining 100% clarity. Every character should earn its place by providing essential information.

### Self-Documenting Names

While documentation is encouraged, the field name itself should contain enough information that someone encountering it for the first time can understand exactly what it represents without needing external documentation.

### Deterministic Naming

Field names should be entirely determined by what they represent. Given the same data concept, any engineer should arrive at the identical field name following these conventions.

### Broad-to-Specific Ordering

Field names follow a hierarchical structure from most general to most specific, enabling alphabetical grouping of related fields and reliable JSON flattening patterns.

## Naming Structure

### Object-Centric Foundation

Every field either describes an object, a relationship, or an event. The object or relationship name should be the first element in the field name.

**Structure Pattern:** `{object}_{sub_object}_{trait}_{measure}`

Examples:
- `user_subscription_active_from`
- `customer_payment_method_last`
- `employee_manager_contact_email`

### Context-Dependent Object Naming

When a field's object matches the primary focus of the table, the object name can be omitted for brevity.

**In USER_H table:**
- `contact_email` (not `user_contact_email`)
- `subscription_active_from` (not `user_subscription_active_from`)
- `name_first` (not `user_name_first`)

**Exception:** ID fields always retain object names for clarity, even in their own table:
- `user_id` (kept even in USER_H table)

**In relationship tables** like EMPLOYEE_MANAGER_H, object specification is required for attributes belonging to specific objects, but not for fields describing the relationship itself:
- `employee_contact_email` (belongs to employee object)
- `manager_contact_email` (belongs to manager object)
- `is_active` (describes the relationship itself, no object prefix needed)

### Foreign Attributes

Attributes from other objects follow the same pattern as foreign keys, with the source object as a prefix.

Examples:
- `manager_account_name` (account name from the manager object)
- `referrer_manager_contact_email` (transitive relationship concatenation)

### Transitive Relationships

When referencing objects through multiple relationship hops, concatenate the relationship path:
- `referrer_manager_contact_email`
- `parent_company_legal_name`

## Reserved Terms

### Boolean Indicators

**`is_*` / `has_*`** - Boolean fields indicating state or possession
- `is_active`
- `has_subscription`
- `is_premium`

**`has_flag`** - Standard JSON field containing multiple boolean values
- `has_flag.certified`
- `has_flag.verified`
- `has_flag.eligible`

### Temporal Fields

**`*_at`** - Exact moment in time when something occurred
- `created_at`
- `login_at`
- `processed_at`

**`*_first` / `*_last`** - Temporal extremes (work like `*_at` for singular moments)
- `login_first`
- `purchase_last`
- `access_last`

**`*_from` / `*_to`** - Time ranges for actual occurrences
- Inclusive at start, exclusive at end
- `valid_from` / `valid_to` (required for H and R tables)
- `active_from` / `active_to`
- `*_from` without `*_to` implies ongoing/no end date

**`*_begin` / `*_end`** - Planned or expected time ranges
- `trial_begin` / `trial_end` (planned trial period)
- `subscription_begin` / `subscription_end` (expected subscription duration)
- `*_end` is sufficient (not `*_end_to`)

### Identifiers

**`*_id`** - Keys that always reference a specific object
- `user_id`
- `account_id`
- `transaction_id`

### System Fields

**`meta_*`** - Fields storing procedural or audit information about the row
- `meta_audit`
- `meta_changes`
- `meta_datahash`
- `meta_processed_at`

### Quantitative Measures

**`*_level`** - Numerical representative metrics
- `skill_level`
- `difficulty_level`
- `priority_level`

**`*_rate`** - Ratio or percentage measurements (primarily in marts)
- `conversion_rate`
- `refund_rate`

### Collections

**`*_set`** - Ordered arrays of values (default length 10)
- `actions_last_set`
- `purchases_recent_set`

## Data Type Principles

### Avoid Data Type Encoding

Don't encode data types in field names since they should be obvious from context and reserved terms.

**Correct:**
- `user_signup_at`
- `amount`
- `email`

**Incorrect:**
- `signup_date` (violates broad-to-specific ordering)
- `amount_decimal`
- `email_address`

### Eliminate Redundancy

Remove superfluous words that don't add meaning:
- `ip` not `ip_address`
- `email` not `email_address`
- `phone` not `phone_number`

## JSON Field Strategy

### Grouping Related Fields

Related fields should be grouped into JSON objects to enable efficient processing and flexible schema evolution.

**Location fields:**
```json
{
  "location": {
    "street": "123 Main St",
    "city": "New York", 
    "state": "NY",
    "territory": "Northeast"
  }
}
```

**Activity metrics:**
```json
{
  "activity": {
    "days_active": {
      "weekly": 5,
      "monthly": 18,
      "yearly": 247
    },
    "logins": {
      "weekly": 12,
      "monthly": 45
    }
  }
}
```

### JSON Nesting Guidelines

**Standard depth:** One level of nesting for most cases
- `user_contact.name_first`
- `user_contact.address_street`

**Special cases:** Activity metrics can go two levels deep
- `activity.days_active.monthly`
- `activity.logins.weekly`

**Field count threshold:** If a JSON object would contain more than 4 elements, consider if there's a better data representation.

### Activity Metrics Pattern

Activity metrics follow a specific naming convention within JSON:

**Structure:** `activity.{metric}.{period}`

**Metric naming:** `{count_type}_{filter}`
- **Count type:** Plural indicates what's being counted
  - `days_*` = counting unique days
  - `logins` = counting individual events
- **Filter:** The qualifying condition (`active`, `edited`, etc.)
- **Period:** Temporal window (`weekly`, `monthly`, `yearly`)

**Examples:**
- `activity.days_active.weekly` = unique days with any activity in the past week
- `activity.logins.monthly` = total login events in the past month
- `activity.days_edited.quarterly` = unique days with editing activity in the past quarter

### Rolling Windows

**Standard periods:** Use predefined terms when possible
- `weekly`, `monthly`, `quarterly`, `yearly`

**Custom windows:** Use `l{days}` notation for non-standard periods
- `days_active_l91` = days active in last 91 days
- `logins_l7` = logins in last 7 days

## Field Ordering

### Standard Order Within Tables

1. **Primary Keys** - Object identifiers
2. **Time Fields** - `valid_from`, `valid_to`, `event_time`, etc.
3. **Foreign Keys** - Alphabetical order
4. **Attributes** - Alphabetical order
5. **Meta Fields** - System and audit fields

### Alphabetical Benefits

Alphabetical ordering of attributes provides:
- **Related field clustering** - Similar fields group together
- **Predictable location** - Easy to find specific fields
- **JSON flattening reliability** - Consistent hierarchy

## Scope and Application

### Layer-Specific Rules

**IN and DV Layers:** Preserve source field names, standardize structure only

**BV Layer and Beyond:** Apply OEF naming conventions for the first time
- Transform source field names to OEF standards
- Introduce object-centric naming
- Apply reserved term conventions

### Custom Fields in Marts

**Flexible naming:** Mart layer allows custom field names for business-specific requirements

**Documentation requirement:** Custom names must be documented with clear definitions

**Derived metrics:** Complex calculations get business-appropriate names rather than systematic names

## Edge Cases and Extensions

### Complex Temporal References

**Planned vs Actual:** Use `begin/end` for planned periods, `from/to` for actual occurrences
- `trial_begin` (planned start)
- `trial_active_from` (actual start)

**Custom temporal references:** Add new reserved terms when needed
- `tertial` for third occurrence
- Document additions to reserved term list

### Multi-State Fields

**Status patterns:** Use separate fields for complex state tracking
- `status` (current state)
- `pause_source` (reason for pause, null unless paused)

**Modifiers:** Add descriptive modifiers to core values
- `user_onboarding_begin_planned`
- `subscription_cancel_scheduled`

### Array and Set Handling

**Default behavior:** Ordered arrays contain 10 elements unless specified
- `actions_last_set` (last 10 actions)

**Custom sizes:** Specify when different from default
- `purchases_recent_set_5` (last 5 purchases)

This systematic approach to field naming creates predictable, self-documenting data structures that scale consistently across the entire framework while maintaining maximum clarity and minimum ambiguity.