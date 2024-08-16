WITH temp AS (
    SELECT 
        *
    FROM `trades_bq_joined`
    QUALIFY row_number() OVER (PARTITION BY vessel_id, CAST(voyage_number AS INT), destination ORDER BY `end_date_time` ASC) = 1
    AND row_number() OVER (PARTITION BY vessel_id, port_call_destination_id, destination ORDER BY `start_date_time` DESC) = 1
    AND origin <> destination
),
temp_2 AS (
    SELECT
        * EXCEPT(voyage_number, `origin_country_geography`, `destination_country_geography`),
    	`h3.LONGLAT_ASH3`(ST_X(ST_GEOGFROM(`origin_geo_point`)), ST_Y(ST_GEOGFROM(`origin_geo_point`)), 2) AS origin_h3_res2_index,
    	`h3.LONGLAT_ASH3`(ST_X(ST_GEOGFROM(`destination_geo_point`)), ST_Y(ST_GEOGFROM(`destination_geo_point`)), 2) AS destination_h3_res2_index,
        ST_ASTEXT(ST_MAKELINE(ST_GEOGFROM(origin_geo_point), ST_GEOGFROM(destination_geo_point))) AS `od_linestring`,
        CAST(distance AS INT)/1000 AS `distance_kms`,
        IF(LAG(destination) OVER(PARTITION BY vessel_id ORDER BY end_date_time ASC) IS NULL,
           origin,
           LAG(destination) OVER(PARTITION BY vessel_id ORDER BY end_date_time ASC)
          ) AS `previous_visited_port`,
        IF(LAG(destination) OVER(PARTITION BY vessel_id, port_call_origin_id ORDER BY end_date_time ASC) IS NULL,
           origin,
           LAG(destination) OVER(PARTITION BY vessel_id, port_call_origin_id ORDER BY end_date_time ASC)
          ) AS `previous_port`,
        IF(LAG(destination) OVER(PARTITION BY vessel_id, port_call_origin_id ORDER BY end_date_time ASC) IS NULL, 
            CAST(distance AS INT)/1000,
            (CAST(distance AS INT)/1000) - LAG((CAST(distance AS INT)/1000)) OVER(PARTITION BY vessel_id, port_call_origin_id ORDER BY destination_end_utc ASC)) AS `distance_from_previous_port`,
        DENSE_RANK() OVER(PARTITION BY vessel_id ORDER BY port_call_origin_id) AS voyage_number,
        ROW_NUMBER() OVER(PARTITION BY vessel_id, port_call_origin_id ORDER BY end_date_time ASC) AS `leg_index`,
        ROW_NUMBER() OVER(PARTITION BY vessel_id ORDER BY end_date_time ASC) AS `stop_index`
    FROM
        temp
),
temp_3 AS (
    SELECT
        *,
        LAG(destination) OVER (PARTITION BY vessel_id ORDER BY start_date_time) AS previous_visited_port_1,
        LAG(destination, 2) OVER (PARTITION BY vessel_id ORDER BY start_date_time) AS previous_visited_port_2,
        LAG(destination, 3) OVER (PARTITION BY vessel_id ORDER BY start_date_time) AS previous_visited_port_3,
        ARRAY_AGG(previous_port) OVER (
              PARTITION BY vessel_id, voyage_number
              ORDER BY leg_index
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS previous_ports_list,
        ARRAY_AGG(previous_visited_port) OVER (
              PARTITION BY vessel_id
              ORDER BY stop_index
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS previous_visited_ports_list,
    	SUM(CASE WHEN previous_visited_port != destination THEN 1 ELSE 0 END) OVER (PARTITION BY vessel_id ORDER BY start_date_time) as case_previous_diff_port
    FROM
        temp_2
),
temp_4 AS (
    SELECT
        *,
        FIRST_VALUE(previous_visited_port) OVER (
            PARTITION BY vessel_id, 
            case_previous_diff_port
            ORDER BY start_date_time
        ) AS previous_different_visited_port
    FROM
        temp_3
),
temp_5 AS (
    SELECT
        *,
        ARRAY_AGG(previous_different_visited_port) OVER (
            PARTITION BY vessel_id
            ORDER BY start_date_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS previous_different_visited_ports_list
    FROM
        temp_4
)
SELECT
    * except(previous_different_visited_ports_list, case_previous_diff_port, previous_different_visited_port),
    ARRAY(
        SELECT x 
        FROM UNNEST(previous_different_visited_ports_list) x WITH OFFSET pos
        WHERE pos = 0 OR x != previous_different_visited_ports_list[OFFSET(pos-1)]
    ) AS previous_different_visited_ports_list
FROM
    temp_5