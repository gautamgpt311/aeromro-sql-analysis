# ✈️ AeroMRO Analytics — SQL Analysis

## About This Project

I wanted to build a project that reflects how data is actually used in aviation MRO operations — not just flight performance, but the full operational picture behind keeping aircraft airworthy. I designed a custom 9-table relational database from scratch covering every domain of MRO: fleet management, maintenance checks, technician workforce, parts inventory, and vendor procurement. Then I wrote 30 business-driven queries across 6 analysis phases that answer the kind of questions an MRO operations manager would actually ask.

---

## Dataset

- Source: Custom-built synthetic MRO dataset designed to simulate real airline MRO operations
- Size: 9 tables | 20 aircraft | 200 maintenance orders | 694 work orders | 300 purchase orders
- Tool: MySQL 8.0, MySQL Workbench

---

## What I Investigated

- Which aircraft are approaching critical flight hour and cycle thresholds?
- Which maintenance check types are breaching turnaround time targets?
- Which technicians have high deferral rates and whose licenses are expiring soon?
- Which AOG-critical parts are currently below their reorder point?
- Which vendors are underperforming on delivery and where is procurement spend concentrated?
- How are fleet utilization and procurement spend trending month over month?

---

## Key Findings

**Fleet Health**
6 aircraft have crossed critical thresholds — 40,000+ flight hours or 30,000+ cycles. These are flagged as Critical Threshold and need priority maintenance planning before the next cycle.

**Maintenance TAT**
C-Checks are averaging 258 days turnaround time — the highest of all check types and flagged as a TAT Breach. Engine Shop Visits average 124 days. All other check types are on track under 30 days.

**Deferred Work Backlog**
162 work orders are currently in Deferred status across all maintenance orders. This represents a significant unresolved discrepancy backlog across the fleet.

**Inventory Risk**
3 AOG-critical parts are below their reorder point. The Fuel Level Sensor is the most urgent — quantity on hand is 3 against a reorder point of 6. A direct Aircraft On Ground risk if not procured immediately.

**Technician License Risk**
12 AME licenses are expiring within the next 12 months. DEL and CCU stations are most exposed. Without renewal these technicians cannot legally sign off maintenance work under DGCA regulations.

**Vendor Performance**
HAL Accessories Division leads on-time delivery at 97.2%. TransDigm Group is the only underperforming vendor at 83.4%. Honeywell Aerospace holds the highest procurement spend at $14.3M but ranks only 11th in on-time delivery — a concentration risk worth flagging.

---

## Challenges I Faced

The most important challenge was designing the schema itself. In a real MRO system there are strict business rules — a work order must belong to a maintenance order, a maintenance order must belong to an aircraft, a part can only be consumed against the MO it was used in. Getting all 9 foreign key relationships correct before loading any data was essential because MySQL rejects records that violate referential integrity. Loading order mattered too — vendors and aircraft had to exist before inventory and maintenance orders, which had to exist before work orders and parts used.

The second challenge was NULL handling on import. Several columns — actual close dates for open MOs, sign-off dates for deferred work orders, actual delivery dates for pending POs — were intentionally blank in the CSV because those events had not happened yet. Naively loading them would either throw a Data Truncated error or default to a zero date, which would have broken every TAT and delay calculation in the project. I solved this by loading those columns into temporary variables first and using `IF(@variable = '', NULL, STR_TO_DATE())` to convert empty strings to NULL cleanly at the point of ingestion.

These two challenges taught me that in real MRO data projects, getting the data model right and handling NULL values correctly at the start saves far more time than fixing broken queries later.

---

## SQL Skills Demonstrated

- Multi-table JOINs across 3 and 4 tables simultaneously
- CTEs for readable multi-step analysis
- Window functions — RANK(), ROW_NUMBER(), NTILE(), LAG(), running totals with OVER and PARTITION BY
- DATEDIFF() for TAT and delay calculations
- DATE_FORMAT() for monthly trend grouping
- GROUP_CONCAT() for multi-value aggregation
- CASE WHEN for business classification and risk flagging
- Correlated subqueries for rolling window calculations
- UNION ALL for cross-table summary reports
- LOAD DATA INFILE with STR_TO_DATE(), IF(), and NULLIF() for NULL handling on import

---

## Project Structure

```
aeromro-sql-analysis/
│
├── 00_sql_schema.sql
├── phase1_data_exploration.sql
├── phase2_fleet_health_aircraft_status.sql
├── phase3_maintenance_operations_tat_performance.sql
├── phase4_technician_performance_license_compliance.sql
├── phase5_parts_consumption_inventory_risk.sql
├── phase6_vendor_procurement_performance.sql
└── README.md
```

---

## How to Run

1. Run `00_sql_schema.sql` to create the database, all 9 tables, and load the data
2. Place all CSV files in your MySQL uploads folder (`C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/`)
3. Update the file paths in the LOAD DATA INFILE statements if your upload path differs
4. Run phases 1 through 6 in order

---

## Related Project

📊 [AeroMRO Analytics — Power BI Dashboard](https://github.com/gautamgpt311/aeromro-analytics-powerbi)
