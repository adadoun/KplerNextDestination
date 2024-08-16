WITH port_calls AS (
  SELECT 
    *,
    ST_GEOGPOINT(CAST(destination_longitude AS FLOAT64), CAST(destination_latitude AS FLOAT64)) AS destination_point
  FROM `port_calls_bq`
  WHERE destination_longitude IS NOT NULL AND destination_latitude IS NOT NULL
),

country_boundaries AS (
  SELECT
    *,
    ST_GEOGFROMGEOJSON(REPLACE(`Geo Shape`, '""', '"')) AS country_shape,
    ST_ASTEXT(ST_GEOGFROMGEOJSON(`Geo Shape`)) as country_geography,
  FROM `country_boundaries_bq`
  WHERE `Geo Shape` IS NOT NULL
),

exact_matches AS (
  SELECT
    pc.* except(destination_point),
    ST_ASTEXT(destination_point) as destination_geo_point,
    cb.`English Name` AS country_name,
    cb.`ISO 3 country code` as country_code,
    cb.`Continent of the territory` as continent_code,
    cb.`Region of the territory` as region_code,
    cb.country_geography,
    'Exact match' AS match_type,
    0 AS distance_to_matched_country
  FROM port_calls pc
  JOIN country_boundaries cb
  ON ST_CONTAINS(cb.country_shape, pc.destination_point)
),

unmatched_calls AS (
  SELECT pc.*
  FROM port_calls pc
  LEFT JOIN exact_matches em ON pc.id = em.id
  WHERE em.id IS NULL
),

closest_matches AS (
  SELECT
    uc.* except(destination_point),
    ST_ASTEXT(destination_point) as destination_geo_point,
    cb.`English Name` AS country_name,
    cb.`ISO 3 country code` as country_code,
    cb.`Continent of the territory` as continent_code,
    cb.`Region of the territory` as region_code,
    cb.country_geography,
    'Closest match' AS match_type,
    ST_DISTANCE(uc.destination_point, cb.country_shape) AS distance_to_matched_country
  FROM unmatched_calls uc
  CROSS JOIN country_boundaries cb
  WHERE ST_DWITHIN(uc.destination_point, cb.country_shape, 1000000)  -- 1000 km radius
  QUALIFY ROW_NUMBER() OVER (PARTITION BY uc.id ORDER BY ST_DISTANCE(uc.destination_point, cb.country_shape)) = 1
)

SELECT * FROM exact_matches
UNION ALL
SELECT * FROM closest_matches
ORDER BY id;