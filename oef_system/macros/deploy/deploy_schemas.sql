{% macro deploy_schemas() %}

{{ log("Deploying any schemas that don't exist", info=true) }}

{%- set create_model_table %}
CREATE SCHEMA IF NOT EXISTS meta;
CREATE SCHEMA IF NOT EXISTS src;
CREATE SCHEMA IF NOT EXISTS ain;
CREATE SCHEMA IF NOT EXISTS ana;
CREATE SCHEMA IF NOT EXISTS vin;
CREATE SCHEMA IF NOT EXISTS vlt;
{%- endset %}

{% do run_query(create_model_table) -%}

{{ log("Deployed schemas:", info=true) }}
{{ log("  META", info=true) }}
{{ log("  SRC", info=true) }}
{{ log("  VIN", info=true) }}
{{ log("  VLT", info=true) }}
{{ log("  AIN", info=true) }}
{{ log("  ANA", info=true) }}

{% endmacro %}