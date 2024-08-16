-- Step 1: Get historical data for each vessel, now including regions
WITH vessel_history AS (
  SELECT
    vessel_id,
    ARRAY_AGG(DISTINCT destination_region_code) AS visited_region_codes,
    ARRAY_AGG(DISTINCT destination) AS visited_destinations
  FROM
    `train_trades_bq`
  GROUP BY
    vessel_id
),
-- Step 2: Get all possible destinations for each vessel based on visited regions
possible_destinations AS (
  SELECT DISTINCT
    vh.vessel_id,
    t.destination,
    t.destination_country_code,
    t.destination_region_code
  FROM
    vessel_history vh
  CROSS JOIN
    `train_trades_bq` t
  WHERE
    t.destination_region_code IN UNNEST(vh.visited_region_codes)
),
-- Step 3: Prepare the test samples (now including destination_region_code)
test_samples AS (
  SELECT
    vessel_id,
    origin,
    origin_h3_res2_index,
    destination,
    destination_h3_res2_index,
    start_date_time,
    CAST(traded_volume AS FLOAT64) AS traded_volume,
    product_family,
    vessel_type,
    products,
    CAST(dead_weight AS FLOAT64) AS dead_weight,
    flag_name,
    CAST(build_year AS INT64) AS build_year,
    CAST(origin_draught_change AS FLOAT64) AS origin_draught_change,
    CAST(destination_draught_change AS FLOAT64) AS destination_draught_change,
    origin_country_code,
    destination_country_code,
    destination_region_code,
    CAST(origin_cargo_volume AS FLOAT64) AS origin_cargo_volume,
    CAST(destination_cargo_volume AS FLOAT64) AS destination_cargo_volume,
    previous_visited_port_1,
    previous_visited_port_2,
    previous_visited_port_3,
    1 AS is_visit
  FROM
    `test_trades_bq`
),
-- Step 4: Generate negative samples based on regions
negative_samples AS (
  SELECT
    t.* except(is_visit, destination, destination_country_code, destination_region_code),
    cast(pd.destination as string) AS destination,
    pd.destination_country_code,
    pd.destination_region_code,
    0 AS is_visit  -- Flag for negative samples
  FROM
    test_samples t
  JOIN
    possible_destinations pd ON t.vessel_id = pd.vessel_id
  --WHERE
  --  pd.destination != t.destination  -- Exclude the actual destination
),
-- Step 5: Combine positive (test) and negative samples
combined_samples AS (
  SELECT 
    vessel_id,
    origin,
    origin_h3_res2_index,
    destination,
    destination_h3_res2_index,
    start_date_time,
    EXTRACT(DAYOFWEEK FROM timestamp(start_date_time)) AS day_of_week,
    EXTRACT(MONTH FROM timestamp(start_date_time)) AS month,
    traded_volume,
    product_family,
    vessel_type,
    products,
    dead_weight,
    flag_name,
    EXTRACT(YEAR FROM timestamp(start_date_time)) - build_year AS vessel_age,
    origin_draught_change,
    destination_draught_change,
    origin_country_code,
    destination_country_code,
    --destination_region_code,
    origin_cargo_volume,
    destination_cargo_volume,
    previous_visited_port_1,
    previous_visited_port_2,
    previous_visited_port_3,
    is_visit
  FROM test_samples
  
  UNION ALL
  
  SELECT 
    vessel_id,
    origin,
    origin_h3_res2_index,
    destination,
    destination_h3_res2_index,
    start_date_time,
    EXTRACT(DAYOFWEEK FROM timestamp(start_date_time)) AS day_of_week,
    EXTRACT(MONTH FROM timestamp(start_date_time)) AS month,
    traded_volume,
    product_family,
    vessel_type,
    products,
    dead_weight,
    flag_name,
    EXTRACT(YEAR FROM timestamp(start_date_time)) - build_year AS vessel_age,
    origin_draught_change,
    destination_draught_change,
    origin_country_code,
    destination_country_code,
    --destination_region_code,
    origin_cargo_volume,
    destination_cargo_volume,
    previous_visited_port_1,
    previous_visited_port_2,
    previous_visited_port_3,
    is_visit
  FROM negative_samples
)
-- Final step: Select and prepare the final dataset
SELECT
  *
FROM
  combined_samples