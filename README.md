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
- [Source vs Business Data](docs/principles.md#source-vs-business-data)
- [State-Focused Architecture](docs/principles.md#state-focused-architecture)
- [Object Hierarchy](docs/principles.md#object-hierarchy)

### [Design](docs/design.md)
Planning and defining your business objects and data architecture:
- [Business Object Definition](docs/design.md#business-object-definition)
- [Object Hierarchy Planning](docs/design.md#object-hierarchy-planning)
- [Key Mapping Strategy](docs/design.md#key-mapping-strategy)

### [Table Types](docs/table-types.md)
Standard table structures and when to use each:
- [H - Historical Tables](docs/table-types.md#h-historical-tables)
- [R - Registry Tables](docs/table-types.md#r-registry-tables)
- [M - Mapping Tables](docs/table-types.md#m-mapping-tables)
- [E - Event Tables](docs/table-types.md#e-event-tables)
- [A - Aggregate Tables](docs/table-types.md#a-aggregate-tables)
- [S - Snapshot Tables](docs/table-types.md#s-snapshot-tables)
- [Time Variants](docs/table-types.md#time-variants)

### [Layers](docs/layers.md)
Data processing layers from raw to analytics-ready:
- [Source - Raw Data](docs/layers.md#source-raw-data)
- [IN - Ingestion Layer](docs/layers.md#in-ingestion-layer)
- [DV - Data Vault](docs/layers.md#dv-data-vault)
- [BV - Business Vault](docs/layers.md#bv-business-vault)
- [FCT - Fact Layer](docs/layers.md#int-fact-layer)
- [OUT - Output Layer](docs/layers.md#out-output-layer)
- [MART - Mart Layer](docs/layers.md#mart-mart-layer)

### [Configurations](docs/configurations.md)
Data processing layers from raw to analytics-ready:
- [unique_key](docs/configurations.md#unique_key)
- [_initial_date](docs/configurations.md#_initial_date)
- [_delta_limit](docs/configurations.md#_delta_limit)
- [_rollback_days](docs/configurations.md#_rollback_days)

### [Fields](docs/fields.md)
Standard field types and naming conventions:
- [Primary Keys](docs/fields.md#primary-keys)
- [Time Fields](docs/fields.md#time-fields)
- [Attribute Fields](docs/fields.md#attribute-fields)
- [Meta Fields](docs/fields.md#meta-fields)

### [Meta Tables](docs/meta-tables.md)
System tables that track processing state and metadata:
- [meta.model](docs/meta-tables.md#metamodel)
- [meta.run](docs/meta-tables.md#metarun)
- [Usage Patterns](docs/meta-tables.md#usage-patterns)

### [Model Execution](docs/model-execution.md)
How the system processes data and manages state:
- [Processing Stages](docs/model-execution.md#processing-stages)
- [Cursor Tracking](docs/model-execution.md#cursor-tracking)
- [Locking Mechanism](docs/model-execution.md#locking-mechanism)
- [Delta Processing](docs/model-execution.md#delta-processing)
- [Rollback Operations](docs/model-execution.md#rollback-operations)

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
3. **Design Phase:** Plan business objects using the design guide
4. **Implementation:** Build tables layer by layer using provided templates
5. **Deployment:** Configure data marts for your specific use cases

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