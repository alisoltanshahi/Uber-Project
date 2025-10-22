-- #############################################################
-- ## PART 1: SCHEMA SETUP AND DATA REMEDIATION (ETL)
-- #############################################################

-- 1. DROP EXISTING TABLES (Safely drops all data and dependencies)
DROP TABLE IF EXISTS sensors CASCADE;
DROP TABLE IF EXISTS events_mixed CASCADE;
DROP TABLE IF EXISTS driver_car_assignment_planned CASCADE;
DROP TABLE IF EXISTS cars CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;

-- 2. CREATE TABLES (Using final, stable schema)
CREATE TABLE drivers (
    driver_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    contract_type VARCHAR(20),
    weekly_hours_limit INT,
    start_working_date DATE
);

CREATE TABLE cars (
    car_id VARCHAR(10) PRIMARY KEY,
    plate_number VARCHAR(15) UNIQUE,
    model VARCHAR(50),
    weight_kg INT, -- Accepting NULLs as per final fix
    first_registration DATE
);

CREATE TABLE driver_car_assignment_planned (
    assignment_id SERIAL PRIMARY KEY,
    driver_id VARCHAR(10) REFERENCES drivers(driver_id) ON DELETE CASCADE,
    car_id VARCHAR(10) REFERENCES cars(car_id) ON DELETE CASCADE,
    shift_start TIMESTAMP,
    shift_end TIMESTAMP
);

CREATE TABLE events_mixed (
    event_pk SERIAL PRIMARY KEY,
    driver_id VARCHAR(10) REFERENCES drivers(driver_id) ON DELETE NO ACTION,
    car_id VARCHAR(10) REFERENCES cars(car_id) ON DELETE NO ACTION,
    timestamp TIMESTAMP,
    event_type VARCHAR(50),
    trip_id VARCHAR(20),
    trip_type VARCHAR(50),
    actual_time_min NUMERIC,
    actual_dist_km NUMERIC,
    trip_cost NUMERIC,
    payment_type VARCHAR(10),
    cancellation_reason TEXT,
    cash_collected NUMERIC
);

CREATE TABLE sensors (
    sensor_id SERIAL PRIMARY KEY,
    date DATE,
    driver_id VARCHAR(10) REFERENCES drivers(driver_id) ON DELETE NO ACTION,
    car_id VARCHAR(10) REFERENCES cars(car_id) ON DELETE NO ACTION,
    seconds_above_15kmh INT,
    g_events INT,
    seatbelt_alarm_seconds INT,
    end_odometer_km NUMERIC
);

-- NOTE: Data must be loaded via Python/copy_from *after* this section.

-- 3. DATA REMEDIATION: CALCULATE MISSING actual_time_min
-- This assumes 'trip_start' and 'trip_end' events exist and are sequential.
WITH TripDurationCalculation AS (
    SELECT
        driver_id,
        timestamp AS start_timestamp,
        LEAD(timestamp) OVER (PARTITION BY driver_id ORDER BY timestamp) AS end_timestamp,
        EXTRACT(EPOCH FROM (LEAD(timestamp) OVER (PARTITION BY driver_id ORDER BY timestamp) - timestamp)) / 60 AS calculated_time_min
    FROM
        events_mixed
    WHERE
        event_type = 'trip_start'
)
UPDATE events_mixed AS em
SET
    actual_time_min = tdc.calculated_time_min
FROM
    TripDurationCalculation AS tdc
WHERE
    em.event_type = 'trip_end'
    AND em.driver_id = tdc.driver_id
    AND em.timestamp = tdc.end_timestamp
    AND em.actual_time_min IS NULL;
    
-- Set the calculated duration on the corresponding 'trip_start' row as well, 
-- since that is where the cost/distance data resides in many datasets.
UPDATE events_mixed AS em
SET
    actual_time_min = tdc.calculated_time_min
FROM
    TripDurationCalculation AS tdc
WHERE
    em.event_type = 'trip_start'
    AND em.driver_id = tdc.driver_id
    AND em.timestamp = tdc.start_timestamp
    AND em.actual_time_min IS NULL;