# __init__.py
from dbt.adapters.oefsnowflake.connections import (
    OEFSnowflakeConnectionManager,
    OEFSnowflakeCredentials
)
from dbt.adapters.oefsnowflake.impl import OEFSnowflakeAdapter
from dbt.adapters.base import AdapterPlugin
from dbt.include import oefsnowflake

# Ensure snowflake adapter is loaded
import dbt.adapters.snowflake

Plugin = AdapterPlugin(
    adapter=OEFSnowflakeAdapter,
    credentials=OEFSnowflakeCredentials,
    include_path=oefsnowflake.PACKAGE_PATH,
    dependencies=["snowflake"]
)

__all__ = ["Plugin"]