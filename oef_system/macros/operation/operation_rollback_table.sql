{% macro operation_rollback_table(table_name, rollback_date, cascade_downstream=false, create_backup=true, force=false) %}
{%- if execute -%}

  {{ log("Starting rollback for table: " ~ table_name, info=true) }}
  
  {# Get table metadata and configuration #}
  {%- set model_configs = get_model_configs() -%}
  {%- set table_type = model_configs.type -%}
  {%- set is_src_table = model_configs.dependencies.is_src_table -%}
  
  {# Convert rollback_date to timestamp #}
  {%- set rollback_timestamp = "'" ~ rollback_date ~ "'::timestamp" -%}
  
  {# Get model metadata for lock/immutable checks #}
  {%- set model_meta = get_model_meta() -%}
  {%- set current_lock = model_meta.current_state.lock_id -%}
  {%- set is_locked = current_lock is not none and current_lock != invocation_id -%}
  {%- set is_immutable = model_meta.model_configs.is_immutable -%}
  
  {# Check for blocking conditions #}
  {%- if is_locked -%}
    {{ log("Table " ~ table_name ~ " is locked by another process. Skipping.", info=true) }}
    {{ return(false) }}
  {%- endif -%}
  
  {%- if is_immutable and not force -%}
    {{ log("Table " ~ table_name ~ " is immutable. Use force=true to override.", info=true) }}
    {{ return(false) }}
  {%- endif -%}
  
  {# Create backup if requested #}
  {%- if create_backup -%}
    {# TODO: Call backup macro when implemented #}
    {# {% set backup_result = operation_backup_table(table_name) %} #}
    {{ log("Backup creation requested but not yet implemented.", info=true) }}
  {%- endif -%}
  
  {# Set lock on the table #}
  {{ set_model_meta_lock() }}
  
  {# Perform rollback based on table type #}
  {%- if table_type in ['history', 'event'] -%}
    
    {%- if is_src_table -%}
      {# Handle SRC tables with source_processed_at logic #}
      {%- set new_source_processed_to = _rollback_src_table(table_name, table_type, rollback_timestamp) -%}
    {%- else -%}
      {# Handle regular tables #}
      {{ _rollback_regular_table(table_name, table_type, rollback_timestamp) }}
    {%- endif -%}
    
  {%- else -%}
    {{ log("Unsupported table type '" ~ table_type ~ "' for table " ~ table_name ~ ". Skipping rollback.", info=true) }}
    {{ _unlock_table(table_name) }}
    {{ return(false) }}
  {%- endif -%}
  
  {# Update meta.model table #}
  {{ _update_rollback_meta(table_name, rollback_timestamp, is_src_table, new_source_processed_to) }}
  
  {{ log("Completed rollback on table: " ~ table_name, info=true) }}
  
  {# Handle downstream cascade if requested #}
  {%- if cascade_downstream -%}
    {{ _cascade_rollback_downstream(table_name, rollback_date, create_backup, force) }}
  {%- endif -%}
  
  {{ return(true) }}

{%- endif -%}
{% endmacro %}

{# Helper macro for SRC table rollback logic #}
{% macro _rollback_src_table(table_name, table_type, rollback_timestamp) %}
{%- if execute -%}
  
  {# Determine time field based on table type #}
  {%- set time_field = 'valid_from' if table_type == 'history' else 'event_time' -%}
  
  {# Find minimum source_processed_at for data integrity #}
  {%- set source_check_query %}
    SELECT MIN(meta_audit.source_processed_at) as min_source_processed
    FROM {{ table_name }}
    WHERE {{ time_field }} > {{ rollback_timestamp }}
  {% endset %}
  
  {%- call statement('get_min_source_processed', fetch_result=true) -%}
    {{ source_check_query }}
  {%- endcall -%}
  
  {%- set source_rows = load_result('get_min_source_processed').rows -%}
  {%- if source_rows|length > 0 and source_rows[0][0] is not none -%}
    {%- set min_source_processed = source_rows[0][0] -%}
    
    {# Delete based on source_processed_at #}
    {%- set delete_query %}
      DELETE FROM {{ table_name }}
      WHERE meta_audit.source_processed_at >= '{{ min_source_processed }}'
    {% endset %}
    
    {%- call statement('delete_src_rows') -%}
      {{ delete_query }}
    {%- endcall -%}
    
    {# Update valid_to for history tables #}
    {%- if table_type == 'history' -%}
      {{ _update_history_valid_to(table_name, rollback_timestamp) }}
    {%- endif -%}
    
    {%- set new_source_processed_to = "DATEADD('second', -1, '" ~ min_source_processed ~ "'::timestamp)" -%}
    {{ return(new_source_processed_to) }}
  {%- else -%}
    {{ log("No rows found with " ~ time_field ~ " > " ~ rollback_timestamp ~ " for " ~ table_name, info=true) }}
    {{ return(none) }}
  {%- endif -%}

{%- endif -%}
{% endmacro %}

{# Helper macro for regular table rollback logic #}
{% macro _rollback_regular_table(table_name, table_type, rollback_timestamp) %}
{%- if execute -%}
  
  {# Determine time field and delete condition based on table type #}
  {%- set time_field = 'valid_from' if table_type == 'history' else 'event_time' -%}
  
  {# Delete rows #}
  {%- set delete_query %}
    DELETE FROM {{ table_name }}
    WHERE {{ time_field }} > {{ rollback_timestamp }}
  {% endset %}
  
  {%- call statement('delete_regular_rows') -%}
    {{ delete_query }}
  {%- endcall -%}
  
  {# Update valid_to for history tables #}
  {%- if table_type == 'history' -%}
    {{ _update_history_valid_to(table_name, rollback_timestamp) }}
  {%- endif -%}

{%- endif -%}
{% endmacro %}

{# Helper macro for updating valid_to in history tables #}
{% macro _update_history_valid_to(table_name, rollback_timestamp) %}
{%- if execute -%}
  {%- set update_query %}
    UPDATE {{ table_name }}
    SET valid_to = '9999-12-31'::timestamp
    WHERE valid_to > {{ rollback_timestamp }}
  {% endset %}
  
  {%- call statement('update_valid_to') -%}
    {{ update_query }}
  {%- endcall -%}
{%- endif -%}
{% endmacro %}

{# Helper macro for unlocking table on error #}
{% macro _unlock_table(table_name) %}
{%- if execute -%}
  {%- set unlock_query %}
    UPDATE meta.model 
    SET locked_run_id = NULL, locked_at = NULL
    WHERE model_name = '{{ table_name }}'
  {% endset %}
  {%- call statement('unlock_table_error') -%}
    {{ unlock_query }}
  {%- endcall -%}
{%- endif -%}
{% endmacro %}

{# Helper macro for updating meta table after rollback #}
{% macro _update_rollback_meta(table_name, rollback_timestamp, is_src_table, new_source_processed_to) %}
{%- if execute -%}
  {%- set meta_update_query %}
    UPDATE meta.model
    SET 
      data_to = {{ rollback_timestamp }},
      effective_to = {{ rollback_timestamp }},
      processed_at = CURRENT_TIMESTAMP(),
      {%- if is_src_table and new_source_processed_to is not none %}
      source_processed_to = {{ new_source_processed_to }},
      {%- endif %}
      locked_run_id = NULL,
      locked_at = NULL
    WHERE model_name = '{{ table_name }}'
  {% endset %}
  
  {%- call statement('update_meta_model') -%}
    {{ meta_update_query }}
  {%- endcall -%}
{%- endif -%}
{% endmacro %}

{# Helper macro for cascading to downstream tables #}
{% macro _cascade_rollback_downstream(table_name, rollback_date, create_backup, force) %}
{%- if execute -%}
  {{ log("Cascading rollback to downstream tables...", info=true) }}
  
  {# Find downstream dependencies #}
  {%- set downstream_tables = [] -%}
  {%- for node_id, node in graph.nodes.items() -%}
    {%- if node.resource_type == 'model' -%}
      {%- for dependency in node.depends_on.nodes -%}
        {%- if dependency.endswith('.' ~ table_name) -%}
          {%- do downstream_tables.append(node.name) -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endfor -%}
  
  {# Recursively call rollback on downstream tables #}
  {%- for downstream_table in downstream_tables -%}
    {%- set downstream_result = operation_rollback_table(downstream_table, rollback_date, true, create_backup, force) -%}
  {%- endfor -%}
{%- endif -%}
{% endmacro %}