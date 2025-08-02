# Object Evolution Framework (OEF)

A modern data engineering methodology that treats business object evolution as a first-class analytical concern alongside event tracking. Built for organizations that need to analyze how entities change over time, not just what events they participate in.

## What This Framework Provides

**Starting Point:** Raw data in any columnar format, with a focus on object attributes and historical state changes

**End Result:** Two clean databases - a Processing Database for transformation work and a Reporting Database with purpose-built data marts

**Complete Automation:** Behind-the-scenes macros handle complex processing logic, with templates that make table development consistent and minimal-effort

**Technology Stack:** Built on Snowflake + dbt Core + orchestration scheduler, but the methodology can be adapted to other modern data platforms

## Why Choose OEF

- **State-Centric Analytics:** Track business object evolution over time, not just events
- **Rebuild Efficiency:** Change business logic without recalculating expensive aggregations  
- **Historical Accuracy:** Complete audit trail with point-in-time analysis capabilities
- **Standardized Patterns:** Consistent naming and structure across all tables
- **Complete Implementation:** Framework + dbt package + templates for immediate deployment

## Documentation

### [Introduction & Overview](docs/introduction.md)
Complete overview of the framework, use cases, and implementation approach.

### [Principles](docs/principles.md)
Core concepts that drive all framework decisions:
- [Absolute Historical Truth](docs/principles.md#absolute-historical-truth)
- [Object State Over Transaction Events](docs/principles.md#object-state-over-transaction-events)
- [Processing Efficiency Over Storage Optimization](docs/principles.md#processing-efficiency-over-storage-optimization)

### [Business Object Planning](docs/plan_business_objects.md)
Systematic approach to designing business objects and their relationships:
- [Business Object Definitions](docs/plan_business_objects.md#business-object-definitions)
- [Source System Mapping](docs/plan_business_objects.md#source-system-mapping)
- [Relationship DAG](docs/plan_business_objects.md#relationship-dag)

### [Data Inventory Planning](docs/plan_data_inventory.md)
Instructions for subject matter experts to document source systems:
- [Planning Spreadsheet](docs/plan_data_inventory.md#phase-1-planning-spreadsheet)
- [YML File Creation](docs/plan_data_inventory.md#phase-2-yml-file-creation)
- [Quality Checklist](docs/plan_data_inventory.md#quality-checklist)

### [Table Types](docs/table-types.md)
Standard table structures and when to use each:
- [H - Historical Tables](docs/table-types.md#h---historical-tables)
- [R - Registry Tables](docs/table-types.md#r---registry-tables)
- [O - Override Tables](docs/table-types.md#o---override-tables)
- [E - Event Tables](docs/table-types.md#e---event-tables)
- [AX - Aggregate Tables](docs/table-types.md#ax---aggregate-tables)
- [SX - Periodic Snapshots](docs/table-types.md#sx---periodic-snapshots)
- [C - Current State Tables](docs/table-types.md#c---current-state-tables)
- [Time Variants](docs/table-types.md#time-variants)

### [Layers](docs/layers.md)
Data processing layers from raw to analytics-ready:
- [SRC - Source Layer](docs/layers.md#src---source-layer)
- [VLTX - Vault Transformation](docs/layers.md#vltx---vault-transformation-layer)
- [VLT - Vault Layer](docs/layers.md#vlt---vault-layer)
- [WHX - Warehouse Transformation](docs/layers.md#whx---warehouse-transformation-layer)
- [WH - Warehouse Layer](docs/layers.md#wh---warehouse-layer)
- [MART - Mart Layer](docs/layers.md#mart---mart-layer)

### [Configurations](docs/configurations.md)
Model configuration options and their usage:
- [unique_key](docs/configurations.md#unique_key)
- [_initial_date](docs/configurations.md#_initial_date)
- [_delta_limit](docs/configurations.md#_delta_limit)
- [_rollback_days](docs/configurations.md#_rollback_days)

### [Fields](docs/fields.md)
Standard field types and naming conventions:
- [Naming Structure](docs/fields.md#naming-structure)
- [Reserved Terms](docs/fields.md#reserved-terms)
- [JSON Field Strategy](docs/fields.md#json-field-strategy)
- [Field Ordering](docs/fields.md#field-ordering)

### [Data Inventory Template](docs/template_data_inventory.yml)
YML template for documenting source systems and tables.

## Package Implementation

This framework includes a complete dbt package with:
- **Macros:** Automated generation of standard table patterns
- **Templates:** Pre-built model structures for each layer
- **Functions:** Custom Snowflake functions for advanced processing
- **Operations:** Deployment, backup, and maintenance utilities

See the `oef_system/` directory for the complete implementation.

## Quick Start

1. **Environment Setup:** Deploy Snowflake + dbt Core + scheduler
2. **Package Installation:** Install the OEF dbt package
3. **Design Phase:** Plan business objects using the [design guide](docs/plan_business_objects.md)
4. **Data Inventory:** Document source systems using the [inventory guide](docs/plan_data_inventory.md)
5. **Implementation:** Build tables layer by layer using provided templates
6. **Deployment:** Configure data marts for your specific use cases

## Status

This framework is under active development. While the core methodology is stable and has been tested in production environments, the dbt package and documentation are being refined based on real-world implementations.

## Contributing

Contributions, feedback, and real-world implementation experiences are welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where we especially welcome input:
- Additional connector support beyond Snowflake
- Performance optimizations for large-scale implementations
- Documentation improvements and examples
- Bug reports and edge case scenarios

## Support

- **Documentation Issues:** Open a GitHub issue
- **Implementation Questions:** Use GitHub Discussions
- **Bug Reports:** Open a GitHub issue with reproduction steps

## Disclaimer

This framework represents opinionated approaches to data engineering that work well for specific use cases. It is not a universal solution and may not be appropriate for all organizations or data scenarios. 

Key considerations:
- Optimized for analytical workloads, not operational systems
- Requires modern cloud data warehouse capabilities
- Best suited for slowly-changing dimensional data
- Assumes organizational commitment to standardized patterns

Evaluate fit for your specific requirements before implementation.

## License

Copyright (c) 2025 Adam Skalenakis

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.