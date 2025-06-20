{% macro get_source_configs() -%}
{%- if execute -%}

{%- set source_main = model.sources[0] -%}
{%- set source_key = 'source.' ~ model.package_name ~ '.' ~ source_main[0] ~ '.' ~ source_main[1] -%}
{%- set source_node = graph.sources[source_key] -%}

{%- if not source_node -%}
  {{- exceptions.raise_compiler_error("Source node not found in graph: " ~ source_key) -}}
{%- endif -%}

{%- set source_configs = source_node.meta -%}
{%- set source_fields = source_node.columns -%}

{%- set field_collections = {
  'pk': [],
  'data_time': [],
  'process_time': [],
  'other': []
} -%}

{%- if source_fields -%}
  {%- set sorted_fields = source_fields.items() | sort -%}
  
  {%- for field_name, field_obj in sorted_fields -%}
    {%- if not field_obj.meta._exclude -%}
      {%- set purpose = field_obj.meta._purpose | default('other') -%}
      {%- set valid_purposes = ['pk', 'data_time', 'process_time', 'other'] -%}
      
      {%- if purpose not in valid_purposes -%}
        {{- exceptions.raise_compiler_error("Invalid _purpose '" ~ purpose ~ "' for field '" ~ field_name ~ "'. Valid purposes are: " ~ valid_purposes | join(', ')) -}}
      {%- endif -%}
      
      {%- if field_obj.meta._transformation -%}
        {%- set transformation = field_obj.meta._transformation -%}
        {%- if purpose in ['data_time', 'process_time'] -%}
          {%- if ' as ' in transformation.lower() -%}
            {%- set as_position = transformation.lower().rfind(' as ') -%}
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
      
      {%- do field_collections[purpose].append(field_expr) -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

{%- for field_type in ['data_time', 'process_time'] -%}
  {%- set count = field_collections[field_type] | length -%}
  {%- if count == 0 -%}
    {{- exceptions.raise_compiler_error("No " ~ field_type ~ " field found") -}}
  {%- elif count > 1 -%}
    {{- exceptions.raise_compiler_error("More than one " ~ field_type ~ " field found") -}}
  {%- endif -%}
{%- endfor -%}

{%- set result = {
  'configs': source_configs,
  'fields': {
    'pk': field_collections.pk,
    'data_time': field_collections.data_time[0],
    'process_time': field_collections.process_time[0],
    'other': field_collections.other
  }
} -%}

{{ return(result) }}

{%- endif -%}
{%- endmacro -%}