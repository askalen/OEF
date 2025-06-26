{% macro get_table_meta(table_ref, table_type=none, table_period=none) -%}
{%- if execute -%}

{%- set table_parts = table_ref.split('.') -%}
{%- set is_source = table_parts|length >= 3 -%}

{#- Determine time field names -#}
{%- if is_source -%}
  {%- set source_configs = get_source_configs() -%}
  {%- set data_time_field = source_configs.fields.data_time -%}
  {%- set process_time_field = source_configs.fields.process_time -%}
{%- else -%}
  {%- set process_time_field = 'meta_processed_at' -%}
  {%- if table_type == 'event' -%}
    {%- set data_time_field = 'event_time' -%}
  {%- elif table_type == 'aggregate' -%}
    {%- set data_time_field = 'period_begin' -%}
  {%- elif table_type == 'pit' -%}
    {%- set data_time_field = 'valid_at' -%}
  {%- else -%}
    {%- set data_time_field = 'valid_from' -%}
  {%- endif -%}
{%- endif -%}

{#- Parse table reference for query components -#}
{%- if table_parts|length == 3 -%}
  {%- set table_database = table_parts[0] -%}
  {%- set table_schema = table_parts[1] -%}
  {%- set table_name = table_parts[2] -%}
{%- elif table_parts|length == 2 -%}
  {%- set table_database = target.database -%}
  {%- set table_schema = table_parts[0] -%}
  {%- set table_name = table_parts[1] -%}
{%- else -%}
  {{ operation_clear_lock(force=true) }}
  {{- exceptions.raise_compiler_error("Invalid table reference format: " ~ table_ref) -}}
{%- endif -%}

{#- Build query to get metadata -#}
{%- set meta_query %}
WITH field_info AS (
  SELECT 
    column_name,
    data_type,
    ordinal_position
  FROM {{ table_database }}.INFORMATION_SCHEMA.COLUMNS
  WHERE table_name = UPPER('{{ table_name }}')
    AND table_schema = UPPER('{{ table_schema }}')
    AND table_catalog = UPPER('{{ table_database }}')
  ORDER BY ordinal_position
),
time_ranges AS (
  SELECT 
    MIN({{ data_time_field }}) as min_data_time,
    MAX({{ data_time_field }}) as max_data_time,
    {%- if is_source %}
    MIN({{ process_time_field }}) as min_process_time,
    MAX({{ process_time_field }}) as max_process_time
    {%- else %}
    MIN({{ process_time_field }}) as min_process_time,
    MAX({{ process_time_field }}) as max_process_time
    {%- endif %}
  FROM {{ table_ref }}
),
field_array AS (
  SELECT 
    ARRAY_AGG(
      OBJECT_CONSTRUCT(
        'name', column_name,
        'type', data_type,
        'position', ordinal_position
      ) 
      ORDER BY ordinal_position
    ) as fields
  FROM field_info
)
SELECT 
  TRUE as exists,
  '{{ table_ref }}' as table_name,
  fa.fields,
  tr.min_data_time,
  tr.max_data_time,
  tr.min_process_time,
  tr.max_process_time
FROM field_array fa
CROSS JOIN time_ranges tr
{%- endset -%}

{#- Execute query with error handling using run_query -#}
{%- set result = none -%}
{%- set query_failed = false -%}

{%- set results = run_query(meta_query) -%}

{%- if results and results.rows|length > 0 -%}
  {%- set row = results.rows[0] -%}
  
  {#- Check for NULL time values -#}
  {%- if row[3] is none or row[4] is none -%}
    {{ operation_clear_lock(force=true) }}
    {{- exceptions.raise_compiler_error("Table " ~ table_ref ~ " exists but " ~ data_time_field ~ " contains NULL values") -}}
  {%- endif -%}
  
  {%- if is_source and (row[5] is none or row[6] is none) -%}
    {{ operation_clear_lock(force=true) }}
    {{- exceptions.raise_compiler_error("Source table " ~ table_ref ~ " exists but " ~ process_time_field ~ " contains NULL values") -}}
  {%- elif not is_source and (row[5] is none or row[6] is none) -%}
    {{ operation_clear_lock(force=true) }}
    {{- exceptions.raise_compiler_error("Model table " ~ table_ref ~ " exists but meta_processed_at contains NULL values") -}}
  {%- endif -%}
  
  {%- set result = {
    'exists': row[0],
    'table_name': row[1],
    'fields': row[2],
    'min_data_time': row[3],
    'max_data_time': row[4],
    'min_process_time': row[5],
    'max_process_time': row[6]
  } -%}
{%- else -%}
  {%- set query_failed = true -%}
{%- endif -%}

{#- Handle table not existing -#}
{%- if query_failed -%}
  {%- set result = {
    'exists': false,
    'table_name': table_ref
  } -%}
{%- endif -%}

{{ return(result) }}

{%- endif -%}
{%- endmacro -%}