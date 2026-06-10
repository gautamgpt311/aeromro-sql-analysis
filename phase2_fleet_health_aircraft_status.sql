-- Phase 2 — Fleet Health & Aircraft Status --

-- Identify all aircraft that have crossed critical flight hour or cycle thresholds
-- and classify them as 'Critical Threshold' or 'Normal Operations'.
SELECT
	tail_number,
    aircraft_type,
    base_station,
    status,
    CASE 
		WHEN total_flight_hours >= 40000 OR total_cycles > 30000 
		THEN 'Critical Threshold' ELSE 'Normal Operations' 
	END AS category
FROM aircraft
ORDER BY total_flight_hours DESC, total_cycles;


-- Which base stations are handling the highest flight operations —
-- ranked by total flight hours with aircraft count per station?
WITH base_station_cte AS (
	SELECT
		a.base_station,
		COUNT(DISTINCT a.aircraft_id) AS total_aircraft,
		SUM(flight_hours) AS total_flight_hours,
		SUM(cycles) AS total_cycles
	FROM aircraft AS a
    JOIN flight_cycles AS fc
		ON a.aircraft_id = fc.aircraft_id
    GROUP BY base_station
)
SELECT
	base_station,
    total_aircraft,
    total_flight_hours,
    total_cycles,
    RANK() OVER (ORDER BY total_flight_hours DESC) AS rank_total_flight
FROM base_station_cte;

-- Rank aircraft types by average fuel burn per cycle 
-- to identify fuel-inefficient types for engine performance review.
WITH fuel_burn_cte AS (
	SELECT
		a.aircraft_type,
		ROUND(AVG(fc.fuel_burn_kg), 2) AS avg_fuel_burn,
		ROUND(AVG(fc.cycles), 2) AS avg_cycles,
        ROUND(SUM(fc.fuel_burn_kg) / SUM(fc.cycles), 2) AS avg_fuel_burn_per_cycle
	FROM aircraft AS a
	JOIN flight_cycles AS fc
		ON a.aircraft_id = fc.aircraft_id
	GROUP BY a.aircraft_type
)
SELECT
	aircraft_type,
    avg_fuel_burn_per_cycle,
    RANK() OVER(ORDER BY avg_fuel_burn_per_cycle DESC) AS rank_fuel_burn
FROM fuel_burn_cte;

-- Identify aircraft with no flight activity in the last 90 days —
-- potential long-term groundings or undocumented withdrawals from service.
WITH overall_latest AS (
    SELECT 
		MAX(flight_date) AS max_date 
    FROM flight_cycles
),
last_flight_per_aircraft AS (
    SELECT 
		aircraft_id, 
		MAX(flight_date) AS last_flight
    FROM flight_cycles
    GROUP BY aircraft_id
)
SELECT
    lf.aircraft_id,
    a.tail_number,
    lf.last_flight,
    DATEDIFF(ol.max_date, lf.last_flight) AS days_inactive
FROM last_flight_per_aircraft AS lf
JOIN overall_latest AS ol
JOIN aircraft AS a 
	ON lf.aircraft_id = a.aircraft_id
WHERE DATEDIFF(ol.max_date, lf.last_flight) > 90;

-- Build a month-wise fleet utilisation trend showing total flight hours,
-- cycles, and active aircraft count per month.
SELECT
	DATE_FORMAT(flight_date, '%Y-%m') AS flight_month,
    SUM(fc.flight_hours) AS total_flight_hours,
    SUM(fc.cycles) AS total_cycles,
    COUNT(DISTINCT CASE WHEN a.status = 'Active' THEN a.aircraft_id END) AS total_active
FROM aircraft AS a
JOIN flight_cycles AS fc
	ON a.aircraft_id = fc.aircraft_id
GROUP BY flight_month
ORDER BY flight_month ASC;

-- Calculate rolling 30-day flight hours per aircraft and flag aircraft
-- Exceeding 150 hours — burnout risk detection before scheduled checks.
WITH flight_rolling_cte AS (
	SELECT
		fc1.aircraft_id,
		fc1.flight_date,
		(SELECT SUM(fc2.flight_hours)
		 FROM flight_cycles fc2
		 WHERE fc2.aircraft_id = fc1.aircraft_id
		 AND fc2.flight_date BETWEEN DATE_SUB(fc1.flight_date, INTERVAL 30 DAY) 
			AND fc1.flight_date) AS rolling_30day_hours
	FROM flight_cycles fc1
)
SELECT
	fr.aircraft_id,
    a.tail_number,
    fr.flight_date,
    fr.rolling_30day_hours
FROM  flight_rolling_cte AS fr
JOIN aircraft AS a
	ON fr.aircraft_id = a.aircraft_id
WHERE fr.rolling_30day_hours > 30;
