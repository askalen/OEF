{% macro deploy_meta_tables() %}
{%- if execute -%}

{%- set create_model_table %}
CREATE TABLE IF NOT EXISTS meta.model (
  -- Core identity
  model_name VARCHAR(255) PRIMARY KEY,
  
  -- Data progression tracking
  data_from TIMESTAMP,
  data_to TIMESTAMP,
  effective_to TIMESTAMP,
  processed_at TIMESTAMP,
  
  -- Source-specific tracking
  source_processed_to TIMESTAMP,
  
  -- Concurrency control
  locked_run_id VARCHAR(255),
  locked_at TIMESTAMP,
  
  -- Configuration flags
  is_immutable BOOLEAN DEFAULT FALSE,
  is_slow BOOLEAN DEFAULT FALSE,
  is_src BOOLEAN DEFAULT FALSE
)
{%- endset %}

{%- call statement('create_model_table') -%}
  {{ create_model_table }}
{%- endcall -%}

{{ log("Deployed meta.model table", info=true) }}

{%- endif -%}
{% endmacro %}