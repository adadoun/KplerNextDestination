# KplerNextDestination


# BigQuery Data Transformation Process and Vessel Destination Prediction

This repository contains the SQL scripts, Jupyter notebooks, and documentation for our data exploration, transformation process using BigQuery and the subsequent vessel destination prediction models.

## Table of Contents
1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Data Flow](#data-flow)
4. [Transformation Steps](#transformation-steps)
5. [SQL Scripts](#sql-scripts)
6. [Jupyter Notebooks](#jupyter-notebooks)
7. [Execution Instructions](#execution-instructions)
8. [Data Quality Checks](#data-quality-checks)
9. [Performance Considerations](#performance-considerations)
10. [Troubleshooting](#troubleshooting)

## Overview

This project aims to transform raw maritime shipping data into a structured format suitable for analysis and prediction of vessel destinations. The transformation process involves multiple steps of data cleaning, feature engineering, and aggregation using BigQuery SQL. Following the data preparation, we develop and compare various models for predicting vessel destinations.

## Repository Structure

- `SQL_Scripts/`: Contains all SQL scripts for data transformation
- `Models_Notebooks/`: Jupyter notebooks for prototype models
- `EDA_Notebooks/`: Jupyter notebooks for exploratory data analysis
- `images/`: Diagrams and visualizations used in this README

## Data Flow

Our data transformation process follows these main stages:

1. Data Ingestion
2. Data Cleaning and Preprocessing
3. Feature Engineering
4. Aggregation and Merging
5. Final Output Preparation

![Data Flow Diagram](images/Data_Preprocessing.png)

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
## Jupyter Notebooks

### Exploratory Data Analysis (EDA_Notebooks)

The `EDA_Notebooks/` folder contains Jupyter notebooks used for initial data exploration and analysis. These notebooks provide insights into the dataset's characteristics, distributions, and potential features for our prediction models.

Key notebooks:
- `01_Data_Overview.ipynb`: Initial exploration of the dataset structure and basic statistics
- `02_Temporal_Analysis.ipynb`: Analysis of temporal patterns in vessel movements
- `03_Spatial_Analysis.ipynb`: Exploration of geographical aspects of vessel routes
- `04_Feature_Relationships.ipynb`: Investigation of relationships between different features

### Model Prototypes (Models_Notebooks)

The `Models_Notebooks/` folder contains Jupyter notebooks that implement and evaluate different approaches to vessel destination prediction.

Key notebooks:
- `01_Statistical_Model.ipynb`: Implementation of the baseline statistical model using historical probabilities
- `02_LGBM_Model.ipynb`: Development and evaluation of a Light Gradient Boosting Machine model
- `03_Neural_Network_Model.ipynb`: Implementation of a neural network model with embedding layers
- `04_Model_Comparison.ipynb`: Comparative analysis of all implemented models

These notebooks provide a comprehensive view of our modeling process, from baseline approaches to more sophisticated machine learning techniques.

## Execution Instructions

1. Ensure you have access to the BigQuery project and necessary datasets.
2. Execute the SQL scripts in the order specified in the [Transformation Steps](#transformation-steps) section.
3. After data preparation, explore the data using the notebooks in the `EDA_Notebooks/` folder.
4. Run the model prototype notebooks in the `Models_Notebooks/` folder to train and evaluate different prediction models.

## Data Quality Checks

[Content remains the same as in the previous version]

## Performance Considerations

[Content remains the same as in the previous version]

## Troubleshooting

[Previous content remains, with the following addition:]

For issues related to Jupyter notebooks:
1. **Kernel dies when running large datasets**: 
   - Solution: Consider using a more powerful machine or processing data in smaller batches.
2. **Package import errors**: 
   - Solution: Ensure all required packages are installed. A `requirements.txt` file is provided in the repository root.

For any other issues, please open an issue in this repository with a description of the problem and the relevant query or notebook.


