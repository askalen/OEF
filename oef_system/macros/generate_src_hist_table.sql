{% macro generate_src_table_h(source_path) -%}
{%- if execute -%}
{%- set source_main = model.sources[0] -%}
{%- set pulled_configs = pull_source_configs() -%}
{%- set field_collections = pulled_configs.fields -%}
{%- set source_configs = pulled_configs.configs -%}


{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}
{#- SETTING UP SQL CODE CHUNKS -#}
{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}

{%- set sql_filter -%}
  and {{ field_collections.process_time }} >  process_from
  and {{ field_collections.process_time }} <= process_to
{%- endset -%}


{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}
{#- GENERATING MODEL CODE -#}
{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}


WITH new_data AS (
SELECT
  {{ format_field_array(fields.pk) }},
  {{ fields.data_time }} AS valid_from,
  {{ format_field_array(fields.other) }}
FROM
  {{ source(source_main[0], source_main[1]) }}
WHERE 1 = 1
  {{ sql_filter }}
    {% if source_configs.filter -%}and {{ source_configs.filter }}{%- endif -%}

  {% if schema_change %}

UNION ALL

SELECT
  {{ format_field_array(fields.pk) }},
  {{ fields.data_time }} AS valid_from,
  {{ format_field_array(fields.other) }}
FROM
  {{ source(source_main[0], source_main[1]) }}
WHERE 1 = 1
  {% if source_configs.filter is not none -%}and {{ source_configs.filter }}{%- endif %}
    and {{ field_collections.data_time }} <= data_from
QUALIFY
    row_number() over (
      partition by {{ field_collections.pk | join(",") }}
      order by {{ field_collections.data_time }} desc
    ) = 1
  {%- endif -%}
)
combined AS (
  SELECT
    {{ sql_select_h }},
    HASH(
      {{ field_collections.other }}
    ) as data_hash
  FROM
    new_data

  UNION ALL

  SELECT
    old.{{ sql_select_h }},
    old.data_hash
  FROM 
    {{ this }}

)


{%- endif -%}
{%- endmacro -%}