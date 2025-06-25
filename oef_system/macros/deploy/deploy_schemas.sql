{% macro deploy_schemas() %}
{%- if execute -%}

{%- set create_model_table %}
CREATE SCHEMA IF NOT EXISTS meta 
{{ log("Deployed META schema", info=true) }}
{%- endset %}

{%- call statement('create_model_table') -%}
  {{ create_model_table }}
{%- endcall -%}

{%- endif -%}
{% endmacro %}