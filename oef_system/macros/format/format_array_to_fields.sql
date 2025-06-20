{% macro format_array_to_fields(field_array, prefix='', suffix='') -%}
{%- for field in field_array -%}
{{ prefix }}{{ field }}{{ suffix }}
{%- if not loop.last -%}
,
{%- endif -%}
{%- endfor -%}
{%- endmacro -%}