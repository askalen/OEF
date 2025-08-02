{% macro deploy_schemas() %}

{{ log("Deploying any schemas that don't exist", info=true) }}

{%- set create_model_table %}
CREATE SCHEMA IF NOT EXISTS meta;
CREATE SCHEMA IF NOT EXISTS src;
CREATE SCHEMA IF NOT EXISTS vltx;
CREATE SCHEMA IF NOT EXISTS vlt;
CREATE SCHEMA IF NOT EXISTS whx;
CREATE SCHEMA IF NOT EXISTS wh;
CREATE SCHEMA IF NOT EXISTS extsrc;
CREATE SCHEMA IF NOT EXISTS extwh;
CREATE SCHEMA IF NOT EXISTS ref;

CREATE SCHEMA IF NOT EXISTS dev;
{%- endset %}

{% do run_query(create_model_table) -%}

{{ log("Deployed schemas:", info=true) }}
{{ log("  META", info=true) }}
{{ log("  SRC", info=true) }}
{{ log("  VLTX", info=true) }}
{{ log("  VLT", info=true) }}
{{ log("  WHX", info=true) }}
{{ log("  WH", info=true) }}
{{ log("  EXTSRC", info=true) }}
{{ log("  EXTWH", info=true) }}
{{ log("  REF", info=true) }}

{% endmacro %}