{% macro get_model_sql() %}
  {%- if execute -%}
    {# Model path is available in the graph #}
    {%- set model_path = model.original_file_path -%}
    {%- set full_path = model.root_path ~ '/' ~ model_path -%}
    
    {# Read using dbts file reading capability #}
    {%- set sql_content = load_file_contents(full_path) -%}
    {{ return(sql_content) }}
  {%- endif -%}
{% endmacro %}