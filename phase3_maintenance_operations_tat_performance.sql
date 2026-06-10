-- Phase 3 — Maintenance Operations & TAT Performance --

-- Which maintenance check types are breaching turnaround time targets?
-- Calculate average TAT per check type and flag breaches above 30 days.
SELECT
	mo_type,
	ROUND(AVG(DATEDIFF(actual_close_date, actual_start_date)), 2) AS avg_tat_days,
	CASE WHEN AVG(DATEDIFF(actual_close_date, actual_start_date)) > 30 THEN 'TAT breach' ELSE 'On Track' END AS tat_status
FROM maintenance_orders
WHERE status = 'Closed'
GROUP BY mo_type
ORDER BY avg_tat_days DESC;

-- Which maintenance orders carry the highest deferred work order backlog?
-- Identify all MOs with at least one deferred work order.
SELECT
	mo.mo_id,
    mo.aircraft_id,
    mo.mo_type,
    COUNT(wo.wo_id) AS total_deferred_work_orders
FROM maintenance_orders AS mo
JOIN work_orders AS wo
	ON mo.mo_id = wo.mo_id
WHERE wo.status = 'Deferred'
GROUP BY mo.mo_id, mo.aircraft_id
HAVING COUNT(wo.wo_id) >= 1
ORDER BY total_deferred_work_orders DESC;

-- Identify maintenance orders where actual manhours exceeded scheduled manhours by more than 20% 
-- manhour overrun analysis by station.
SELECT
	mo_id,
    aircraft_id,
    mo_type,
    station,
    scheduled_manhours,
    actual_manhours,
    ROUND((actual_manhours - scheduled_manhours) / scheduled_manhours * 100.0, 2) AS overrun_pct
FROM maintenance_orders
WHERE ROUND((actual_manhours - scheduled_manhours) / scheduled_manhours * 100.0, 2) > 20
ORDER BY overrun_pct DESC;

-- Which ATA chapters are generating the highest volume of discrepancy work orders? Rank by work order volume and percentage share.
SELECT
    ata_chapter,
    COUNT(*) AS total_work_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_share,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_by_volume
FROM work_orders
GROUP BY ata_chapter
ORDER BY total_work_orders DESC;

-- Which stations are most overloaded with pending and in-progress maintenance work? Ranked by total scheduled manhours still pending.

SELECT
	station,
    SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_maintenance_orders,
    SUM(CASE WHEN status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_maintenance_orders,
    SUM(scheduled_manhours) AS total_scheduled_manhours
FROM maintenance_orders
GROUP BY station
ORDER BY total_scheduled_manhours DESC;

-- For each maintenance type, identify the top 3 worst performing events by turnaround time using window functions.
WITH rank_tat_cte AS (
	SELECT
		mo_id,
		mo_type,
		aircraft_id,
		station,
		DATEDIFF(actual_close_date, actual_start_date) AS TAT_days,
		ROW_NUMBER() OVER(PARTITION BY mo_type ORDER BY DATEDIFF(actual_close_date, actual_start_date) DESC) AS rank_tat_days
	FROM maintenance_orders
	WHERE status = 'Closed'
)
SELECT
	mo_id,
    mo_type,
    aircraft_id,
    station,
    TAT_days,
    rank_tat_days
FROM rank_tat_cte
WHERE rank_tat_days <= 3;