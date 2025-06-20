{{ config(
  _initial_date = '2020-01-01',
  _delta_limit = 20,
  tags = []
) }}
{{ generate_src_table(source('core','user_j'), 'History') }}