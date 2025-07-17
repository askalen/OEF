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
,
with_previous AS (
    -- New records with meta fields
    SELECT 
        {{ pk_fields | join(',\n        ') }},
        '9999-12-31'::timestamp as valid_to,  -- Place it in correct position
        {{ attribute_fields | join(',\n        ') }},
        object_construct() as meta_audit,
        object_construct() as meta_changes,
        HASH({{ attribute_fields | join(', ') }}) as meta_datahash,
        sysdate() as meta_processed_at,
        'new' as _source_type
    FROM {{ cte }}

    {%- if is_incremental() and not (model_configs.configs._dev | default(false)) -%}
    UNION ALL
    
    -- Previous versions of these records (already have meta fields)
    SELECT 
        *,
        'old' as _source_type
    FROM {{ this }}
    WHERE ({{ pk_fields | join(', ') }}) IN (
        SELECT {{ pk_fields | join(', ') }} 
        FROM {{ cte }}
    )
    {%- endif %}
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
            ELSE curr.meta_changes  -- NULL for new records
        END as meta_changes_new
        
    FROM numbered curr
    LEFT JOIN numbered prev
        ON {% for field in pk_fields -%}
        curr.{{ field }} = prev.{{ field }}
        {%- if not loop.last %} AND {% endif %}
        {%- endfor %}
        AND prev._rn = curr._rn + 1
    WHERE curr._source_type = 'new'  -- Only process new records
        AND (prev._rn IS NULL OR curr.meta_datahash != COALESCE(prev.meta_datahash, 0))  -- Only real changes
),

finalized AS (
    SELECT 
        {{ pk_fields | join(',\n        ') }},
        LEAD(valid_from, 1, '9999-12-31'::timestamp) OVER (
            PARTITION BY {{ pk_fields | join(', ') }} 
            ORDER BY valid_from
        ) as valid_to,
        {%- for field in attribute_fields %}
        {{ field }},
        {%- endfor %}
        -- Meta fields
        meta_audit,
        meta_changes_new as meta_changes,
        meta_datahash,
        meta_processed_at,

    FROM compared
)

SELECT * FROM finalized

{%- endif -%}
{%- endmacro %}