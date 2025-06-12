{% macro test1() -%}
{% set example = namespace(
      max = modules.datetime.datetime.now(),
      min = modules.datetime.datetime(2000, 1, 1, 0, 0, 0),
      yoda_max = modules.datetime.datetime.now(),
      yoda_min = modules.datetime.datetime(2000, 1, 1, 0, 0, 0)
    ) %}
{{ log("Result1: ", info=True) }}
{{ log(example.max, info=True) }}
{{ test2() }}
{% endmacro %}