/*
Project: GA4 Funnel by Day and Channel
Platform: Google BigQuery
Target Table: funnel_by_day_channel_2021

Business Purpose:
Analyze user sessions and conversion steps by date and traffic channel.

Key Metrics:
- Sessions
- Add to cart conversion
- Checkout conversion
- Purchase conversion

Key SQL Concepts:
- Session-level aggregation
- COUNT DISTINCT
- CASE WHEN
- SAFE_DIVIDE
- GROUP BY
- Source / medium / campaign analysis
*/

#standardSQL
CREATE OR REPLACE TABLE `basic-eon-484117-g5.sql_ara_proje_HiGu.landing_page_conversion_2020` AS
WITH e AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_name,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _table_suffix BETWEEN '20200101' AND '20201231'
    AND event_name IN ('session_start', 'purchase')
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    ANY_VALUE(IF(event_name='session_start', page_location, NULL)) AS landing_url,
    MAX(IF(event_name='purchase', 1, 0)) AS has_purchase
  FROM e
  WHERE session_id IS NOT NULL
  GROUP BY 1,2
),
final AS (
  SELECT
    COALESCE(REGEXP_EXTRACT(landing_url, r'https?://[^/]+(/[^?#]*)'), '(unknown)') AS page_path,
    has_purchase
  FROM sessions
)
SELECT
  page_path,
  COUNT(*) AS unique_user_sessions_count,
  SUM(has_purchase) AS purchases,
  ROUND(SUM(has_purchase) / COUNT(*), 4) AS purchase_cvr
FROM final
GROUP BY page_path
ORDER BY unique_user_sessions_count DESC;
