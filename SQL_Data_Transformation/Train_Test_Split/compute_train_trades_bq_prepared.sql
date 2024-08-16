-- Step 1: Prepare the positive samples (actual visits) with previous ports and new features
WITH positive_samples_with_history AS (
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
    CAST(origin_cargo_volume AS FLOAT64) AS origin_cargo_volume,
    CAST(destination_cargo_volume AS FLOAT64) AS destination_cargo_volume,
    previous_visited_port_1,
    previous_visited_port_2,
    previous_visited_port_3,
    1 AS is_visit  -- Flag for positive samples
  FROM
    `train_trades_bq`
  WHERE
    destination IS NOT NULL AND destination != ''
),

-- Step 2: Calculate visited countries and potential destinations for each vessel
vessel_visited_countries AS (
  SELECT
    vessel_id,
    ARRAY_AGG(DISTINCT destination_country_code) AS visited_country_codes,
    ARRAY_AGG(DISTINCT destination) AS visited_destinations,
    ARRAY_AGG(DISTINCT destination_h3_res2_index) AS visited_destinations_h3_res2_index
  FROM
    positive_samples_with_history
  GROUP BY
    vessel_id
),

-- Step 3: Create a mapping of all ports to their countries
port_country_mapping AS (
  SELECT DISTINCT
    destination AS port,
    destination_country_code AS country_code
  FROM
    positive_samples_with_history
),

-- Step 4: Generate five negative samples for each positive sample
negative_samples AS (
  SELECT
    p.* EXCEPT(destination, destination_country_code, is_visit),
    pcm.port AS random_destination,
    pcm.country_code AS random_destination_country_code,
    0 AS is_visit  -- Flag for negative samples
  FROM
    positive_samples_with_history p
  JOIN
    vessel_visited_countries vc ON p.vessel_id = vc.vessel_id
  CROSS JOIN UNNEST(vc.visited_country_codes) AS visited_country
  JOIN
    port_country_mapping pcm ON pcm.country_code = visited_country
  WHERE
    pcm.port != p.destination  -- Ensure the random destination is different from the actual destination
  QUALIFY ROW_NUMBER() OVER (PARTITION BY p.vessel_id, p.start_date_time ORDER BY RAND()) <= 5  -- Generate two negative samples for each positive sample
),

-- Step 5: Combine positive and negative samples
combined_samples AS (
  SELECT 
    *
  FROM positive_samples_with_history
  
  UNION ALL
  
  SELECT 
    vessel_id,
    origin,
    origin_h3_res2_index,
    random_destination AS destination,
    destination_h3_res2_index,
    start_date_time,
    traded_volume,
    product_family,
    vessel_type,
    products,
    dead_weight,
    flag_name,
    build_year,
    origin_draught_change,
    destination_draught_change,
    origin_country_code,
    random_destination_country_code AS destination_country_code,
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
  origin_cargo_volume,
  destination_cargo_volume,
  previous_visited_port_1,
  previous_visited_port_2,
  previous_visited_port_3,
  is_visit
FROM
  combined_samples
