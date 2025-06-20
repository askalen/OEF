{% macro get_model_configs() -%}
{%- if execute -%}

{%- set model_key = 'model.' ~ model.package_name ~ '.' ~ model.name -%}
{%- set model_node = graph.nodes[model_key] -%}

{%- if not model_node -%}
  {{- exceptions.raise_compiler_error("Model node not found in graph: " ~ model_key) -}}
{%- endif -%}

{%- set model_configs = model_node.config -%}
{%- set model_fields = model_node.columns -%}

{%- set pk_fields = [] -%}
{%- if model_fields -%}
  {%- set sorted_fields = model_fields.items() | sort -%}
  {%- for field_name, field_obj in sorted_fields -%}
    {%- if field_obj.meta._purpose == 'pk' -%}
      {%- do pk_fields.append(field_name) -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

{%- set upstreams = {
  'models': [],
  'sources': [],
  'seeds': []
} -%}

{%- for dependency in model_node.depends_on.nodes -%}
  {%- if dependency.startswith('model.') -%}
    {%- set model_name = dependency.split('.')[-1] -%}
    {%- do upstreams.models.append(model_name) -%}
  {%- elif dependency.startswith('source.') -%}
    {%- set source_parts = dependency.split('.') -%}
    {%- set source_name = source_parts[-2] ~ '.' ~ source_parts[-1] -%}
    {%- do upstreams.sources.append(source_name) -%}
  {%- elif dependency.startswith('seed.') -%}
    {%- set seed_name = dependency.split('.')[-1] -%}
    {%- do upstreams.seeds.append(seed_name) -%}
  {%- endif -%}
{%- endfor -%}

{%- set model_name_parts = model.name.split('_') -%}
{%- set suffix = model_name_parts[-1] if model_name_parts|length > 1 else '' -%}

{%- set type_mapping = {
  'h': 'history',
  'e': 'event', 
  'a': 'aggregate',
  'c': 'current',
  'd': 'definition',
  'p': 'pit'
} -%}

{%- set period_mapping = {
  'h': 'hour',
  'd': 'day',
  'w': 'week', 
  'm': 'month',
  'q': 'quarter',
  'y': 'year'
} -%}

{%- set table_type = null -%}
{%- set table_period = null -%}

{%- if suffix|length >= 1 -%}
  {%- set first_letter = suffix[0]|lower -%}
  {%- set table_type = type_mapping.get(first_letter, null) -%}
{%- endif -%}

{%- if suffix|length >= 2 -%}
  {%- set second_letter = suffix[1]|lower -%}
  {%- set table_period = period_mapping.get(second_letter, null) -%}
{%- endif -%}

{%- set result = {
  'configs': model_configs,
  'upstreams': upstreams,
  'pk_fields': pk_fields,
  'type': table_type,
  'period': table_period
} -%}

{{ return(result) }}

{%- endif -%}
{%- endmacro -%}