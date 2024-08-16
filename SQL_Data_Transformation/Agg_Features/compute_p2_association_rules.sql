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
    origin,
    vessel_id,
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
    wd.origin,
    wd.vessel_id,
    wd.destination
  FROM
    all_weeks w
  CROSS JOIN (
    SELECT DISTINCT origin, vessel_id, destination
    FROM weekly_data
  ) wd
),
cumulative_counts AS (
  SELECT
    ac.week,
    ac.origin,
    ac.vessel_id,
    ac.destination,
    COUNT(wd.destination) OVER (
      PARTITION BY ac.origin, ac.vessel_id, ac.destination
      ORDER BY ac.week
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_count,
    COUNT(wd.destination) OVER (
      PARTITION BY ac.origin, ac.vessel_id
      ORDER BY ac.week
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_count
  FROM
    all_combinations ac
  LEFT JOIN
    weekly_data wd
  ON
    ac.week = wd.week
    AND ac.origin = wd.origin
    AND ac.vessel_id = wd.vessel_id
    AND ac.destination = wd.destination
)
SELECT
  week AS agg_stop_ts,
  origin,
  vessel_id,
  destination,
  CASE
    WHEN total_count > 0 THEN cumulative_count / total_count
    ELSE 0
  END AS probability
FROM
  cumulative_counts
WHERE
  cumulative_count > 0;
