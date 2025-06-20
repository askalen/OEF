{% macro prehook_setup() %}
{% if execute %}

  {# ========================================
     CONFIG AND DEPENDENCY EXTRACTION
     Extract model configuration and dependencies from graph
     ======================================== #}
  
  {# TODO: Extract model_configs from graph.nodes[model.unique_id].config
     Should include: delta_limit, data_begin, is_slow_changing, is_immutable, field_collections
  #}
  {% set model_configs = {} %}
  
  {# TODO: Build ref_models array from graph.nodes[model.unique_id].depends_on.nodes
     Filter for 'model.' node types and extract names
  #}
  {% set ref_models = [] %}
  
  {# TODO: Build source_models array from graph.nodes[model.unique_id].depends_on.nodes  
     Filter for 'source.' node types
  #}
  {% set source_models = [] %}
  
  {# ========================================
     INITIALIZATION AND VALIDATION
     ======================================== #}
  
  {# Determine table type and validate configuration #}
  {% set is_src_table = this.name.startswith('src_') or source_models|length > 0 %}
  
  {# Get configuration values with defaults #}
  {% set delta_limit = model_configs.delta_limit %}
  {% set data_begin = model_configs.data_begin or '1900-01-01' %}
  {% set is_slow_changing = model_configs.is_slow_changing %}
  {% set is_immutable = model_configs.is_immutable %}
  
  {# Validate dependencies and configuration #}
  {% if not is_src_table and ref_models|length == 0 %}
    {{ exceptions.raise_compiler_error("Non-SRC table " ~ this.name ~ " has no upstream dependencies") }}
  {% endif %}
  
  {% if is_src_table and source_models|length == 0 %}
    {{ exceptions.raise_compiler_error("SRC table " ~ this.name ~ " has no source dependencies") }}
  {% endif %}
  
  {% if is_src_table and not model_configs.field_collections %}
    {{ exceptions.raise_compiler_error("SRC table " ~ this.name ~ " missing required field_collections configuration") }}
  {% endif %}
  
  {# ========================================
     TERMINAL LOGGING - START
     ======================================== #}
  
  {{ log("", info=true) }}
  {{ log("Running model: " ~ this.name, info=true) }}
  
  {# ========================================
     LOCK ACQUISITION
     ======================================== #}
  
  {% set lock_query %}
    MERGE INTO meta.model AS target
    USING (SELECT '{{ this.name }}' AS model_name, '{{ invocation_id }}' AS run_id) AS source
    ON target.model_name = source.model_name
    WHEN MATCHED AND target.locking_run_id IS NULL THEN
      UPDATE SET 
        locking_run_id = source.run_id,
        lock_timestamp = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
      INSERT (model_name, locking_run_id, lock_timestamp)
      VALUES (source.model_name, source.run_id, CURRENT_TIMESTAMP())
  {% endset %}
  
  {% set lock_result = run_query(lock_query) %}
  
  {# ========================================
     SOURCE DATA QUERY (SRC TABLES ONLY)
     ======================================== #}
  
  {% if is_src_table %}
    {% set source_query %}
      SELECT MAX({{ model_configs.field_collections.process_time }}) as max_source_process
      FROM {{ source_models[0] }}
    {% endset %}
    
    {% set source_result = run_query(source_query) %}
    {% set max_source_process = source_result.rows[0][0] if source_result.rows|length > 0 else none %}
  {% endif %}
  
  {# ========================================
     METADATA RETRIEVAL AND CALCULATIONS
     Single query to get all needed information
     ======================================== #}
  
  {% set main_query %}
    SELECT 
      -- Lock verification and current model state
      MAX(IFF(model_name = '{{ this.name }}', locking_run_id = '{{ invocation_id }}', NULL)) as has_lock,
      MAX(IFF(model_name = '{{ this.name }}', last_effective_time IS NULL, NULL)) as is_first_run,
      MAX(IFF(model_name = '{{ this.name }}', last_effective_time, NULL)) as last_effective_time,
      MAX(IFF(model_name = '{{ this.name }}', last_data_time, NULL)) as last_data_time,
      MAX(IFF(model_name = '{{ this.name }}', last_process_time, NULL)) as last_process_time,
      
      {% if is_src_table %}
      -- Source table: calculate deltas using SQL timestamp arithmetic
      CASE 
        WHEN MAX(IFF(model_name = '{{ this.name }}', last_effective_time IS NULL, NULL)) THEN 
          GREATEST('{{ data_begin }}'::timestamp, MAX(IFF(model_name = '{{ this.name }}', COALESCE(last_process_time, '{{ data_begin }}'::timestamp), NULL)))
        ELSE 
          MAX(IFF(model_name = '{{ this.name }}', COALESCE(last_process_time, '{{ data_begin }}'::timestamp), NULL))
      END as calculated_delta_from,
      
      '{{ max_source_process }}'::timestamp as calculated_delta_to
      
      {% else %}
      -- Non-SRC table: get upstream data with arrays for logging
      ARRAY_AGG(IFF(model_name != '{{ this.name }}', model_name, NULL)) WITHIN GROUP (ORDER BY model_name) as upstream_table_names,
      ARRAY_AGG(IFF(model_name != '{{ this.name }}', 
        CASE WHEN is_slow_changing THEN COALESCE(last_data_time, last_effective_time) ELSE last_effective_time END, 
        NULL)) WITHIN GROUP (ORDER BY model_name) as upstream_effective_times,
      
      CASE 
        WHEN MAX(IFF(model_name = '{{ this.name }}', last_effective_time IS NULL, NULL)) THEN 
          GREATEST('{{ data_begin }}'::timestamp, 
            MAX(IFF(model_name != '{{ this.name }}', COALESCE(last_data_time, '{{ data_begin }}'::timestamp), NULL)))
        ELSE 
          MAX(IFF(model_name = '{{ this.name }}', COALESCE(last_effective_time, '{{ data_begin }}'::timestamp), NULL))
      END as calculated_delta_from,
      
      ARRAY_MIN(ARRAY_AGG(IFF(model_name != '{{ this.name }}', 
        CASE WHEN is_slow_changing THEN COALESCE(last_data_time, last_effective_time) ELSE last_effective_time END, 
        NULL))) as calculated_delta_to
      {% endif %}
      
    FROM meta.model 
    WHERE model_name = '{{ this.name }}'
    {% if ref_models|length > 0 %}
      OR model_name IN ({{ "'" ~ ref_models|join("','") ~ "'" }})
    {% endif %}
  {% endset %}
  
  {% set main_result = run_query(main_query) %}
  
  {% if main_result.rows|length == 0 %}
    {{ exceptions.raise_compiler_error("Failed to retrieve model metadata for: " ~ this.name) }}
  {% endif %}
  
  {# Parse results based on table type #}
  {% set result_row = main_result.rows[0] %}
  {% set has_lock = result_row[0] %}
  {% set is_first_run = result_row[1] %}
  {% set last_effective_time = result_row[2] %}
  {% set last_data_time = result_row[3] %}
  {% set last_process_time = result_row[4] %}
  {% set delta_from = result_row[5] %}
  {% set delta_to = result_row[6] %}
  
  {% if not is_src_table %}
    {% set upstream_table_names = result_row[5] %}
    {% set upstream_effective_times = result_row[6] %}
    {% set delta_from = result_row[7] %}
    {% set delta_to = result_row[8] %}
    
    {# Validate all upstream tables were found #}
    {% set non_null_upstreams = upstream_table_names|select("!=", none)|list|length %}
    {% if non_null_upstreams != ref_models|length %}
      {{ exceptions.raise_compiler_error("Expected " ~ ref_models|length ~ " upstream tables for " ~ this.name ~ ", but found " ~ non_null_upstreams ~ ". Missing tables may not exist in meta.model.") }}
    {% endif %}
  {% endif %}
  
  {# ========================================
     LOCK VERIFICATION AND EARLY EXIT
     ======================================== #}
  
  {% if not has_lock %}
    {{ log("  Processing lock active, skipping table", info=true) }}
    {% set should_process = false %}
    {% set final_delta_from = last_effective_time or last_data_time or data_begin %}
    {% set final_delta_to = final_delta_from %}
    {% set final_data_min = final_delta_from %}
    {% set final_backfilling = false %}
  {% else %}
    {{ log("  Processing lock set", info=true) }}
    
    {# ========================================
       TABLE CLEANUP AND ROLLBACK
       ======================================== #}
    
    {% if is_first_run %}
      {% set cleanup_query = "DELETE FROM " ~ this ~ " WHERE 1=1" %}
    {% else %}
      {% set cleanup_query = "DELETE FROM " ~ this ~ " WHERE valid_from > '" ~ delta_from ~ "'" %}
    {% endif %}
    
    {% set cleanup_result = run_query(cleanup_query) %}
    
    {# ========================================
       DELTA LIMITING AND BACKFILL DETECTION
       ======================================== #}
    
    {% set backfilling = false %}
    {% if delta_limit %}
      {% set limited_query %}
        SELECT 
          CASE WHEN '{{ delta_to }}'::timestamp > DATEADD('day', {{ delta_limit }}, '{{ delta_from }}'::timestamp) 
            THEN DATEADD('day', {{ delta_limit }}, '{{ delta_from }}'::timestamp)
            ELSE '{{ delta_to }}'::timestamp 
          END as final_delta_to,
          '{{ delta_to }}'::timestamp > DATEADD('day', {{ delta_limit }}, '{{ delta_from }}'::timestamp) as is_limited
      {% endset %}
      
      {% set limited_result = run_query(limited_query) %}
      {% set delta_to = limited_result.rows[0][0] %}
      {% set backfilling = limited_result.rows[0][1] %}
    {% endif %}
    
    {# ========================================
       DATA_MIN CALCULATION AND PROCESSING CHECK
       ======================================== #}
    
    {% set data_min = (last_data_time or delta_from) if is_src_table else delta_from %}
    
    {# Check if processing is needed #}
    {% if delta_to <= delta_from or (is_src_table and not max_source_process) %}
      {% if is_src_table and not max_source_process %}
        {{ log("  No new data available in source. Skipping.", info=true) }}
      {% else %}
        {{ log("  Delta window is empty. Skipping.", info=true) }}
      {% endif %}
      
      {% set should_process = false %}
      {% set final_delta_from = delta_from %}
      {% set final_delta_to = delta_to %}
      {% set final_data_min = data_min %}
      {% set final_backfilling = false %}
    {% else %}
      {# ========================================
         TERMINAL LOGGING - DETAILED OUTPUT
         ======================================== #}
      
      {{ log("  Upstream tables:", info=true) }}
      {% if is_src_table %}
        {{ log("    " ~ source_models[0] ~ ": " ~ max_source_process, info=true) }}
      {% else %}
        {% for i in range(upstream_table_names|length) %}
          {% if upstream_table_names[i] %}
            {{ log("    " ~ upstream_table_names[i] ~ ": " ~ upstream_effective_times[i], info=true) }}
          {% endif %}
        {% endfor %}
      {% endif %}
      
      {{ log("  Setting run variables:", info=true) }}
      {{ log("    delta_from: " ~ delta_from, info=true) }}
      {{ log("    delta_to: " ~ delta_to, info=true) }}
      {% if backfilling %}
        {{ log("    is_backfilling: true", info=true) }}
      {% endif %}
      {% if is_slow_changing %}
        {{ log("    is_slow: true", info=true) }}
      {% endif %}
      
      {% set should_process = true %}
      {% set final_delta_from = delta_from %}
      {% set final_delta_to = delta_to %}
      {% set final_data_min = data_min %}
      {% set final_backfilling = backfilling %}
    {% endif %}
  {% endif %}
  
  {# ========================================
     SINGLE RETURN STATEMENT
     ======================================== #}
  
  {{ return("SET (oef_should_process, oef_delta_from, oef_delta_to, oef_data_min, oef_backfilling) = (" ~ should_process|upper ~ ", '" ~ final_delta_from ~ "', '" ~ final_delta_to ~ "', '" ~ final_data_min ~ "', " ~ final_backfilling|upper ~ ");") }}

{% endif %}
{% endmacro %}