-- macros/persistent_vars.sql
-- Custom persistent variable functionality for OEF Snowflake adapter

{% macro set_var(key, value) %}
  {%- if execute -%}
    {%- do adapter.set_var(key, value) -%}
  {%- endif -%}
  {{ return('') }}
{% endmacro %}

{% macro get_var(key, default=none) %}
  {%- if execute -%}
    {{ return(adapter.get_var(key, default)) }}
  {%- else -%}
    {{ return(default) }}
  {%- endif -%}
{% endmacro %}

{% macro clear_vars() %}
  {%- if execute -%}
    {%- do adapter.clear_vars() -%}
  {%- endif -%}
  {{ return('') }}
{% endmacro %}

{% macro list_vars() %}
  {%- if execute -%}
    {{ return(adapter.list_vars() | join(', ')) }}
  {%- else -%}
    {{ return('') }}
  {%- endif -%}
{% endmacro %}