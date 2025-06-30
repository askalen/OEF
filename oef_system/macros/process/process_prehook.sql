{% macro process_prehook() %}
{%- if execute -%}

  {# ========================================
     STEP 1: LOG MODEL START
     ======================================== #}
  {{ log("", info=true) }}
  {{ log("********************************************", info=true) }}
  {{ log("Running model: " ~ model.name, info=true) }}
  {{ log("********************************************", info=true) }}

  {# ========================================
     STEP 1b: TESTING AREA
     ======================================== #}


  {# ========================================
     STEP 2: GET MODEL CONFIGURATION
     ======================================== #}
  {%- set model_configs = get_model_configs() -%}
  {%- set is_src_table = model.name.startswith('src_') or model_configs.upstreams.sources|length > 0 -%}
  {%- set table_type = model_configs.type -%}

  {{ log(model_configs.attribute_fields, info=true) }}


  {# ========================================
     STEP 3: SET LOCK
     ======================================== #}
  {{ set_model_meta_lock() }}
  
  {# ========================================
     STEP 4: GET MODEL METADATA
     ======================================== #}
  {%- set model_meta = get_model_meta() -%}

{# ========================================
     STEP 5: CHECK PROCESSING CONDITIONS
     ======================================== #}
  {# Check if lock was acquired #}
  {%- set has_lock = model_meta.current_state.lock_id == invocation_id -%}
  {%- set timeout_minutes = var('lock_timeout_minutes', 30) -%}
  {{ log("► Checking for data lock...", info=true) }}
  {%- if not has_lock -%}
    
    
    {%- if model_meta.current_state.lock_id is not none -%}
      {# Another lock exists - check if its stale using the timestamp we already have #}
      {%- if model_meta.current_state.locked_at -%}
        {%- set stale_check_query %}
          SELECT '{{ model_meta.current_state.locked_at }}'::timestamp < DATEADD('minute', -{{ timeout_minutes }}, CURRENT_TIMESTAMP()) as is_stale
        {%- endset %}
        
        {%- set stale_result = run_query(stale_check_query) -%}
        {%- set lock_is_stale = stale_result.rows[0][0] if stale_result and stale_result.rows|length > 0 else false -%}
        
        {%- if lock_is_stale -%}
          {{ log("    Found stale lock from " ~ model_meta.current_state.locked_at ~ ", clearing and retrying...", info=true) }}
          {{ operation_clear_lock(force=true) }}
          {{ set_model_meta_lock() }}
          {# Re-get metadata after clearing stale lock #}
          {%- set model_meta = get_model_meta() -%}
          {%- set has_lock = model_meta.current_state.lock_id == invocation_id -%}
          
          {%- if not has_lock -%}
            {{ log("    Another process acquired lock after stale clear", info=true) }}
          {%- endif -%}
        {%- else -%}
          {{ log("    Active lock found from " ~ model_meta.current_state.locked_at, info=true) }}
        {%- endif -%}
      {%- else -%}
        {{ log("    Lock exists but no timestamp found - treating as active", info=true) }}
      {%- endif -%}
    {%- else -%}
      {# No lock exists but we couldn't acquire it - shouldn't happen #}
      {{ log("    WARNING: Failed to acquire lock but no existing lock found", info=true) }}
    {%- endif -%}
  {%- endif -%}

  {%- if not has_lock -%}
    {{ log("    Processing lock active, skipping table", info=true) }}
    {{ return("SET oef_should_process = FALSE;") }}
  {%- else -%}
    {{ log("  ✓ Lock acquired successfully", info=true) }}
  {%- endif -%}
  
  {# ========================================
     STEP 6: CALCULATE DELTAS
     ======================================== #}
  {# Determine delta_from #}
  {%- if model_meta.current_state.is_first_run -%}
    {%- set data_begin = model_configs.configs._initial_date or '1900-01-01' -%}
    {%- set delta_from = data_begin -%}
  {%- else -%}
    {%- if is_src_table -%}
      {%- if model_meta.current_state.last_process_time -%}
        {%- set delta_from = model_meta.current_state.last_process_time -%}
      {%- elif model_meta.current_state.last_data_time -%}
        {%- set delta_from = model_meta.current_state.last_data_time -%}
      {%- else -%}
        {%- set delta_from = '1900-01-01' -%}
      {%- endif -%}
    {%- else -%}
      {%- if model_meta.current_state.last_data_time -%}
        {%- set delta_from = model_meta.current_state.last_data_time -%}
      {%- elif model_meta.current_state.last_effective_time -%}
        {%- set delta_from = model_meta.current_state.last_effective_time -%}
      {%- else -%}
        {%- set delta_from = '1900-01-01' -%}
      {%- endif -%}
    {%- endif -%}
  {%- endif -%}
  
  {# Determine delta_to #}
  {%- if is_src_table -%}
    {# SRC tables: use delta_limit or max future date #}
    {%- set delta_limit = model_configs.configs._delta_limit -%}
    {%- if delta_limit -%}
      {# Evaluate the DATEADD expression #}
      {%- set delta_to_query = "SELECT DATEADD('day', " ~ delta_limit ~ ", '" ~ delta_from ~ "'::timestamp)::varchar" -%}
      {%- set delta_to_result = run_query(delta_to_query) -%}
      {%- set delta_to = delta_to_result.rows[0][0] -%}
    {%- else -%}
      {%- set delta_to = '9999-12-31' -%}
    {%- endif -%}
    {%- set is_backfilling = false -%}
  {%- else -%}
    {# Non-SRC tables: use minimum upstream effective_to #}
    {%- set upstream_names = model_meta.upstream_states.table_names -%}
    {%- set upstream_times = model_meta.upstream_states.effective_times -%}
    {%- if upstream_times and upstream_times | length > 0 -%}
      {# Log upstream tables for visibility #}
      {{ log("  Upstream tables:", info=true) }}
      {%- for i in range(upstream_names|length) -%}
        {%- if upstream_names[i] -%}
          {{ log("    " ~ upstream_names[i] ~ ": " ~ upstream_times[i], info=true) }}
        {%- endif -%}
      {%- endfor -%}
      
      {# Find minimum non-null upstream time #}
      {%- set min_upstream_time = none -%}
      {%- for time in upstream_times -%}
        {%- if time and (not min_upstream_time or time < min_upstream_time) -%}
          {%- set min_upstream_time = time -%}
        {%- endif -%}
      {%- endfor -%}
      
      {%- if not min_upstream_time -%}
        {{ log("  No upstream tables have progressed. Skipping.", info=true) }}
        {{ return("SET oef_should_process = FALSE;") }}
      {%- endif -%}
      
      {# Apply delta_limit if configured #}
      {%- set delta_limit = model_configs.configs._delta_limit -%}
      {%- if delta_limit -%}
        {# Evaluate the DATEADD expression #}
        {%- set limited_delta_to_query = "SELECT DATEADD('day', " ~ delta_limit ~ ", '" ~ delta_from ~ "'::timestamp)::varchar" -%}
        {%- set limited_delta_to_result = run_query(limited_delta_to_query) -%}
        {%- set limited_delta_to = limited_delta_to_result.rows[0][0] -%}
        
        {%- set compare_query = "SELECT '" ~ limited_delta_to ~ "'::timestamp < '" ~ min_upstream_time ~ "'::timestamp" -%}
        {%- set compare_result = run_query(compare_query) -%}
        {%- if compare_result.rows[0][0] -%}
          {%- set delta_to = limited_delta_to -%}
          {%- set is_backfilling = true -%}
        {%- else -%}
          {%- set delta_to = min_upstream_time -%}
          {%- set is_backfilling = false -%}
        {%- endif -%}
      {%- else -%}
        {%- set delta_to = min_upstream_time -%}
        {%- set is_backfilling = false -%}
      {%- endif -%}
    {%- else -%}
      {{ log("  No upstream dependencies found. Skipping.", info=true) }}
      {{ return("SET oef_should_process = FALSE;") }}
    {%- endif -%}
  {%- endif -%}
  
  {# Check if delta window is valid #}
  {%- set window_check_query = "SELECT '" ~ delta_to ~ "'::timestamp <= '" ~ delta_from ~ "'::timestamp" -%}
  {%- set window_check_result = run_query(window_check_query) -%}
  {%- if window_check_result.rows[0][0] -%}
    {{ log("  Delta window is empty. Nothing to process.", info=true) }}
    {{ return("SET oef_should_process = FALSE;") }}
  {%- endif -%}
  
  {# Calculate data_min #}
  {%- if is_src_table -%}
    {%- set data_min = model_meta.current_state.last_data_time or delta_from -%}
  {%- else -%}
    {%- set data_min = delta_from -%}
  {%- endif -%}
  
  {# ========================================
     STEP 7: LOGGING
     ======================================== #}
{{ log("► Setting Snowflake variables", info=true) }}
{{ log("    delta_from:  " ~ (delta_from ~ ' 00:00:00.000' if delta_from|length == 10 else delta_from), info=true) }}
{{ log("    delta_to:    " ~ (delta_to ~ ' 00:00:00.000' if delta_to|length == 10 else delta_to), info=true) }}
{{ log("    data_min:    " ~ (data_min ~ ' 00:00:00.000' if data_min|length == 10 else data_min), info=true) }}
  {%- if is_backfilling -%}
  {{ log("    backfilling: true", info=true) }}
  {%- endif -%}
  
  {# ========================================
     STEP 8: HANDLE ROLLBACK
     ======================================== #}
  {%- set rollback_days = model_configs.configs._rollback_days -%}
  
  {%- if rollback_days is not none and not model_meta.current_state.is_first_run -%}
    {%- if rollback_days == 0 -%}
      {{ log("  Rolling back to effective_to: " ~ model_meta.current_state.last_effective_time, info=true) }}
      {% set rollback_result = operation_rollback_table(model.name, model_meta.current_state.last_effective_time, false, false, true) %}
    {%- else -%}
      {# Evaluate the rollback date #}
      {%- set rollback_date_query = "SELECT DATEADD('day', -" ~ rollback_days ~ ", '" ~ delta_from ~ "'::timestamp)::varchar" -%}
      {%- set rollback_date_result = run_query(rollback_date_query) -%}
      {%- set rollback_date = rollback_date_result.rows[0][0] -%}
      {{ log("  Rolling back " ~ rollback_days ~ " days from delta_from", info=true) }}
      {% set rollback_result = operation_rollback_table(model.name, rollback_date, false, false, true) %}
    {%- endif -%}
  {%- endif -%}
  
  {# ========================================
     STEP 9: RETURN SET STATEMENT
     ======================================== #}
  {{ return("SET 
  (oef_should_process, oef_delta_from, oef_delta_to, oef_delta_min, oef_backfilling) =
  (TRUE, '" ~ delta_from ~ "', '" ~ delta_to ~ "', '" ~ data_min ~ "', " ~ is_backfilling ~ ");") }}

{%- endif -%}
{% endmacro %}