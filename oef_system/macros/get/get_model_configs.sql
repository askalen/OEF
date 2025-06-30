{% macro get_model_configs() -%}
{%- if execute -%}

{%- set model_key = 'model.' ~ model.package_name ~ '.' ~ model.name -%}
{%- set model_node = graph.nodes[model_key] -%}

{%- if not model_node -%}
  {{- exceptions.raise_compiler_error("Model node not found in graph: " ~ model_key) -}}
{%- endif -%}

{%- set model_configs = model_node.config -%}

{#- Get PKs from unique_key config -#}
{%- set pk_fields = [] -%}
{%- set unique_key = model_configs.unique_key -%}
{%- if unique_key -%}
  {%- if unique_key is string -%}
    {#- Single PK field -#}
    {%- do pk_fields.append(unique_key) -%}
  {%- elif unique_key is sequence -%}
    {#- Multiple PK fields -#}
    {%- for pk in unique_key -%}
      {%- do pk_fields.append(pk) -%}
    {%- endfor -%}
  {%- endif -%}
{%- endif -%}

{#- Parse upstreams -#}
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

{#- Determine table type and period -#}
{%- set model_name_parts = model.name.split('_') -%}
{%- set suffix = model_name_parts[-1] if model_name_parts|length > 1 else '' -%}

{%- set type_mapping = {
  'h': 'history',
  'e': 'event', 
  'a': 'aggregate',
  'c': 'current',
  'd': 'definition',
  'p': 'pit',
  'r': 'reference'
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

{#- Define time fields based on table type -#}
{%- set time_fields = [] -%}
{%- if table_type == 'history' -%}
  {%- set time_fields = ['valid_from', 'valid_to'] -%}
{%- elif table_type == 'event' -%}
  {%- set time_fields = ['event_time'] -%}
{%- elif table_type == 'aggregate' -%}
  {%- set time_fields = ['period_begin', 'period_end'] -%}
{%- elif table_type == 'pit' -%}
  {%- set time_fields = ['valid_at'] -%}
{%- elif table_type == 'current' -%}
  {%- set time_fields = ['updated_at'] -%}
{%- endif -%}

{#- Parse attribute fields from the compiled SQL -#}
{%- set attribute_fields = [] -%}
{%- if model_node.compiled_code or model_node.raw_code -%}
  {%- set sql_to_parse = model_node.compiled_code or model_node.raw_code -%}
  {%- set attribute_fields = _parse_attribute_fields(sql_to_parse, pk_fields, time_fields) -%}
{%- endif -%}

{%- set result = {
  'configs': model_configs,
  'upstreams': upstreams,
  'pk_fields': pk_fields,
  'attribute_fields': attribute_fields,
  'type': table_type,
  'period': table_period
} -%}

{{ return(result) }}

{%- endif -%}
{%- endmacro -%}

{#- Helper macro to parse attribute fields from SQL -#}
{% macro _parse_attribute_fields(sql_text, pk_fields, time_fields) -%}
{%- set attribute_fields = [] -%}

{#- Find the last SELECT statement -#}
{%- set sql_upper = sql_text.upper() -%}
{%- set last_select_pos = sql_upper.rfind('SELECT') -%}

{%- if last_select_pos >= 0 -%}
  {#- Find the next FROM after the SELECT -#}
  {%- set from_pos = sql_upper.find('FROM', last_select_pos + 6) -%}
  
  {%- if from_pos > 0 -%}
    {#- Extract the SELECT clause -#}
    {%- set select_clause = sql_text[last_select_pos + 6:from_pos].strip() -%}
    
    {#- Split by commas and get the last word of each segment -#}
    {%- set field_segments = select_clause.split(',') -%}
    
    {%- for segment in field_segments -%}
      {%- set trimmed_segment = segment.strip() -%}
      {%- if trimmed_segment -%}
        {#- Get the last word in the segment -#}
        {%- set words = trimmed_segment.split() -%}
        {%- if words|length > 0 -%}
          {%- set field_name = words[-1].rstrip('.,;:)]}').lower() -%}
          
          {#- Add to attribute_fields if not a system field -#}
          {%- if field_name and 
                 field_name not in pk_fields and 
                 field_name not in time_fields and 
                 not field_name.startswith('meta_') -%}
            {%- do attribute_fields.append(field_name) -%}
          {%- endif -%}
        {%- endif -%}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
{%- endif -%}

{{ return(attribute_fields) }}
{%- endmacro -%}