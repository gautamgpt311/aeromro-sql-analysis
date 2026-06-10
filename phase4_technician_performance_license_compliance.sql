-- Phase 4 — Technician Performance & License Compliance --

-- Identify technicians with deferred work order rate above 30% flag as 'High Risk' or 'Acceptable' for compliance review.
SELECT
	tech.name AS technician_name,
    tech.license_type,
    COUNT(wo.tech_id) AS total_work_orders,
    SUM(CASE WHEN wo.status = 'Deferred' THEN 1 ELSE 0 END) AS total_deferred,
    ROUND(SUM(CASE WHEN wo.status = 'Deferred' THEN 1 ELSE 0 END) * 100.0 / COUNT(wo.tech_id), 2) AS deferral_pct,
    CASE WHEN SUM(CASE WHEN wo.status = 'Deferred' THEN 1 ELSE 0 END) * 100.0 / COUNT(wo.tech_id) > 30 THEN 'High Risk' ELSE 'Acceptable' END AS deferral_status
FROM work_orders AS wo
JOIN technicians AS tech
	ON wo.tech_id = tech.tech_id
GROUP BY technician_name, tech.license_type;

-- Which technicians have licenses expiring within the next 180 days? Sorted by days remaining for immediate compliance action.
SELECT
	name,
    specialization,
    license_type,
    license_expiry,
    DATEDIFF(license_expiry, (SELECT MAX(flight_date) FROM flight_cycles)) AS days_remaining
FROM technicians
WHERE DATEDIFF(license_expiry, (SELECT MAX(flight_date) FROM flight_cycles)) BETWEEN 0 AND 180
ORDER BY days_remaining ASC;

-- Rank technicians by total hours logged within each specialization and segment into performance bands using NTILE(4).
WITH tech_hours AS (
    SELECT tech.name, tech.specialization, SUM(wo.hours_logged) AS total_hours
    FROM technicians tech 
    JOIN work_orders wo 
		ON tech.tech_id = wo.tech_id
    GROUP BY tech.tech_id, tech.name, tech.specialization
)
SELECT name, specialization, total_hours,
    RANK() OVER(PARTITION BY specialization ORDER BY total_hours DESC) AS rank_in_specialization,
    CASE NTILE(4) OVER(ORDER BY total_hours DESC)
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN 'Upper Mid'
        WHEN 3 THEN 'Lower Mid'
        WHEN 4 THEN 'Bottom 25%'
    END AS performance_band
FROM tech_hours;

-- Identify technicians deployed across multiple stations multi-base deployment analysis for workforce planning.
SELECT
	tech.name,
    tech.specialization,
    COUNT(DISTINCT mo.station) AS total_stations,
    GROUP_CONCAT(DISTINCT mo.station) AS group_station
FROM work_orders AS wo
JOIN technicians AS tech
	ON wo.tech_id = tech.tech_id
JOIN maintenance_orders AS mo
	ON mo.mo_id = wo.mo_id
GROUP BY tech.name, tech.specialization
HAVING COUNT(DISTINCT mo.station) > 1;

-- Do higher certified technicians log more hours per task? Average hours per work order analysed by license type.
SELECT
	tech.license_type,
    COUNT(DISTINCT tech.tech_id) AS total_technicians,
    COUNT(wo.wo_id) AS total_work_orders,
    ROUND(SUM(wo.hours_logged) / COUNT(wo.wo_id), 2) AS avg_hour_per_work_order
FROM work_orders AS wo
JOIN technicians AS tech
	ON wo.tech_id = tech.tech_id
GROUP BY tech.license_type
ORDER BY avg_hour_per_work_order DESC;

-- Segment the entire technician workforce into High, Medium, and Low utilisation bands using NTILE(3) based on total hours logged.
WITH technicians_cte AS (
	SELECT
		tech.name,
		tech.specialization,
		tech.license_type,
		SUM(wo.hours_logged) AS total_hours_logged
	FROM technicians AS tech
	JOIN work_orders AS wo
		ON tech.tech_id = wo.tech_id
	GROUP BY tech.name, tech.specialization, tech.license_type
)
SELECT
	name,
    specialization,
    license_type,
    total_hours_logged,
    CASE NTILE(3) OVER(ORDER BY total_hours_logged DESC)
		WHEN 1 THEN 'High Utilisation'
        WHEN 2 THEN 'Medium Utilisation'
        WHEN 3 THEN 'Low Utilisation'
	END AS utilisated_hours
FROM technicians_cte;