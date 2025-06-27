{% macro set_model_meta_lock() %}
{%- if execute -%}

{%- set lock_query %}
MERGE INTO meta.model AS target
USING (SELECT '{{ model.name }}' AS model_name, '{{ invocation_id }}' AS run_id) AS source
ON target.model_name = source.model_name
WHEN MATCHED AND target.locked_run_id IS NULL THEN
  UPDATE SET 
    locked_run_id = source.run_id,
    locked_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (model_name, locked_run_id, locked_at)
  VALUES (source.model_name, source.run_id, CURRENT_TIMESTAMP())
{%- endset %}

{%- call statement('set_model_meta_lock') -%}
  {{ lock_query }}
{%- endcall -%}

{%- endif -%}
{% endmacro %}