{% macro generate_h_logic(cte='ready') -%}
{%- if execute -%}

{#- Get model configuration including field lists -#}
{%- set model_configs = get_model_configs() -%}
{%- set pk_fields = model_configs.pk_fields -%}
{%- set attribute_fields = model_configs.attribute_fields -%}

{#- Validate we have required fields -#}
{%- if not pk_fields or pk_fields|length == 0 -%}
  {{- exceptions.raise_compiler_error("H tables require at least one primary key field defined in unique_key config") -}}
{%- endif -%}

{#- Build the H table processing SQL -#}
, with_previous AS (
    -- New/updated records from the CTE
    SELECT 
        *,
        'new' as _source_type
    FROM {{ cte }}
    
    UNION ALL
    
    -- Previous versions of these records
    SELECT 
        *,
        'old' as _source_type
    FROM {{ this }}
    WHERE ({{ pk_fields | join(', ') }}) IN (
        SELECT {{ pk_fields | join(', ') }} 
        FROM {{ cte }}
    )
),

numbered AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY {{ pk_fields | join(', ') }} 
            ORDER BY valid_from DESC
        ) as _rn
    FROM with_previous
),

compared AS (
    SELECT 
        curr.*,
        -- Calculate hash of attribute fields for change detection
        {%- if attribute_fields|length > 0 %}
        HASH({{ attribute_fields | join(', ') }}) as meta_datahash,
        {%- else %}
        HASH(*) as meta_datahash,
        {%- endif %}
        
        -- Detect if this is a real change
        CASE 
            WHEN prev._rn IS NULL THEN TRUE  -- New record
            {%- if attribute_fields|length > 0 %}
            WHEN HASH({{ attribute_fields | map('format_string', 'curr.{}') | join(', ') }}) != 
                 COALESCE(HASH({{ attribute_fields | map('format_string', 'prev.{}') | join(', ') }}), 0) THEN TRUE
            {%- else %}
            WHEN curr.meta_datahash != COALESCE(prev.meta_datahash, 0) THEN TRUE
            {%- endif %}
            ELSE FALSE
        END as _is_change,
        
        -- Build meta_changes using conditional keys
        CASE 
            WHEN prev._rn IS NOT NULL THEN
                OBJECT_CONSTRUCT_KEEP_NULL(
                    {%- for field in attribute_fields %}
                    IFF(
                        curr.{{ field }} IS DISTINCT FROM prev.{{ field }},
                        '{{ field }}',
                        NULL
                    ), prev.{{ field }}
                    {%- if not loop.last %},{% endif %}
                    {%- endfor %}
                )
            ELSE NULL
        END as meta_changes
        
    FROM numbered curr
    LEFT JOIN numbered prev
        ON {{ pk_fields | map('format_string', 'curr.{} = prev.{}') | join(' AND ') }}
        AND prev._rn = curr._rn + 1
    WHERE curr._source_type = 'new'  -- Only process new records, not historical
),

finalized AS (
    SELECT 
        -- All original fields except internal ones
        {{ pk_fields | join(',\n        ') }},
        valid_from,
        {%- for field in attribute_fields %}
        {{ field }},
        {%- endfor %}
        -- Meta fields
        meta_datahash,
        meta_changes,
        CURRENT_TIMESTAMP() as meta_processed_at,
        -- Calculate valid_to
        LEAD(valid_from, 1, '9999-12-31'::timestamp) OVER (
            PARTITION BY {{ pk_fields | join(', ') }} 
            ORDER BY valid_from
        ) as valid_to
    FROM compared
    WHERE _is_change = TRUE  -- Only keep records with actual changes
)

SELECT * FROM finalized

{%- endif -%}
{%- endmacro %}