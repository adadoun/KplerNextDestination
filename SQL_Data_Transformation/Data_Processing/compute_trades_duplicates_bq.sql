SELECT
	MIN(id) AS id,
    port_call_origin_id,
    port_call_destination_id,
    sum(cast(traded_volume as decimal)) as traded_volume,
    distance,
    start_date_time,
    end_date_time,
    product_family,
    STRING_AGG(DISTINCT product, ', ' ORDER BY product) AS products,
  FROM
    `trades_bq`
  GROUP BY
    port_call_origin_id,
    port_call_destination_id,
    distance,
    start_date_time,
    end_date_time,
    product_family