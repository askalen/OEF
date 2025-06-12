{% macro test2() -%}
{{ log("Result: ", info=True) }}
{{ log(example.max, info=True) }}
{% endmacro %}