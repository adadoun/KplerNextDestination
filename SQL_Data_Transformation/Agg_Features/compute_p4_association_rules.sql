-- P4: Probability of destination given vessel_id, product_family, and previous_visited_port_1
WITH
  TEMP AS (
  SELECT
    *,
    DATE_TRUNC(TIMESTAMP(end_date_time), WEEK) AS week
  FROM
    `train_trades_bq` ),
weekly_data AS (
  SELECT DISTINCT
    week,
    vessel_id,
    product_family,
    previous_visited_port_1,
    destination
  FROM
    TEMP
),
all_weeks AS (
  SELECT DISTINCT week
  FROM weekly_data
),
all_combinations AS (
  SELECT
    w.week,
    wd.vessel_id,
    wd.product_family,
    wd.previous_visited_port_1,
    wd.destination
  FROM
    all_weeks w
  CROSS JOIN (
    SELECT DISTINCT vessel_id, product_family, previous_visited_port_1, destination
    FROM weekly_data
  ) wd
),
cumulative_counts AS (
  SELECT
    ac.week,
    ac.vessel_id,
    ac.product_family,
    ac.previous_visited_port_1,
    ac.destination,
    COUNT(wd.destination) OVER (
      PARTITION BY ac.vessel_id, ac.product_family, ac.previous_visited_port_1, ac.destination
      ORDER BY ac.week
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_count,
    COUNT(wd.destination) OVER (
      PARTITION BY ac.vessel_id, ac.product_family, ac.previous_visited_port_1
      ORDER BY ac.week
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_count
  FROM
    all_combinations ac
  LEFT JOIN
    weekly_data wd
  ON
    ac.week = wd.week
    AND ac.vessel_id = wd.vessel_id
    AND ac.product_family = wd.product_family
    AND ac.previous_visited_port_1 = wd.previous_visited_port_1
    AND ac.destination = wd.destination
)
SELECT
  week AS agg_stop_ts,
  vessel_id,
  product_family,
  previous_visited_port_1,
  destination,
  CASE
    WHEN total_count > 0 THEN cumulative_count / total_count
    ELSE 0
  END AS probability
FROM
  cumulative_counts
WHERE
  cumulative_count > 0;
