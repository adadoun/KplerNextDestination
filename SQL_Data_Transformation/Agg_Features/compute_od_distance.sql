SELECT 
    origin,
    origin_h3_res2_index,
    destination,
    destination_h3_res2_index,
    avg(distance_kms) as od_distance
  FROM `train_trades_bq`
  GROUP BY
  	origin,
    origin_h3_res2_index,
    destination,
    destination_h3_res2_index,