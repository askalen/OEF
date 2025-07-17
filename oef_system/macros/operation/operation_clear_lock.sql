{% macro operation_clear_lock(model_name=none, force=false) %}
{%- if execute -%}
  {%- set target_model = model_name or model.name -%}
  
  {%- set unlock_query %}
    UPDATE meta.model 
    SET 
      locked_run_id = NULL,
      locked_at = NULL
    WHERE model_name = '{{ target_model }}'
      {%- if not force %}
      AND locked_run_id = '{{ invocation_id }}'  -- Only clear if we own the lock
      {%- endif %}
  {%- endset %}
  
  {%- set results = run_query(unlock_query) -%}
  
  {%- if force -%}
    {{ log("  ✓ Force cleared lock for model: " ~ target_model, info=true) }}
  {%- else -%}
    {{ log("✓   Cleared lock for model: " ~ target_model, info=true) }}
  {%- endif -%}
{%- endif -%}
{% endmacro %}

{% macro clear_stale_locks() %}
{%- if execute -%}
  {%- set timeout_minutes = var('lock_timeout_minutes', 30) -%}
  
  {{ log("  Clearing stale locks older than " ~ timeout_minutes ~ " minutes...", info=true) }}
  
  {%- set clear_query %}
    UPDATE meta.model 
    SET 
      locked_run_id = NULL,
      locked_at = NULL
    WHERE locked_at < DATEADD('minute', -{{ timeout_minutes }}, CURRENT_TIMESTAMP())
      AND locked_run_id IS NOT NULL
  {%- endset %}
  
  {%- set results = run_query(clear_query) -%}
  
  {%- if results -%}
    {%- set rows_affected = results.rows_affected if results.rows_affected is defined else 0 -%}
    {{ log("    Cleared " ~ rows_affected ~ " stale locks", info=true) }}
  {%- endif -%}
  
{%- endif -%}
{% endmacro %}