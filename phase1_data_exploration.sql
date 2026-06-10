-- Phase 1 — Data Exploration & Quality Checks --

-- How many records exist in each table of the MRO database?
SELECT
	'aircraft' AS mro_table, COUNT(*)
FROM aircraft
UNION ALL
SELECT
	'flight_cycles',
    COUNT(*)
FROM flight_cycles
UNION ALL
SELECT 
	'inventory',
    COUNT(*)
FROM inventory
UNION ALL
SELECT
	'maintenance_orders',
    COUNT(*)
FROM maintenance_orders
UNION ALL
SELECT
	'parts_used',
    COUNT(*)
FROM parts_used
UNION ALL
SELECT
	'purchase_orders',
    COUNT(*)
FROM purchase_orders
UNION ALL
SELECT
	'technicians',
    COUNT(*)
FROM technicians
UNION ALL
SELECT
	'vendors',
    COUNT(*)
FROM vendors
UNION ALL
SELECT
	'work_orders',
    COUNT(*)
FROM work_orders;

-- Which tables contain NULL values, in which columns, and how many?
SELECT 
    'maintenance_orders' AS table_name,
    'actual_close_date' AS column_name,
    SUM(CASE WHEN actual_close_date IS NULL THEN 1 ELSE 0 END) AS null_count
FROM maintenance_orders
UNION ALL
SELECT 
    'work_orders',
    'sign_off_date',
    SUM(CASE WHEN sign_off_date IS NULL THEN 1 ELSE 0 END)
FROM work_orders
UNION ALL
SELECT 
    'purchase_orders',
    'actual_delivery_date',
    SUM(CASE WHEN actual_delivery_date IS NULL THEN 1 ELSE 0 END)
FROM purchase_orders
UNION ALL
SELECT 
    'inventory',
    'shelf_life_days',
    SUM(CASE WHEN shelf_life_days IS NULL THEN 1 ELSE 0 END)
FROM inventory;

-- Are there any duplicate aircraft registrations (tail numbers) in the fleet master?
SELECT
	tail_number,
    COUNT(*) AS count
FROM aircraft
GROUP BY tail_number
HAVING COUNT(*) >= 2
ORDER BY count DESC;

-- What is the date range of operations covered in this dataset?
SELECT
	'flight_cycles' AS table_name,
    MIN(flight_date) AS earliest_date,
    MAX(flight_date) AS latest_date
FROM flight_cycles
UNION ALL
SELECT
	'maintenance_orders',
    MIN(scheduled_date),
    MAX(scheduled_date)
FROM maintenance_orders
UNION ALL
SELECT
	'purchase_orders',
    MIN(order_date),
    MAX(order_date)
FROM purchase_orders;

-- What is the distribution of aircraft by type, manufacturer, and current status?
SELECT 
	'aircraft_type' AS category,
	aircraft_type AS value,
    COUNT(*) AS count
FROM aircraft
GROUP BY aircraft_type
UNION ALL
SELECT 
	'manufacturer',
    manufacturer,
    COUNT(*)
FROM aircraft
GROUP BY manufacturer
UNION ALL
SELECT 'status',
status,
COUNT(*)
FROM aircraft
GROUP BY status;

-- What are the minimum, maximum, and average flight hours and cycles across the fleet?
SELECT
	'total_flight_hours' AS table_name,
    MIN(total_flight_hours) AS min_value,
    MAX(total_flight_hours) AS max_value,
    ROUND(AVG(total_flight_hours), 2) AS avg_value
FROM aircraft
UNION ALL
SELECT
	'total_cycles',
    MIN(total_cycles),
    MAX(total_cycles),
    ROUND(AVG(total_cycles), 2)
FROM aircraft
UNION ALL
SELECT
	'flight_hours',
    MIN(flight_hours),
    MAX(flight_hours),
    ROUND(AVG(flight_hours), 2)
FROM flight_cycles
UNION ALL
SELECT
	'cycles',
    MIN(cycles),
    MAX(cycles),
    ROUND(AVG(cycles), 2)
FROM flight_cycles;

-- How many maintenance orders, work orders, and parts used records exist per aircraft?
SELECT
	mo.aircraft_id,
    COUNT(DISTINCT mo.mo_id) AS count_maintenance_orders,
    COUNT(DISTINCT wo.wo_id) AS count_work_orders,
    COUNT(DISTINCT pu.pu_id) AS count_parts_used
FROM maintenance_orders AS mo
JOIN work_orders AS wo
	ON mo.mo_id = wo.mo_id
JOIN parts_used AS pu
	ON wo.mo_id = pu.mo_id
GROUP BY mo.aircraft_id;