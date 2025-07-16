WITH setup AS (
  SELECT
    *,
    try_to_timestamp(date_updated, 'MM/DD/YYYY HH12:MI:SS AM') as valid_from,
    ifnull(lead(
      valid_from) over (
        partition by case_id order by valid_from
      ), '9999-12-31') as valid_to
  FROM {{ source('extraw','tcc_case_j' )}}
  WHERE case_id is not null and valid_from is not null
)
SELECT * exclude date_updated
FROM setup