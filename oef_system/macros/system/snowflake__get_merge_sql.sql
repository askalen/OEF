{% macro snowflake__get_merge_sql(target, source, unique_key, dest_columns, incremental_predicates=none) -%}
  
  {# Determine if we need processing #}
  {%- set table_processing = config.get('_table_processing', 'auto') -%}
  
  {%- if table_processing == 'auto' -%}
    {%- if target.identifier.endswith('_h') -%}
      {%- set table_processing = 'h' -%}
    {%- elif target.identifier.endswith('_e') -%}
      {%- set table_processing = 'e' -%}
    {%- elif target.identifier.endswith('_a') or target.identifier.endswith('_ad') -%}
      {%- set table_processing = 'a' -%}
    {%- else -%}
      {%- set table_processing = 'none' -%}
    {%- endif -%}
  {%- endif -%}
  
  {# Apply processing or use source directly #}
  {%- if table_processing == 'h' -%}
    {%- set processed_source = process_h_table(target, source, unique_key, dest_columns) -%}
  {%- elif table_processing == 'e' -%}
    {%- set processed_source = process_e_table(target, source, unique_key, dest_columns) -%}
  {%- elif table_processing == 'a' -%}
    {%- set processed_source = process_a_table(target, source, unique_key, dest_columns) -%}
  {%- else -%}
    {%- set processed_source = source -%}
  {%- endif -%}
  
  {# Call the original with our processed source #}
  {% set original_result = dbt_snowflake.get_merge_sql(target, processed_source, unique_key, dest_columns, incremental_predicates) %}
  
  {{ return(original_result) }}

{%- endmacro %}