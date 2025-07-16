{% macro snowflake__get_merge_sql(target, source, unique_key, dest_columns, incremental_predicates=none) -%}
  
  {# Call the original with our processed source #}
  {% set original_result = dbt_snowflake.get_merge_sql(target, processed_source, unique_key, dest_columns, incremental_predicates) %}
  
  {{ return(original_result) }}

{%- endmacro %}