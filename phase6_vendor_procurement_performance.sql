-- Phase 5 — Vendor & Procurement Performance --

-- The procurement manager wants to hold vendors accountable for delivery performance. 
-- Rank all vendors by their average delay in days against committed delivery dates — only for delivered orders. 
-- Show vendor name, total orders delivered, average delay days, and rank. 
-- Flag vendors with average delay above 5 days as 'Underperforming' and others as 'Acceptable'
WITH vendors_cte AS (
	SELECT
		ven.vendor_name,
		SUM(CASE WHEN po.status = 'Delivered' THEN 1 ELSE 0 END) AS total_orders_delivered,
		ROUND(AVG(DATEDIFF(actual_delivery_date, expected_delivery_date)), 2) AS avg_delay_days
	FROM purchase_orders AS po
	JOIN vendors AS ven
		ON po.vendor_id = ven.vendor_id
	WHERE po.status = 'Delivered'
	GROUP BY ven.vendor_name
)
SELECT
	vendor_name,
    total_orders_delivered,
    avg_delay_days,
    CASE WHEN avg_delay_days > 5 THEN 'Underperforming' ELSE 'Acceptable' END AS flag_vendors,
    RANK() OVER(ORDER BY avg_delay_days) AS rank_avg_delay_days
FROM vendors_cte;
    
--  The supply chain risk team wants to assess vendor concentration. 
-- Calculate what percentage of total procurement spend is held by each vendor. 
-- Show vendor name, total spend, percentage of total spend, and cumulative spend percentage. 
-- Flag the top 3 vendors by spend as 'High Concentration Risk'.
WITH vendor_spend AS (
    SELECT vendor_name, SUM(total_cost_usd) AS total_spend
    FROM purchase_orders AS po
    JOIN vendors AS ven
		ON po.vendor_id = ven.vendor_id
    GROUP BY vendor_name
)
SELECT vendor_name, total_spend,
    ROUND(total_spend * 100.0 / SUM(total_spend) OVER(), 2) AS spend_pct,
    ROUND(SUM(total_spend) OVER(ORDER BY total_spend DESC), 2) AS cumulative_spend,
    CASE WHEN RANK() OVER(ORDER BY total_spend DESC) <= 3 
         THEN 'High Concentration Risk' ELSE 'Normal' END AS risk_flag
FROM vendor_spend;

-- The operations team wants to know which delayed purchase orders are directly impacting flight operations. 
-- Identify all purchase orders for AOG-critical parts that are delayed by more than 7 days beyond their expected delivery date. 
-- Show PO ID, vendor name, part name, criticality, order date, expected vs actual delivery, and delay days. 
-- Sort by delay days descending.
SELECT
	po.po_id,
    ven.vendor_name,
    po.part_name,
    inv.criticality,
    po.order_date,
    po.expected_delivery_date,
    po.actual_delivery_date,
    DATEDIFF(actual_delivery_date, expected_delivery_date) AS delay_days
FROM purchase_orders AS po
JOIN vendors AS ven
	ON po.vendor_id = ven.vendor_id
JOIN inventory AS inv
	ON inv.part_number = po.part_number
WHERE inv.criticality = 'AOG' AND DATEDIFF(actual_delivery_date, expected_delivery_date) > 7
ORDER BY delay_days DESC;

-- The supply chain risk team wants to identify single vendor dependency across aircraft systems.
-- Find vendors who supply parts across the most ATA chapters. 
-- Show vendor name, approved status, total parts supplied, total ATA chapters covered, and list the ATA chapters. 
-- Sort by ATA chapters covered descending.
SELECT
	ven.vendor_name,
    ven.approved_status,
    COUNT(inv.part_number) AS total_part_supplied,
    COUNT(DISTINCT ata_chapter) AS total_ata_chapters_covered,
    GROUP_CONCAT(DISTINCT ata_description) AS list_ata_chapter
FROM inventory AS inv
JOIN vendors AS ven
	ON inv.vendor_id = ven.vendor_id
GROUP BY ven.vendor_name, ven.approved_status
ORDER BY total_ata_chapters_covered DESC;

-- The finance team wants to track how procurement spending has evolved over time. 
-- Build a monthly procurement spend trend showing total orders, total spend, and month over month spend change. 
-- Sort chronologically.
WITH monthly_spend AS (
	SELECT
		DATE_FORMAT(order_date, '%Y-%m') AS order_month,
		COUNT(*) AS total_orders,
		ROUND(SUM(total_cost_usd), 2) AS total_spend
	FROM purchase_orders
	GROUP BY order_month
)
SELECT
	order_month,
    total_orders,
    total_spend,
    LAG(total_spend) OVER(ORDER BY order_month) AS prev_month_spend,
    ROUND(total_spend - LAG(total_spend) OVER(ORDER BY order_month), 2) AS mom_change
FROM monthly_spend
ORDER BY order_month;

-- The procurement director wants a single vendor scorecard to make sourcing decisions. 
-- Build a comprehensive vendor scorecard combining on-time delivery rate, quality rating, total spend, and total orders. 
-- Rank vendors overall using a weighted score. 
-- Show vendor name, approved status, on-time delivery %, quality rating, total spend, total orders, and final rank.
WITH vendor_scorecard AS (
    SELECT
        ven.vendor_name,
        ven.approved_status,
        ven.on_time_delivery_pct,
        ven.avg_lead_time_days,
        COUNT(po.po_id) AS total_orders,
        ROUND(SUM(po.total_cost_usd), 2) AS total_spend
    FROM vendors AS ven
    JOIN purchase_orders AS po
        ON ven.vendor_id = po.vendor_id
    GROUP BY ven.vendor_name, ven.approved_status, ven.on_time_delivery_pct, ven.avg_lead_time_days
)
SELECT
    vendor_name,
    approved_status,
    on_time_delivery_pct,
    avg_lead_time_days,
    total_orders,
    total_spend,
    RANK() OVER(ORDER BY on_time_delivery_pct DESC) AS final_rank
FROM vendor_scorecard;