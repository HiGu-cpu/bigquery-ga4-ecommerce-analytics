/*
Project: GA4 Flat Events Table
Platform: Google BigQuery
Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
Target Table: flat_events_2021

Business Purpose:
Prepare a clean event-level table from GA4 e-commerce data for dashboarding and further analysis.

Key SQL Concepts:
- TIMESTAMP_MICROS
- UNNEST
- Event parameter extraction
- Date filtering with _TABLE_SUFFIX
- GA4 event filtering
*/

CREATE OR REPLACE TABLE `basic-eon-484117-g5.sql_ara_proje_HiGu.flat_events_2021` AS
SELECT
TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
user_pseudo_id,
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
event_name,
geo.country AS country,
device.category AS device_category,
traffic_source.source AS source,
traffic_source.medium AS medium,
traffic_source.name AS campaign
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _table_suffix BETWEEN '20210101' AND '20211231'
AND event_name IN (
'session_start','view_item','add_to_cart','begin_checkout',
'add_shipping_info','add_payment_info','purchase'
);
