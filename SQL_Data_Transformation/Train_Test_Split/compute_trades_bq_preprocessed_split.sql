-- Step 1: Define the cut-off date for the train set
WITH cut_off_date AS (
  SELECT DATE('2023-10-30') AS train_end_date
),

-- Step 2: Create the train set
train_set AS (
  SELECT * EXCEPT(start_date_time, end_date_time),
         TIMESTAMP(start_date_time) AS start_date_time,
         TIMESTAMP(end_date_time) AS end_date_time
  FROM `trades_bq_preprocessed`
  WHERE DATE(TIMESTAMP(end_date_time)) <= (SELECT train_end_date FROM cut_off_date)
),

-- Step 3: Find the maximum end_date_time in the train set
max_train_date AS (
  SELECT MAX(end_date_time) AS max_end_date
  FROM train_set
),

-- Step 4: Identify potential test set records
potential_test_set AS (
  SELECT * EXCEPT(start_date_time, end_date_time),
         TIMESTAMP(start_date_time) AS start_date_time,
         TIMESTAMP(end_date_time) AS end_date_time
  FROM `trades_bq_preprocessed`
  WHERE TIMESTAMP(start_date_time) > (SELECT max_end_date FROM max_train_date)
),

-- Step 5: Identify the latest record for each vessel in the potential test set
latest_test_records AS (
  SELECT
    vessel_id,
    MAX(end_date_time) AS max_end_date_time
  FROM potential_test_set
  GROUP BY vessel_id
),

-- Step 6: Create the final test set with only the last trip for each vessel
test_set AS (
  SELECT t.*
  FROM potential_test_set t
  INNER JOIN latest_test_records ltr
  ON t.vessel_id = ltr.vessel_id AND t.end_date_time = ltr.max_end_date_time
)

-- Output the results
SELECT 'train' AS dataset_type, * FROM train_set
UNION ALL
SELECT 'test' AS dataset_type, * FROM test_set