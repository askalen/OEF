{% macro generate_src_table(source_path, table_type) -%}
{%- if execute -%}
{%- if table_type == 'History' -%}
  {% set sql = generate_src_h_table(source_path) %}
{%- elif table_type == 'Event' -%}
  {% set sql = generate_src_event_table(source_path) %}
{%- endif -%}
{{ format_sql(sql) }}
{%- endif -%}
{%- endmacro -%}