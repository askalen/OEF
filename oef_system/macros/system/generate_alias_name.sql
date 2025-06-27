{% macro generate_alias_name(custom_alias_name, node) -%}
    {%- if custom_alias_name is none -%}
        {# Strip the first part of the model name if it matches the schema #}
        {%- set model_name = node.name -%}
        {%- set schema_name = node.config.schema -%}
        {%- if schema_name and model_name.startswith(schema_name ~ '_') -%}
            {{ model_name[schema_name|length + 1:] }}
        {%- else -%}
            {{ model_name }}
        {%- endif -%}
    {%- else -%}
        {{ custom_alias_name | trim }}
    {%- endif -%}
{%- endmacro %}