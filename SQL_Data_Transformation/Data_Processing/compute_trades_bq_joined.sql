SELECT 
    *
    DENSE_RANK() over(PARTITION BY vessel_id order by port_call_origin_id) AS `voyage_number`
  FROM (
    SELECT 
        `trades_duplicates_bq`.`id` AS `id`,
        `trades_duplicates_bq`.`port_call_origin_id` AS `port_call_origin_id`,
        `trades_duplicates_bq`.`port_call_destination_id` AS `port_call_destination_id`,
        `trades_duplicates_bq`.`traded_volume` AS `traded_volume`,
        `trades_duplicates_bq`.`distance` AS `distance`,
        `trades_duplicates_bq`.`start_date_time` AS `start_date_time`,
        `trades_duplicates_bq`.`end_date_time` AS `end_date_time`,
        `trades_duplicates_bq`.`product_family` AS `product_family`,
        `trades_duplicates_bq`.`products` AS `products`,
        `port_calls_enriched_bq`.`vessel_id` AS `vessel_id`,
        `port_calls_enriched_bq`.`start_utc` AS `origin_start_utc`,
        `port_calls_enriched_bq`.`end_utc` AS `origin_end_utc`,
        `port_calls_enriched_bq`.`cargo_volume` AS `origin_cargo_volume`,
        `port_calls_enriched_bq`.`draught_change` AS `origin_draught_change`,
        `port_calls_enriched_bq`.`destination` AS `origin`,
        `port_calls_enriched_bq`.`destination_longitude` AS `origin_longitude`,
        `port_calls_enriched_bq`.`destination_latitude` AS `origin_latitude`,
        `port_calls_enriched_bq`.`destination_geo_point` AS `origin_geo_point`,
        `port_calls_enriched_bq`.`country_name` AS `origin_country_name`,
        `port_calls_enriched_bq`.`country_code` AS `origin_country_code`,
        `port_calls_enriched_bq`.`continent_code` AS `origin_continent_code`,
        `port_calls_enriched_bq`.`region_code` AS `origin_region_code`,
        `port_calls_enriched_bq`.`country_geography` AS `origin_country_geography`,
        `port_calls_enriched_bq_2`.`start_utc` AS `destination_start_utc`,
        `port_calls_enriched_bq_2`.`end_utc` AS `destination_end_utc`,
        `port_calls_enriched_bq_2`.`cargo_volume` AS `destination_cargo_volume`,
        `port_calls_enriched_bq_2`.`draught_change` AS `destination_draught_change`,
        `port_calls_enriched_bq_2`.`destination` AS `destination`,
        `port_calls_enriched_bq_2`.`destination_longitude` AS `destination_longitude`,
        `port_calls_enriched_bq_2`.`destination_latitude` AS `destination_latitude`,
        `port_calls_enriched_bq_2`.`destination_geo_point` AS `destination_geo_point`,
        `port_calls_enriched_bq_2`.`country_name` AS `destination_country_name`,
        `port_calls_enriched_bq_2`.`country_code` AS `destination_country_code`,
        `port_calls_enriched_bq_2`.`continent_code` AS `destination_continent_code`,
        `port_calls_enriched_bq_2`.`region_code` AS `destination_region_code`,
        `port_calls_enriched_bq_2`.`country_geography` AS `destination_country_geography`,
        `vessels_bq`.`status` AS `status`,
        `vessels_bq`.`status_detail` AS `status_detail`,
        `vessels_bq`.`build_country` AS `build_country`,
        `vessels_bq`.`build_year` AS `build_year`,
        `vessels_bq`.`flag_name` AS `flag_name`,
        `vessels_bq`.`dead_weight` AS `dead_weight`,
        `vessels_bq`.`vessel_type` AS `vessel_type`
      FROM `trades_duplicates_bq`
      INNER JOIN `port_calls_enriched_bq`
        ON `trades_duplicates_bq`.`port_call_origin_id` = `port_calls_enriched_bq`.`id`
      INNER JOIN `port_calls_enriched_bq_2`
        ON `trades_duplicates_bq`.`port_call_destination_id` = `port_calls_enriched_bq_2`.`id`
      LEFT JOIN `vessels_bq`
        ON `port_calls_enriched_bq`.`vessel_id` = `vessels_bq`.`id`
    ) `withoutcomputedcols_query`