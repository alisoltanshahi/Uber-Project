-- #############################################################
-- ## PART 2: ADVANCED ANALYSIS QUERY (RISK-ADJUSTED EFFICIENCY SCORE)
-- #############################################################

WITH DriverShiftSummary AS (
    -- CTE 1: Calculate Total Revenue, Trips, and Safety Flags per Shift/Driver/Car
    SELECT
        dca.driver_id,
        dca.car_id,
        dca.assignment_id,
        dca.shift_start,
        dca.shift_end,
        -- Aggregate financial and operational data
        COALESCE(SUM(em.trip_cost), 0) AS total_shift_revenue,
        COUNT(em.trip_id) AS total_trips,
        -- Aggregate sensor data
        COALESCE(SUM(s.seconds_above_15kmh), 0) AS total_speeding_seconds,
        COALESCE(SUM(s.g_events), 0) AS total_g_events,
        -- Calculate the duration of the shift in hours
        NULLIF(ROUND(EXTRACT(EPOCH FROM (dca.shift_end - dca.shift_start)) / 3600.0, 2), 0) AS shift_hours
    FROM
        driver_car_assignment_planned dca
    LEFT JOIN
        events_mixed em ON dca.driver_id = em.driver_id
                        AND em.timestamp BETWEEN dca.shift_start AND dca.shift_end
                        AND LOWER(em.event_type) = 'trip_end'
    LEFT JOIN
        sensors s ON dca.driver_id = s.driver_id
                   AND s.date BETWEEN DATE(dca.shift_start) AND DATE(dca.shift_end)
    GROUP BY
        dca.assignment_id, dca.driver_id, dca.car_id, dca.shift_start, dca.shift_end
),
CarModelSummary AS (
    -- CTE 2: Calculate Average Revenue by Car Model (for normalization)
    SELECT
        ca.model,
        AVG(dss.total_shift_revenue) AS avg_model_revenue
    FROM
        DriverShiftSummary dss
    JOIN
        cars ca ON dss.car_id = ca.car_id
    GROUP BY
        ca.model
)
SELECT
    d.driver_id,
    d.name AS driver_name,
    ca.model AS car_model,
    dss.total_shift_revenue,
    -- 1. WINDOW FUNCTION: Calculate the average revenue of the last 3 shifts for this driver
    ROUND(AVG(dss.total_shift_revenue) OVER (
        PARTITION BY d.driver_id
        ORDER BY dss.shift_start DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS last_3_shift_avg_revenue,

    -- 2. WINDOW FUNCTION: Rank driver's revenue relative to all shifts for that car model
    RANK() OVER (
        PARTITION BY ca.model
        ORDER BY dss.total_shift_revenue DESC
    ) AS revenue_rank_by_model,

    -- 3. REGEX: Flag shifts where the car model suggests premium service but the revenue is low
    CASE
        WHEN ca.model ~* '(tesla|mercedes|bmw)' AND dss.total_shift_revenue < 50 THEN 'Premium_Car_Low_Earning'
        WHEN dss.shift_hours IS NULL OR dss.shift_hours = 0 THEN 'No_Time_Data'
        WHEN dss.shift_hours < 4 AND dss.total_trips > 5 THEN 'Short_Shift_High_Intensity'
        ELSE 'Normal'
    END AS shift_performance_category,

    -- 4. FINAL CALCULATION: Risk-Adjusted Efficiency Score
    ROUND(
        (dss.total_shift_revenue / dss.shift_hours) -
        (dss.total_speeding_seconds * 0.05) -
        (dss.total_g_events * 1.5)
    , 2) AS risk_adjusted_efficiency_score
FROM
    DriverShiftSummary dss
JOIN
    drivers d ON dss.driver_id = d.driver_id
JOIN
    cars ca ON dss.car_id = ca.car_id
JOIN
    CarModelSummary cms ON ca.model = cms.model
ORDER BY
    risk_adjusted_efficiency_score DESC;