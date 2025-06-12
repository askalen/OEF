{% macro generate_src_table(source_path) -%}
{%- if execute -%}
{%- set source_main = model.sources[0] -%}
{%- set pulled_configs = pull_source_configs() -%}
{%- set field_collections = pulled_configs.fields -%}
{%- set source_configs = pulled_configs.configs -%}


{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}
{#- SETTING UP SQL CODE CHUNKS -#}
{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}

{%- set sql_select_h -%}
{% set all_fields = field_collections.pk + 
                    [field_collections.data_time ~ ' as valid_from'] + 
                    field_collections.other -%}
  {{ all_fields | join("\n  , ") }}
{%- endset -%}

{%- set sql_select_e -%}
{% set all_fields = field_collections.pk + 
                    [field_collections.data_time ~ ' as event_time'] + 
                    field_collections.other -%}
  {{ all_fields | join("\n  , ") }}
{%- endset -%}

{%- set sql_filter_h_first %} 
  and {{ field_collections.data_time }} < '{{source_configs.valid_from}}'::date
QUALIFY
  row_number() over (
    partition by {{ field_collections.pk | join(",") }}
    order by {{ field_collections.data_time }} desc
  ) = 1
{%- endset -%}

{%- set sql_filter -%}
  and {{ field_collections.process_time }} >  delta_from
  and {{ field_collections.process_time }} <= delta_to
{%- endset -%}


{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}
{#- GENERATING MODEL CODE -#}
{#- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -#}

SELECT
    {{ sql_select_e }}
FROM
  {{ source(source_main[0], source_main[1]) }}
WHERE 1 = 1
  {{ sql_filter }}

{%- endif -%}
{%- endmacro -%}