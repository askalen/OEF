{% set sql %}
WHERE
{{ format_array_to_filters(["'cat' = 4",'field1 > field2','1 = 1']) }}
{% endset %}
{{ sql }}
{{ format_sql(sql) }}