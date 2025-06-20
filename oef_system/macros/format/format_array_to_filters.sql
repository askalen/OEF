{% macro format_array_to_filters(filter_array, operator='and') -%}

{%- for filter in filter_array -%}
  ({{ filter }})
  {%- if not loop.last %} {{ operator }} 
  {% endif -%}
{%- endfor -%}

{%- endmacro -%}