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
{%- if model_node.raw_code -%}
  {%- set sql_to_parse = model_node.raw_code -%}
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





{#- ----------------------------------------------------------- -#}
{#- Helper macro to parse attribute fields from SQL -#}
{% macro _parse_attribute_fields(sql_text, pk_fields, time_fields) -%}
{%- set attribute_fields = [] -%}

{# Step 1: Remove comments using string replacement #}
{%- set lines = sql_text.split('\n') -%}
{%- set clean_lines = [] -%}
{%- set in_block_comment = false -%}

{%- for line in lines -%}
  {%- set processed_line = line -%}
  
  {# Handle block comments #}
  {%- if '/*' in processed_line and '*/' in processed_line -%}
    {# Single line block comment - remove it #}
    {%- set before_comment_start = processed_line.find('/*') -%}
    {%- set before_comment = processed_line[0:before_comment_start] -%}
    {%- set after_comment_end = processed_line.find('*/', before_comment_start) -%}
    {%- set after_comment = processed_line[after_comment_end + 2:] -%}
    {%- set processed_line = before_comment + after_comment -%}
  {%- elif '/*' in processed_line and not in_block_comment -%} {# Ensure we only start a new block comment if not already in one #}
    {# Start of multi-line block comment #}
    {%- set processed_line = processed_line.split('/*')[0] -%}
    {%- set in_block_comment = true -%}
  {%- elif '*/' in processed_line and in_block_comment -%}
    {# End of multi-line block comment #}
    {%- set processed_line = processed_line.split('*/')[-1] -%}
    {%- set in_block_comment = false -%}
  {%- elif in_block_comment -%}
    {# Inside block comment - skip entire line #}
    {%- set processed_line = '' -%}
  {%- endif -%}
  
  {# Remove line comments #}
  {%- if '--' in processed_line -%}
    {%- set processed_line = processed_line.split('--')[0] -%}
  {%- endif -%}
  
  {%- do clean_lines.append(processed_line) -%}
{%- endfor -%}

{%- set clean_sql = clean_lines | join('\n') -%}

{# Normalize whitespace - replace multiple spaces with single space, tabs with spaces #}
{%- set sql_normalized = clean_sql.replace('\t', ' ').replace('\r', ' ').replace('\n', ' ') -%}
{%- for i in range(10) -%} {# Max 10 passes to reduce multiple spaces to one #}
  {%- set sql_normalized = sql_normalized.replace('  ', ' ') -%}
{%- endfor -%}
{%- set sql_normalized = sql_normalized.strip() -%}


{# Find last SELECT and last FROM #}
{%- set sql_upper = sql_normalized.upper() -%} {# Use normalized SQL for finding keywords #}

{# Ensure ' SELECT ' and ' FROM ' for accurate word boundary search #}
{%- set last_from_pos = sql_upper.rfind(' FROM ') -%}
{%- set last_select_pos = -1 -%}

{%- if last_from_pos != -1 -%}
  {# Search for SELECT backwards from the FROM position in the upper-cased string #}
  {%- set temp_sql_segment = sql_upper[0:last_from_pos] -%}
  {%- set potential_select_pos = temp_sql_segment.rfind(' SELECT ') -%}

  {%- if potential_select_pos != -1 -%}
    {%- set last_select_pos = potential_select_pos -%}
  {%- else -%}
    {# Check if SELECT is at the very beginning of the cleaned SQL #}
    {%- if sql_upper.startswith('SELECT ') -%}
      {%- set last_select_pos = 0 -%}
    {%- endif -%}
  {%- endif -%}
{%- else -%}
  {# No FROM found (e.g., SELECT 1). Assume the rest is the select clause. #}
  {%- if sql_upper.startswith('SELECT ') -%}
    {%- set last_select_pos = 0 -%}
    {%- set last_from_pos = sql_normalized|length -%} {# Set FROM position to end of string #}
  {%- endif -%}
{%- endif -%}


{%- if last_select_pos >= 0 and last_from_pos > last_select_pos -%}
  {# Extract the SELECT clause from the *normalized* SQL (not upper-cased) #}
  {# Adjust start position based on whether 'SELECT ' or ' SELECT ' was found #}
  {%- set select_start_offset = 7 -%} {# Default for ' SELECT ' #}
  {%- if last_select_pos == 0 -%}
    {%- set select_start_offset = 6 -%} {# For 'SELECT ' at beginning #}
  {%- endif -%}

  {%- set select_clause = sql_normalized[last_select_pos + select_start_offset:last_from_pos].strip() -%}
  
  {# Split by commas. Based on your constraint, commas will only be top-level. #}
  {%- set field_segments = select_clause.split(',') -%}
  
  {%- for segment in field_segments -%}
    {%- set trimmed_segment = segment.strip() -%}
    {%- if trimmed_segment -%}
      {%- set field_name = none -%}
      
      {# Split the trimmed segment by space and take the last word. #}
      {# This covers `col_name`, `col AS alias`, `table.col_name`, and simple `func(col)` if no commas are inside parens #}
      {%- set words = trimmed_segment.split(' ') -%}
      {%- if words|length > 0 -%}
        {%- set field_name_raw = words[-1].strip() -%} {# Get the last word, clean its immediate whitespace #}
        {%- set field_name = field_name_raw.lower() -%} {# Convert to lowercase #}
      {%- endif -%}
      
      {# Add to attribute_fields if not a system field #}
      {%- if field_name and 
             field_name not in pk_fields and 
             field_name not in time_fields and 
             not field_name.startswith('meta_') and
             field_name not in attribute_fields -%}
        {%- do attribute_fields.append(field_name) -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

{{ return(attribute_fields) }}
{%- endmacro -%}