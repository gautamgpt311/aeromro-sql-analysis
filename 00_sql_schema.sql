-- ============================================================
-- Project  : Aircraft MRO Analytics
-- File     : 00_sql_schema.sql
-- Tool     : MySQL 8.0
-- Dataset  : Simulated MRO Data (9 tables | ~5,000 rows)
-- Tables   : aircraft, technicians, vendors, inventory,
--            maintenance_orders, work_orders, parts_used,
--            purchase_orders, flight_cycles
-- ============================================================

-- Create the database --
CREATE DATABASE mro_db;
USE mro_db;

-- Create the aircraft table --
CREATE TABLE aircraft (
    aircraft_id        VARCHAR(10)  NOT NULL PRIMARY KEY,
    tail_number        VARCHAR(15)  NOT NULL UNIQUE,
    aircraft_type      VARCHAR(30)  NOT NULL,
    engine_type        VARCHAR(30)  NOT NULL,
    entry_service_date DATE         NOT NULL,
    base_station       VARCHAR(5)   NOT NULL,
    total_flight_hours INT          DEFAULT 0,
    total_cycles       INT          DEFAULT 0,
    manufacturer       VARCHAR(50),
    status             VARCHAR(20)  DEFAULT 'Active'
);

-- Create the technicians table --
CREATE TABLE technicians (
    tech_id            VARCHAR(10)  NOT NULL PRIMARY KEY,
    name               VARCHAR(80)  NOT NULL,
    license_type       VARCHAR(40)  NOT NULL,
    specialization     VARCHAR(40)  NOT NULL,
    license_expiry     DATE         NOT NULL,
    experience_years   INT          DEFAULT 0,
    station            VARCHAR(5)   NOT NULL,
    total_hours_logged INT          DEFAULT 0
);

-- Create the vendors table --
CREATE TABLE vendors (
    vendor_id            VARCHAR(10)   NOT NULL PRIMARY KEY,
    vendor_name          VARCHAR(80)   NOT NULL,
    country              VARCHAR(40)   NOT NULL,
    avg_lead_time_days   INT           DEFAULT 10,
    on_time_delivery_pct DECIMAL(5,2)  DEFAULT 90.00,
    approved_status      VARCHAR(20)   DEFAULT 'Approved',
    total_orders_placed  INT           DEFAULT 0,
    payment_terms_days   INT           DEFAULT 30
);

-- Create the inventory table --
CREATE TABLE inventory (
    part_number      VARCHAR(25)   NOT NULL PRIMARY KEY,
    part_name        VARCHAR(80)   NOT NULL,
    ata_chapter      VARCHAR(10)   NOT NULL,
    ata_description  VARCHAR(50),
    vendor_id        VARCHAR(10)   NOT NULL,
    quantity_on_hand INT           DEFAULT 0,
    reorder_point    INT           DEFAULT 2,
    reorder_quantity INT           DEFAULT 5,
    unit_cost_usd    DECIMAL(12,2) DEFAULT 0.00,
    criticality      VARCHAR(15)   DEFAULT 'Routine',
    shelf_life_days  INT,
    part_condition   VARCHAR(20)   DEFAULT 'Serviceable',

    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
);

-- Create the maintenance orders table --
CREATE TABLE maintenance_orders (
    mo_id              VARCHAR(10) NOT NULL PRIMARY KEY,
    aircraft_id        VARCHAR(10) NOT NULL,
    mo_type            VARCHAR(30) NOT NULL,
    scheduled_date     DATE        NOT NULL,
    actual_start_date  DATE,
    actual_close_date  DATE,
    station            VARCHAR(5)  NOT NULL,
    scheduled_manhours INT         DEFAULT 0,
    actual_manhours    INT         DEFAULT 0,
    status             VARCHAR(20) DEFAULT 'Pending',
    reference_doc      VARCHAR(40),

    FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id)
);

