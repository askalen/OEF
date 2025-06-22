# Object Evolution Framework (OEF)

**A state-focused data architecture methodology for modern data warehouses**

Created by Adam Skalenakis  
Initial Development: June 2025  
Copyright © 2025 Adam Skalenakis

## Overview

The Object Evolution Framework (OEF) is a comprehensive data engineering system that transforms raw data into analytics-ready information through a state-focused, business-oriented approach. Unlike traditional event-centric architectures, OEF treats business object state evolution as the primary analytical foundation.

## Project Scope

This framework provides:

- **Complete methodology** for state-focused data architecture
- **dbt Core implementation** with custom macros and templates  
- **Snowflake optimization** patterns and custom functions
- **Apache Airflow integration** for orchestration
- **Comprehensive documentation** covering implementation and deployment

## Core Innovation

OEF reimagines data warehousing by:

- Focusing on **business object state progression** rather than discrete events
- Creating **aggregatable dimensions** that maintain full historical context
- Enabling **modular rebuilds** by isolating volatile components
- Providing **consistent structural patterns** across all table types

## Architecture

The framework implements a seven-layer architecture:

1. **RAW** - Original source data
2. **SRC** - Cleaned and structured source tables  
3. **VIN** - Vault Intermediate (when needed for complex transformations)
4. **VLT** - Business Vault (normalized business objects)
5. **AIN** - Analytics Intermediate (parallel event aggregation and denormalization)
6. **ANA** - Analytics Layer (complete business objects)
7. **MRT** - Data Marts (purpose-built consumption tables)

## Key Benefits

- **Rebuild Efficiency**: Change business logic without recalculating expensive aggregations
- **Historical Accuracy**: Complete audit trail of all object state changes
- **Analytical Flexibility**: Objects prepared for any metric aggregation pattern
- **Operational Clarity**: Consistent naming and structure patterns
- **Governance Simplicity**: Clear database and schema separation

## Technology Stack

- **Snowflake**: Cloud data warehouse infrastructure
- **dbt Core**: Data transformation and modeling
- **Apache Airflow**: Workflow orchestration
- **Git**: Version control and deployment

*Note: While optimized for this stack, the methodology can be adapted to other modern data platforms.*

## Development Status

This framework represents original research and development in data architecture methodology. All concepts, patterns, and implementations are independently created and not derived from any commercial or proprietary systems.

**Current Status**: Active development of core framework and documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Attribution

When using or referencing this framework, please provide appropriate attribution to the original author and this repository.

---

**Independent Work Disclaimer**: This framework was developed independently by Adam Skalenakis as original research in data engineering methodology. All concepts, designs, and implementations are the result of independent analysis and innovation in the field of modern data architecture.
