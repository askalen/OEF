{% macro deploy_schemas() %}

{{ log("Deploying any schemas that don't exist", info=true) }}

{%- set create_model_table %}
CREATE SCHEMA IF NOT EXISTS meta;
CREATE SCHEMA IF NOT EXISTS src;
CREATE SCHEMA IF NOT EXISTS dv;
CREATE SCHEMA IF NOT EXISTS bv;
CREATE SCHEMA IF NOT EXISTS fct;
CREATE SCHEMA IF NOT EXISTS anl;
CREATE SCHEMA IF NOT EXISTS extraw;
CREATE SCHEMA IF NOT EXISTS extsrc;
CREATE SCHEMA IF NOT EXISTS extanl;
CREATE SCHEMA IF NOT EXISTS ref;

CREATE SCHEMA IF NOT EXISTS dev;
{%- endset %}

{% do run_query(create_model_table) -%}

{{ log("Deployed schemas:", info=true) }}
{{ log("  META", info=true) }}
{{ log("  SRC", info=true) }}
{{ log("  DV", info=true) }}
{{ log("  BV", info=true) }}
{{ log("  FCT", info=true) }}
{{ log("  ANL", info=true) }}
{{ log("  EXTRAW", info=true) }}
{{ log("  EXTSRC", info=true) }}
{{ log("  EXTANL", info=true) }}
{{ log("  REF", info=true) }}
{{ log("  DEV", info=true) }}
{% endmacro %}