-- Create the work orders table --
CREATE TABLE work_orders (
    wo_id             VARCHAR(10)  NOT NULL PRIMARY KEY,
    mo_id             VARCHAR(10)  NOT NULL,
    tech_id           VARCHAR(10)  NOT NULL,
    ata_chapter       VARCHAR(10)  NOT NULL,
    task_description  VARCHAR(120) NOT NULL,
    hours_logged      INT          DEFAULT 0,
    discrepancy       VARCHAR(200),
    corrective_action VARCHAR(200),
    status            VARCHAR(20)  DEFAULT 'Pending',
    sign_off_date     DATE,

    FOREIGN KEY (mo_id)   REFERENCES maintenance_orders(mo_id),
    FOREIGN KEY (tech_id) REFERENCES technicians(tech_id)
);

-- Create the part used table --
CREATE TABLE parts_used (
    pu_id                    VARCHAR(10)   NOT NULL PRIMARY KEY,
    mo_id                    VARCHAR(10)   NOT NULL,
    part_number              VARCHAR(25)   NOT NULL,
    part_name                VARCHAR(80),
    quantity_used            INT           DEFAULT 1,
    unit_cost_usd            DECIMAL(12,2) DEFAULT 0.00,
    total_cost_usd           DECIMAL(14,2) DEFAULT 0.00,
    part_condition           VARCHAR(20)   DEFAULT 'Serviceable',
    removal_date             DATE,
    installation_date        DATE,
    removed_part_disposition VARCHAR(30),

    FOREIGN KEY (mo_id)       REFERENCES maintenance_orders(mo_id),
    FOREIGN KEY (part_number) REFERENCES inventory(part_number)
);

-- Create the purchase orders table --
CREATE TABLE purchase_orders (
    po_id                  VARCHAR(10)   NOT NULL PRIMARY KEY,
    vendor_id              VARCHAR(10)   NOT NULL,
    part_number            VARCHAR(25)   NOT NULL,
    part_name              VARCHAR(80),
    quantity_ordered       INT           DEFAULT 1,
    unit_cost_usd          DECIMAL(12,2) DEFAULT 0.00,
    total_cost_usd         DECIMAL(14,2) DEFAULT 0.00,
    order_date             DATE          NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date   DATE,
    status                 VARCHAR(15)   DEFAULT 'Pending',

    FOREIGN KEY (vendor_id)   REFERENCES vendors(vendor_id),
    FOREIGN KEY (part_number) REFERENCES inventory(part_number)
);

-- Create the flight cycles table --
CREATE TABLE flight_cycles (
    cycle_id          VARCHAR(10)  NOT NULL PRIMARY KEY,
    aircraft_id       VARCHAR(10)  NOT NULL,
    flight_date       DATE         NOT NULL,
    route             VARCHAR(15)  NOT NULL,
    flight_hours      DECIMAL(5,1) DEFAULT 0.0,
    cycles            INT          DEFAULT 1,
    fuel_burn_kg      DECIMAL(10,1),
    departure_station VARCHAR(5),
    arrival_station   VARCHAR(5),

    FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id)
);

-- ------------------------------------------------------------
-- Load aircraft and flight_cycles
-- No @variables needed — all columns are plain strings or
-- integers with no empty-string or date conversion required.
-- Both tables were imported directly via MySQL Workbench's
-- Table Data Import Wizard.
-- ------------------------------------------------------------

-- Enable local file loading
-- Required setting to allow LOAD DATA INFILE to work.
-- Must be run before the import command below.

SET GLOBAL local_infile = 1;

-- Load technicians
-- Why @license_expiry is used:
--   The CSV stores dates as text strings ('YYYY-MM-DD').
--   MySQL cannot insert a raw string directly into a DATE
--   column — STR_TO_DATE() is required to parse the format
--   explicitly. The value is staged in @license_expiry first,
--   then converted in the SET block below.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/technicians.csv'
INTO TABLE technicians
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(tech_id, name, license_type, specialization,
 @license_expiry, experience_years, station, total_hours_logged)
SET license_expiry = STR_TO_DATE(@license_expiry, '%Y-%m-%d');

-- Load vendors
-- No @variables needed — all columns are plain strings or
-- numbers with no empty-string or date conversion required.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/vendors.csv'
INTO TABLE vendors
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(vendor_id, vendor_name, country, avg_lead_time_days,
 on_time_delivery_pct, approved_status, total_orders_placed,
 payment_terms_days);
 
