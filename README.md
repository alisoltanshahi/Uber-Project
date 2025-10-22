#  Uber Logistics Optimization & Predictive Pricing

This project demonstrates an **end-to-end data science pipeline**, from data cleaning and advanced feature engineering in PostgreSQL to building and validating production-ready Machine Learning models for a fictitious ride-sharing company.

***

## I. Business Objectives

The project delivered solutions across three core business needs:

* **Prediction:** Accurately forecast the final **Trip Cost** (Regression).
* **Classification:** Identify **High-Value Trips** (top 25% cost) for priority dispatch and operational focus.
* **Optimization:** Derive core Key Performance Indicators (KPIs) and actionable insights regarding driver efficiency and shift profitability.

***

## II. Technical Stack

| Category | Tools & Technologies |
| :--- | :--- |
| **Database** | **Neon PostgreSQL** (Cloud-native RDBMS) |
| **Data Prep** | Python, Pandas, SQLAlchemy, Advanced SQL (CTEs, Window Functions) |
| **Modeling** | Scikit-learn (**RandomForestClassifier**, **RandomForestRegressor**), imblearn (SMOTE) |
| **Visualization** | Tableau (for executive dashboards) |
| **MLOps** | Joblib (Artifact Persistence) |

***

## III. Key Project Phases & Successes

### 1. Robust Data Ingestion & Cleaning
* Successfully cleaned and loaded denormalized CSV data into a fully relational schema.
* Resolved complex data errors like case-sensitivity and performed crucial data imputation (e.g., calculating **`actual_time_min`** from disparate `trip_start` / `trip_end` events).

### 2. Advanced Analysis
* Created **10 analytical SQL Views** (e.g., `Tableau_RPOH_Summary`, `Tableau_Safety_Compliance`) to power live, dynamic Tableau dashboards for operational monitoring.

### 3. Focused Feature Engineering
* Determined that a simple, non-biased feature set (`actual_dist_km`, `actual_time_min`, `trip_type`) was the most effective for predictive modeling. Extraneous features (like `contract_type`) were removed to eliminate potential bias and improve model robustness.

***

## IV. Final Model Performance (Deployment Ready)

The final models were built with highly focused feature sets and rigorously validated, achieving exceptional and reliable results:

| Model | Primary Goal | Final Metric | Score | Finding |
| :--- | :--- | :--- | :--- | :--- |
| **Regression (Trip Cost)** | Forecasting Price | R-squared ($R^2$) | **0.9957** | **Excellent Fit.** The model explains **99.57%** of the cost variance, confirming highly accurate pricing forecasts. |
| **Classification (High-Value Trip)** | Identifying Opportunities | ROC AUC Score | **1.0000** | **Perfect Discrimination.** The model flawlessly separates high-value from normal trips, making its output **97% precise** and **100% reliable (Recall)** for operational alerts. |

***

## V. Next Steps (MLOps Focus)

The project is complete and the model artifacts are ready for deployment to deliver real-time value:

* **API Deployment:** The `.joblib` artifacts and scalers are ready to be served via a low-latency API (e.g., Flask/FastAPI) for **real-time predictions**.
* **Monitoring:** Implement data drift and model performance monitoring to ensure the $R^2$ and Precision scores remain consistently high in a live production environment.
