{{ config(
  unique_key = ['case_id','valid_from'],
  _dev = true
) }}

WITH cleanup as (
  SELECT
    -- PKs
    case_id,
    valid_from,

    -- FKs
    ifnull(
      nullif(right(
        regexp_replace(split_part(inspector, '|', 2),'[^0-9]', ''),
      10),''),'0'
    ) as inspector_id,
    parcelid as parcel_id,
    servicerequestnumber as request_id,

    -- Attributes
    description,
    object_construct(
      'repeat_offender', iff(upper(repeatoffenderrelated) = 'YES', true, false),
      'short_term_rental', iff(upper(shorttermrentalrelated) = 'YES', true, false)
    ) as has_flag,
    ifnull(trim(split_part(inspector, '|', 1)), '') as inspector_name,

    object_construct(
      'address', address_long,
      'city', city,
      'latitude', try_cast(latitude as number(10,8)),
      'longitude', try_cast(longitude as number(10,8)),
      'state', state,
      'zip', zip_code
    ) as parcel_location,
    try_to_number(priority) as priority,
    reportedby as reported_by,
    status,
    last_update as status_detail
  FROM  {{ ref('extsrc_tcc_case_j') }} 
  WHERE
    valid_from > $oef_delta_from and valid_from <= $oef_delta_to and
    case_id is not null and
    valid_from is not null
),
ready as (
  SELECT
    case_id,
    valid_from,

    inspector_id,
    parcel_id,
    request_id,

    has_flag,
    inspector_name,
    parcel_location,
    priority,
    reported_by,
    status,
    status_detail
  FROM cleanup
)
{{ generate_h_logic() }}


    /*
      Unused fields
        house_number/street_name: superfluous with parcel_address, no need to separate them
        department: always the same, if it were different the table would have a different purpose
        case_type: always the same, if it were different the table would have a different purpose
        violationcasenumber: not something we use or care about
        location: redundant with lat/lon

      Assumptions
        Convert all timestamps to UTC
        Keep times in timestamp format in case want to blend later with similar data
        Keep state in case want to blend later with similar data
        Probably don't need historical data older than 2020
    */