-- Load inventory
-- Why @shelf_life is used:
-- shelf_life_days is NULL for parts with no expiry limit
-- (e.g. structural hardware). Those rows arrive as empty
-- strings ('') in the CSV. MySQL cannot store '' in an INT
-- column — NULLIF() converts empty strings to NULL cleanly.
 LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/inventory.csv'
INTO TABLE inventory
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(part_number, part_name, ata_chapter, ata_description,
 vendor_id, quantity_on_hand, reorder_point, reorder_quantity,
 unit_cost_usd, criticality, @shelf_life, part_condition)
SET shelf_life_days = NULLIF(@shelf_life, '');

-- Load maintenance_orders
-- Why @variables are used:
--  actual_start_date and actual_close_date are NULL for
--  maintenance events that have not yet started or closed.
--  Those rows arrive as empty strings ('') in the CSV.
--  IF(...) guards against passing '' into STR_TO_DATE(),
--  which would produce an invalid date instead of NULL.
--  scheduled_date is always populated but still requires
--  STR_TO_DATE() for explicit format parsing.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/maintenance_orders.csv'
INTO TABLE maintenance_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(mo_id, aircraft_id, mo_type, @scheduled_date,
 @actual_start, @actual_close, station,
 scheduled_manhours, actual_manhours, status, reference_doc)
SET
    scheduled_date    = STR_TO_DATE(@scheduled_date, '%Y-%m-%d'),
    actual_start_date = IF(@actual_start = '', NULL, STR_TO_DATE(@actual_start, '%Y-%m-%d')),
    actual_close_date = IF(@actual_close = '', NULL, STR_TO_DATE(@actual_close, '%Y-%m-%d'));

-- Load work_orders
-- Why @sign_off is used:
-- sign_off_date is NULL for work orders still in progress
-- (status = 'Pending' or 'In Progress'). Those rows carry
-- an empty string in the CSV. IF(...) prevents passing ''
-- into STR_TO_DATE(), returning NULL instead.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/work_orders.csv'
INTO TABLE work_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(wo_id, mo_id, tech_id, ata_chapter, task_description,
 hours_logged, discrepancy, corrective_action, status, @sign_off)
SET sign_off_date = IF(@sign_off = '', NULL, STR_TO_DATE(@sign_off, '%Y-%m-%d'));

-- Load parts_used
-- Why @removal_date and @install_date are used:
-- Parts that are only installed (new fitment) have no
-- removal_date; parts that are only removed have no
-- installation_date. Both columns can be empty strings
-- in the CSV. IF(...) converts '' to NULL for each,
-- preventing STR_TO_DATE() from producing invalid dates.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/parts_used.csv'
INTO TABLE parts_used
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(pu_id, mo_id, part_number, part_name, quantity_used,
 unit_cost_usd, total_cost_usd, part_condition,
 @removal_date, @install_date, removed_part_disposition)
SET
    removal_date      = IF(@removal_date = '', NULL, STR_TO_DATE(@removal_date, '%Y-%m-%d')),
    installation_date = IF(@install_date = '', NULL, STR_TO_DATE(@install_date, '%Y-%m-%d'));

-- Load purchase_orders
-- Why @variables are used:
-- expected_delivery_date and actual_delivery_date are NULL
-- for orders that are still pending or in transit. Those
-- rows carry empty strings in the CSV. IF(...) guards both
-- optional dates while STR_TO_DATE() parses order_date,
-- which is always populated.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/purchase_orders.csv'
INTO TABLE purchase_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(po_id, vendor_id, part_number, part_name, quantity_ordered,
 unit_cost_usd, total_cost_usd, @order_date,
 @exp_date, @act_date, status)
SET
    order_date             = STR_TO_DATE(@order_date, '%Y-%m-%d'),
    expected_delivery_date = IF(@exp_date = '', NULL, STR_TO_DATE(@exp_date, '%Y-%m-%d')),
    actual_delivery_date   = IF(@act_date = '', NULL, STR_TO_DATE(@act_date, '%Y-%m-%d'));