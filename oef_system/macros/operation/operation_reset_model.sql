{% macro operation_reset_model(model_name=none, force=false) %}
{%- if execute -%}

  {%- set target_model = model_name or this.name -%}
  
  {{ log("Resetting model: " ~ target_model, info=true) }}
  
  {# Check if model is locked by another process (unless force=true) #}
  {%- if not force -%}
    {%- set lock_check_query %}
      SELECT locked_run_id, locked_at
      FROM meta.model 
      WHERE model_name = '{{ target_model }}'
        AND locked_run_id IS NOT NULL 
        AND locked_run_id != '{{ invocation_id }}'
    {%- endset %}
    
    {%- set lock_results = run_query(lock_check_query) -%}
    {%- if lock_results and lock_results.rows|length > 0 -%}
      {{ log("  Model " ~ target_model ~ " is locked by another process. Use force=true to override.", info=true) }}
      {{ return(false) }}
    {%- endif -%}
  {%- endif -%}
  
  {# Drop the table if it exists #}
  {%- set drop_table_query %}
    DROP TABLE IF EXISTS {{ target_model }}
  {%- endset %}
  
  {%- set drop_results = run_query(drop_table_query) -%}
  
  {{ log("  ✓ Dropped table: " ~ target_model, info=true) }}
  
  {# Remove meta.model entry #}
  {%- set delete_meta_query %}
    DELETE FROM meta.model 
    WHERE model_name = '{{ target_model }}'
  {%- endset %}
  
  {%- set delete_results = run_query(delete_meta_query) -%}
  
  {{ log("  ✓ Removed meta entry for: " ~ target_model, info=true) }}
  
  {{ log("✓ Reset complete for model: " ~ target_model, info=true) }}
  
  {{ return(true) }}

{%- endif -%}
{% endmacro %}