# KplerNextDestination

# BigQuery Data Transformation Process

This repository contains the SQL scripts and documentation for our data transformation process using BigQuery.

## Table of Contents
1. [Overview](#overview)
2. [Data Flow](#data-flow)
3. [Transformation Steps](#transformation-steps)
4. [SQL Scripts](#sql-scripts)
5. [Execution Instructions](#execution-instructions)
6. [Data Quality Checks](#data-quality-checks)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting](#troubleshooting)

## Overview

This project aims to transform raw maritime shipping data into a structured format suitable for analysis and prediction of vessel destinations. The transformation process involves multiple steps of data cleaning, feature engineering, and aggregation using BigQuery SQL.

## Data Flow

Our data transformation process follows these main stages:

1. Data Ingestion
2. Data Cleaning and Preprocessing
3. Feature Engineering
4. Aggregation and Merging
5. Final Output Preparation

![Data Flow Diagram](images/data_flow_diagram.png)

## Transformation Steps

### 1. Data Preparation and Splitting

- SQL Script: `train_test_split.sql`
- Input: Raw trades data
- Output: Preprocessed and split train/test datasets

This step involves cleaning the raw data, handling multiple products per trade, defining voyages, and creating a temporal split for train and test sets.

![Train/Test Split](images/train_test_split.png)

### 2. Feature Engineering

- SQL Script: `feature_engineering.sql`
- Input: Preprocessed trades data
- Output: Trades data with additional engineered features

This step creates new features such as temporal features, voyage sequencing, historical port visits, and distance calculations.

![Feature Engineering](images/feature_engineering.png)

### 3. Probability Calculations

- SQL Scripts: 
  - `probability_p1.sql`
  - `probability_p2.sql`
  - `probability_p3.sql`
  - `probability_p4.sql`
- Input: Preprocessed trades data
- Output: Probability tables for different levels of granularity

These scripts calculate rolling window probabilities for destination prediction at various levels of specificity.

![Probability Calculations](images/probability_calculations.png)

### 4. Final Data Aggregation

- SQL Script: `final_aggregation.sql`
- Input: 
  - Preprocessed trades data
  - Engineered features
  - Probability tables
- Output: Final dataset ready for model training

This step combines all the processed data and calculated probabilities into a final dataset.

![Final Aggregation](images/final_aggregation.png)

## SQL Scripts

- `train_test_split.sql`: Preprocesses raw data and creates train/test splits
- `feature_engineering.sql`: Creates additional features from the preprocessed data
- `probability_p1.sql`: Calculates P1 probabilities (origin to destination)
- `probability_p2.sql`: Calculates P2 probabilities (origin, vessel to destination)
- `probability_p3.sql`: Calculates P3 probabilities (origin, vessel, product to destination)
- `probability_p4.sql`: Calculates P4 probabilities (vessel, product, previous port to destination)
- `final_aggregation.sql`: Combines all processed data into the final dataset

## Execution Instructions

1. Ensure you have access to the BigQuery project and necessary datasets.
2. Execute the scripts in the following order:
   - `train_test_split.sql`
   - `feature_engineering.sql`
   - `probability_p1.sql`
   - `probability_p2.sql`
   - `probability_p3.sql`
   - `probability_p4.sql`
   - `final_aggregation.sql`
3. Verify the output at each stage using the provided data quality checks.

## Data Quality Checks

After each transformation step, run the following checks:
1. Check for null values in critical columns
2. Verify the number of rows in output tables
3. Ensure date ranges are as expected
4. Validate calculated probabilities sum to 1 for each group

Sample check query:
```sql
SELECT 
  COUNT(*) as total_rows,
  COUNT(DISTINCT vessel_id) as unique_vessels,
  MIN(start_date_time) as min_date,
  MAX(start_date_time) as max_date
FROM `project.dataset.final_trades_table`;
```

## Performance Considerations

- Use partitioning on date columns for large tables
- Apply clustering on frequently filtered columns (e.g., vessel_id, origin, destination)
- Optimize JOIN operations by placing the larger table first
- Use approximate aggregations (e.g., APPROX_COUNT_DISTINCT) for large-scale aggregations where slight inaccuracy is acceptable

## Troubleshooting

Common issues and solutions:

1. **Out of memory error**: 
   - Solution: Break down the query into smaller steps or use a larger machine type.

2. **Unexpected null values**: 
   - Solution: Add COALESCE or IFNULL functions to handle nulls, or investigate the source of nulls in upstream data.

3. **Slow query performance**: 
   - Solution: Review query plan, optimize JOINs, and consider adding additional columns to table clustering.

For any other issues, please open an issue in this repository with a description of the problem and the relevant query.
