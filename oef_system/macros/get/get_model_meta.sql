{% macro get_model_meta() -%}
{%- if execute -%}

{#- Extract model configuration and dependencies from graph -#}
{%- set model_key = 'model.' ~ model.package_name ~ '.' ~ model.name -%}
{%- set model_node = graph.nodes[model_key] -%}

{%- if not model_node -%}
  {{ operation_clear_lock(force=true) }}
  {{- exceptions.raise_compiler_error("Model node not found in graph: " ~ model_key) -}}
{%- endif -%}

{%- set model_configs = model_node.config -%}

{#- Build dependency arrays from graph -#}
{%- set ref_models = [] -%}
{%- set source_models = [] -%}

{%- for dependency in model_node.depends_on.nodes -%}
  {%- if dependency.startswith('model.') -%}
    {%- set model_name = dependency.split('.')[-1] -%}
    {%- do ref_models.append(model_name) -%}
  {%- elif dependency.startswith('source.') -%}
    {%- set source_parts = dependency.split('.') -%}
    {%- set source_name = source_parts[-2] ~ '.' ~ source_parts[-1] -%}
    {%- do source_models.append(source_name) -%}
  {%- endif -%}
{%- endfor -%}

{#- Determine table type for later use -#}
{%- set is_src_table = this.name.startswith('src_') or source_models|length > 0 -%}

{#- Build single query to get all metadata -#}
{%- set meta_query %}
SELECT 
  -- Current model metadata
  MAX(IFF(model_name = '{{ this.name }}', locked_run_id, NULL)) as current_lock_id,
  MAX(IFF(model_name = '{{ this.name }}', locked_at, NULL)) as current_locked_at,
  MAX(IFF(model_name = '{{ this.name }}', data_from IS NULL, NULL)) as is_first_run,
  MAX(IFF(model_name = '{{ this.name }}', effective_to, NULL)) as last_effective_time,
  MAX(IFF(model_name = '{{ this.name }}', data_to, NULL)) as last_data_time,
  MAX(IFF(model_name = '{{ this.name }}', source_processed_to, NULL)) as last_process_time,
  
  {%- if not is_src_table and ref_models|length > 0 %}
  -- Upstream model metadata (for non-SRC tables with dependencies)
  ARRAY_AGG(IFF(model_name != '{{ this.name }}', model_name, NULL)) WITHIN GROUP (ORDER BY model_name) as upstream_table_names,
  ARRAY_AGG(IFF(model_name != '{{ this.name }}', effective_to, NULL)) WITHIN GROUP (ORDER BY model_name) as upstream_effective_times,
  ARRAY_AGG(IFF(model_name != '{{ this.name }}', data_to, NULL)) WITHIN GROUP (ORDER BY model_name) as upstream_data_times,
  ARRAY_AGG(IFF(model_name != '{{ this.name }}', is_slow, NULL)) WITHIN GROUP (ORDER BY model_name) as upstream_is_slow_changing
  {%- else %}
  -- No upstream dependencies to track
  ARRAY_CONSTRUCT() as upstream_table_names,
  ARRAY_CONSTRUCT() as upstream_effective_times, 
  ARRAY_CONSTRUCT() as upstream_data_times,
  ARRAY_CONSTRUCT() as upstream_is_slow_changing
  {%- endif %}

FROM meta.model 
WHERE model_name = '{{ this.name }}'
{%- if ref_models|length > 0 %}
  OR model_name IN ({{ "'" ~ ref_models|join("','") ~ "'" }})
{%- endif %}
{%- endset -%}

{#- Execute query using run_query -#}
{%- set results = run_query(meta_query) -%}

{%- if not results -%}
  {{ operation_clear_lock(force=true) }}
  {{- exceptions.raise_compiler_error("Failed to retrieve model metadata for: " ~ this.name) -}}
{%- endif -%}

{%- set result_rows = results.rows -%}

{%- if result_rows|length == 0 -%}
  {# First run scenario - dont clear lock, this is expected #}
  {%- set result = {
    'model_configs': model_configs,
    'dependencies': {
      'ref_models': ref_models,
      'source_models': source_models,
      'is_src_table': is_src_table
    },
    'current_state': {
      'lock_id': none,
      'locked_at': none,
      'is_first_run': true, 
      'last_effective_time': none,
      'last_data_time': none,
      'last_process_time': none
    },
    'upstream_states': {
      'table_names': [],
      'effective_times': [],
      'data_times': [],
      'is_slow_changing': []
    }
  } -%}
  {{ return(result) }}
{%- endif -%}

{%- set row = result_rows[0] -%}

{#- Build return object -#}
{%- set result = {
  'model_configs': model_configs,
  'dependencies': {
    'ref_models': ref_models,
    'source_models': source_models,
    'is_src_table': is_src_table
  },
  'current_state': {
    'lock_id': row[0],
    'locked_at': row[1],
    'is_first_run': row[2], 
    'last_effective_time': row[3],
    'last_data_time': row[4],
    'last_process_time': row[5]
  },
  'upstream_states': {
    'table_names': row[6],
    'effective_times': row[7],
    'data_times': row[8],
    'is_slow_changing': row[9]
  }
} -%}

{{ return(result) }}

{%- endif -%}
{%- endmacro -%}