-- Phase 5 — Parts Consumption & Inventory Risk --

-- Identify AOG-critical parts currently below reorder point urgent procurement alert for the supply chain team.
SELECT
	part_number,
    part_name,
    quantity_on_hand,
    reorder_point,
    unit_cost_usd,
    (reorder_point - quantity_on_hand) AS Shortage_quantity
FROM inventory
WHERE criticality = 'AOG' AND quantity_on_hand < reorder_point
ORDER BY Shortage_quantity DESC;

-- Where is maintenance material cost concentrated? Total parts consumed, quantity used, and material cost by check type.
SELECT
	mo.mo_type,
    COUNT(DISTINCT pu.part_number) AS total_parts_comsumed,
    SUM(pu.quantity_used) AS total_quantity_used,
    ROUND(SUM(pu.quantity_used * inv.unit_cost_usd), 2) AS total_material_cost
FROM maintenance_orders AS mo
JOIN parts_used AS pu
	ON mo.mo_id = pu.mo_id
JOIN inventory AS inv
	ON inv.part_number = pu.part_number
GROUP BY mo.mo_type
ORDER BY total_material_cost DESC;

-- Top 10 most consumed parts by quantity across all maintenance events demand forecasting input for the next inventory cycle.
SELECT
	pu.part_number,
    inv.part_name,
    inv.ata_chapter,
    inv.criticality,
    SUM(pu.quantity_used) AS total_quantity_used,
    ROUND(SUM(pu.quantity_used * inv.unit_cost_usd), 2) AS total_comsuption_cost
FROM parts_used AS pu
JOIN inventory AS inv
	ON pu.part_number = inv.part_number
GROUP BY pu.part_number, pu.part_name, inv.ata_chapter, inv.criticality
ORDER BY total_comsuption_cost DESC
LIMIT 10;
    
-- Which parts have the highest scrap rate across maintenance events? Top 10 by total scrap cost recurring defect and quality analysis.
SELECT
	pu.part_number,
	inv.part_name,
    inv.criticality,
    SUM(CASE WHEN pu.removed_part_disposition = 'Scrapped' THEN pu.quantity_used ELSE 0 END) AS total_quantity_scrapped,
    SUM(CASE WHEN pu.removed_part_disposition = 'Scrapped' THEN pu.total_cost_usd ELSE 0 END) AS total_scrap_cost
FROM parts_used AS pu
JOIN inventory AS inv
	ON pu.part_number = inv.part_number
GROUP BY pu.part_number, inv.part_name, inv.criticality
ORDER BY total_scrap_cost DESC
LIMIT 10;

-- Where is inventory capital tied up across aircraft systems? Total inventory value on hand ranked by ATA chapter.
SELECT
	ata_chapter,
    ata_description,
    COUNT(part_name) AS total_parts,
    SUM(quantity_on_hand) AS total_quantity_on_hand,
    ROUND(SUM(quantity_on_hand * unit_cost_usd), 2) AS total_inventory_value
FROM inventory
GROUP BY ata_chapter, ata_description
ORDER BY total_inventory_value DESC;

-- Identify fast-expiring stock with shelf life of 365 days or less total stock value at risk for warehouse write-off prevention.
SELECT
	part_number,
    part_name,
    criticality,
    quantity_on_hand,
    shelf_life_days,
    ROUND(quantity_on_hand * unit_cost_usd, 2) AS stock_value_at_risk
FROM inventory
WHERE shelf_life_days <= 365 AND shelf_life_days IS NOT NULL AND quantity_on_hand > 0
ORDER BY stock_value_at_risk ASC;