{% macro process_h_table(target, source, unique_key, dest_columns) -%}
  {%- if execute -%}
    
    {# Get PK fields from model config #}
    {%- set model_configs = get_model_configs() -%}
    {%- set pk_fields = model_configs.pk_fields -%}
    
    {# Get all non-PK, non-meta fields for comparison #}
    {%- set compare_fields = [] -%}
    {%- for column in dest_columns -%}
      {%- if column.name not in pk_fields and not column.name.startswith('meta_') and column.name not in ['valid_from', 'valid_to'] -%}
        {%- do compare_fields.append(column.name) -%}
      {%- endif -%}
    {%- endfor -%}
    
    {# Return the processing query as a subquery #}
    {{ return("(" ~ generate_h_processing_sql(source, target, pk_fields, compare_fields, dest_columns) ~ ")") }}
    
  {%- endif -%}
{%- endmacro %}