{% macro pull_source_configs() -%}
{%- if execute -%}

{%- set field_collections = {
  'pk': [],
  'data_time': [],
  'process_time': [],
  'other': []
} -%}

{%- set source_main = model.sources[0] -%}
{%- set source_key = 'source.' ~ model.package_name ~ '.' ~ source_main[0] ~ '.' ~ source_main[1] -%}
{%- set source_node = graph.sources[source_key] -%}
{%- set source_fields = source_node.columns -%}
{%- set valid_from = source_node.meta._valid_from -%}
{%- set valid_to = source_node.meta._valid_to -%}
{%- set source_type = source_node.meta._type -%}

{%- set source_configs = {
  'type': source_type,
  'valid_from': valid_from,
  'valid_to': valid_to
} -%}

{%- set sorted_fields = source_fields.items() | sort -%}

{%- for field_name, field_obj in sorted_fields -%}
  {%- if not field_obj._exclude -%}
    {%- set purpose = field_obj._purpose | default('other') -%}
    {%- set collection_key = purpose if purpose in ['pk', 'data_time', 'process_time'] else 'other' -%}
    
    {%- if field_obj._transformation -%}
      {%- set transformation = field_obj._transformation.lower() -%}
      {%- if purpose in ['data_time', 'process_time'] -%}
        {%- if ' as ' in transformation -%}
          {%- set as_position = transformation.rfind(' as ') -%}
          {%- set field_expr = transformation[:as_position].strip() -%}
        {%- else -%}
          {%- set field_expr = transformation -%}
        {%- endif -%}
      {%- else -%}
        {%- set field_expr = transformation -%}
      {%- endif -%}
    {%- else -%}
      {%- set field_expr = field_name -%}
    {%- endif -%}
    
    {%- do field_collections[collection_key].append(field_expr) -%}
  {%- endif -%}
{%- endfor -%}

{%- for field_type in ['data_time', 'process_time'] -%}
  {%- set count = field_collections[field_type] | length -%}
  {%- if count == 0 -%}
    {{- exceptions.raise_compiler_error("No " ~ field_type ~ " field found") -}}
  {%- elif count > 1 -%}
    {{- exceptions.raise_compiler_error("More than one " ~ field_type ~ " field found") -}}
  {%- endif -%}
{%- endfor -%}

{%- set field_collections = {
  'pk': field_collections.pk,
  'data_time': field_collections.data_time[0],
  'process_time': field_collections.process_time[0],
  'other': field_collections.other
} -%}

{{ return({'fields': field_collections, 'configs': source_configs}) }}

{%- endif -%}
{%- endmacro -%}