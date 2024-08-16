WITH train_data AS (
  SELECT
    *,
    DATE_TRUNC(timestamp(start_date_time), WEEK) AS agg_stop_ts
  FROM
    `train_trades_bq_prepared`
)
SELECT
  t.*,
  coalesce(od_distance.od_distance, h3_od_distance.h3_od_distance) as od_distance,
  coalesce(p1.probability, 0) as p1_destination_probability,
  coalesce(p2.probability, 0) as p2_destination_probability,
  coalesce(p3.probability, 0) as p3_destination_probability,
  coalesce(p4.probability, 0) as p4_destination_probability,
  COALESCE(p4.probability, p3.probability, p2.probability, p1.probability, 0) AS merged_destination_probability,
  CASE
    WHEN p4.probability IS NOT NULL THEN 'P4'
    WHEN p3.probability IS NOT NULL THEN 'P3'
    WHEN p2.probability IS NOT NULL THEN 'P2'
    WHEN p1.probability IS NOT NULL THEN 'P1'
    ELSE NULL
  END AS probability_level
FROM
  train_data t
LEFT JOIN
  `p4_association_rules` p4
  ON t.agg_stop_ts = p4.agg_stop_ts
  AND t.vessel_id = p4.vessel_id
  AND t.product_family = p4.product_family
  AND t.previous_visited_port_1 = p4.previous_visited_port_1
  AND t.destination = p4.destination
LEFT JOIN
  `p3_association_rules` p3
  ON t.agg_stop_ts = p3.agg_stop_ts
  AND t.origin = p3.origin
  AND t.vessel_id = p3.vessel_id
  AND t.product_family = p3.product_family
  AND t.destination = p3.destination
LEFT JOIN
  `p2_association_rules` p2
  ON t.agg_stop_ts = p2.agg_stop_ts
  AND t.origin = p2.origin
  AND t.vessel_id = p2.vessel_id
  AND t.destination = p2.destination
LEFT JOIN
  `p1_association_rules` p1
  ON t.agg_stop_ts = p1.agg_stop_ts
  AND t.origin = p1.origin
  AND t.destination = p1.destination
LEFT JOIN
  `od_distance` od_distance
  ON t.origin = od_distance.origin
  AND t.destination = od_distance.destination
LEFT JOIN
  (SELECT `origin_h3_res2_index`, `destination_h3_res2_index`, avg(`od_distance`) as h3_od_distance
   FROM `od_distance`
   GROUP BY `origin_h3_res2_index`, `destination_h3_res2_index`) as h3_od_distance
  ON t.origin_h3_res2_index = h3_od_distance.origin_h3_res2_index
  AND t.destination_h3_res2_index = h3_od_distance.destination_h3_res2_index